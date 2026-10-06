"""
Simplified Anomaly Detection Lambda Function
Uses statistical methods instead of ML libraries
"""
import json
import boto3
import os
from datetime import datetime, timedelta
from statistics import mean, stdev

# AWS Clients
cloudwatch = boto3.client('cloudwatch')
ecs = boto3.client('ecs')
sns = boto3.client('sns')

# Environment Variables
CLUSTER_NAME = os.environ.get('CLUSTER_NAME', 'aiops-monitoring-dev-cluster')
SERVICE_NAME = os.environ.get('SERVICE_NAME', 'aiops-monitoring-dev-app-service')
SNS_TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN', '')
MIN_TASKS = int(os.environ.get('MIN_TASKS', '1'))
MAX_TASKS = int(os.environ.get('MAX_TASKS', '10'))

# Thresholds for anomaly detection
CPU_THRESHOLD_HIGH = 70
CPU_THRESHOLD_LOW = 5
MEMORY_THRESHOLD_HIGH = 75
MEMORY_THRESHOLD_LOW = 10

def lambda_handler(event, context):
    """Main Lambda handler"""
    print(f"Starting anomaly detection for {CLUSTER_NAME}/{SERVICE_NAME}")
    
    try:
        # Fetch metrics
        metrics = fetch_cloudwatch_metrics()
        
        if not metrics:
            print("No metrics available")
            return {'statusCode': 200, 'body': json.dumps('No data')}
        
        # Detect anomalies using statistical methods
        anomalies = detect_anomalies_statistical(metrics)
        
        # Analyze and respond
        result = analyze_and_respond(metrics, anomalies)
        
        return {'statusCode': 200, 'body': json.dumps(result)}
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return {'statusCode': 500, 'body': json.dumps(f'Error: {str(e)}')}

def fetch_cloudwatch_metrics():
    """Fetch ECS metrics from CloudWatch"""
    end_time = datetime.utcnow()
    start_time = end_time - timedelta(hours=1)
    
    metrics_data = {'cpu': [], 'memory': [], 'timestamps': []}
    
    for metric_name, key in [('CPUUtilization', 'cpu'), ('MemoryUtilization', 'memory')]:
        try:
            response = cloudwatch.get_metric_statistics(
                Namespace='AWS/ECS',
                MetricName=metric_name,
                Dimensions=[
                    {'Name': 'ClusterName', 'Value': CLUSTER_NAME},
                    {'Name': 'ServiceName', 'Value': SERVICE_NAME}
                ],
                StartTime=start_time,
                EndTime=end_time,
                Period=300,
                Statistics=['Average']
            )
            
            datapoints = sorted(response.get('Datapoints', []), key=lambda x: x['Timestamp'])
            
            for point in datapoints:
                if key == 'cpu':
                    metrics_data['timestamps'].append(point['Timestamp'].isoformat())
                metrics_data[key].append(point['Average'])
                
            print(f"Fetched {len(datapoints)} points for {metric_name}")
            
        except Exception as e:
            print(f"Error fetching {metric_name}: {str(e)}")
    
    return metrics_data

def detect_anomalies_statistical(metrics):
    """Detect anomalies using statistical methods (mean, stdev, thresholds)"""
    anomalies = []
    
    cpu_values = metrics['cpu']
    memory_values = metrics['memory']
    timestamps = metrics['timestamps']
    
    if len(cpu_values) < 5:
        return anomalies
    
    # Calculate statistics
    cpu_mean = mean(cpu_values)
    cpu_std = stdev(cpu_values) if len(cpu_values) > 1 else 0
    mem_mean = mean(memory_values)
    mem_std = stdev(memory_values) if len(memory_values) > 1 else 0
    
    print(f"CPU: mean={cpu_mean:.2f}, std={cpu_std:.2f}")
    print(f"Memory: mean={mem_mean:.2f}, std={mem_std:.2f}")
    
    # Detect anomalies
    for i, (cpu, mem, ts) in enumerate(zip(cpu_values, memory_values, timestamps)):
        is_anomaly = False
        reasons = []
        
        # Threshold-based detection
        if cpu > CPU_THRESHOLD_HIGH:
            is_anomaly = True
            reasons.append(f"High CPU: {cpu:.1f}%")
        elif cpu < CPU_THRESHOLD_LOW:
            is_anomaly = True
            reasons.append(f"Very low CPU: {cpu:.1f}%")
            
        if mem > MEMORY_THRESHOLD_HIGH:
            is_anomaly = True
            reasons.append(f"High Memory: {mem:.1f}%")
        elif mem < MEMORY_THRESHOLD_LOW:
            is_anomaly = True
            reasons.append(f"Very low Memory: {mem:.1f}%")
        
        # Statistical outlier detection (3-sigma rule)
        if cpu_std > 0 and abs(cpu - cpu_mean) > 2 * cpu_std:
            is_anomaly = True
            reasons.append(f"CPU outlier: {cpu:.1f}% (mean: {cpu_mean:.1f})")
            
        if mem_std > 0 and abs(mem - mem_mean) > 2 * mem_std:
            is_anomaly = True
            reasons.append(f"Memory outlier: {mem:.1f}% (mean: {mem_mean:.1f})")
        
        if is_anomaly:
            anomalies.append({
                'index': i,
                'cpu': cpu,
                'memory': mem,
                'timestamp': ts,
                'reasons': reasons
            })
    
    print(f"Detected {len(anomalies)} anomalies")
    return anomalies

def analyze_and_respond(metrics, anomalies):
    """Analyze anomalies and take action"""
    if not anomalies:
        print("System healthy - no anomalies")
        return {
            'status': 'healthy',
            'anomalies_detected': 0,
            'action_taken': 'none'
        }
    
    # Get recent averages
    recent_cpu = metrics['cpu'][-5:] if metrics['cpu'] else [0]
    recent_mem = metrics['memory'][-5:] if metrics['memory'] else [0]
    
    avg_cpu = mean(recent_cpu)
    avg_mem = mean(recent_mem)
    
    # Determine severity
    severity = 'LOW'
    action_taken = 'none'
    
    if len(anomalies) >= 3:
        severity = 'HIGH'
        if avg_cpu > 70 or avg_mem > 70:
            action_taken = scale_ecs_service('up')
        elif avg_cpu < 20 and avg_mem < 20:
            action_taken = scale_ecs_service('down')
    elif len(anomalies) >= 1:
        severity = 'MEDIUM'
    
    if severity in ['MEDIUM', 'HIGH'] and SNS_TOPIC_ARN:
        send_alert(severity, anomalies, avg_cpu, avg_mem, action_taken)
    
    return {
        'status': 'anomaly_detected',
        'severity': severity,
        'anomalies_detected': len(anomalies),
        'avg_cpu': round(avg_cpu, 2),
        'avg_memory': round(avg_mem, 2),
        'action_taken': action_taken,
        'anomaly_details': anomalies[:3]
    }

def scale_ecs_service(direction):
    """Scale ECS service"""
    try:
        response = ecs.describe_services(
            cluster=CLUSTER_NAME,
            services=[SERVICE_NAME]
        )
        
        if not response['services']:
            return 'service_not_found'
        
        current_count = response['services'][0]['desiredCount']
        new_count = min(current_count + 1, MAX_TASKS) if direction == 'up' else max(current_count - 1, MIN_TASKS)
        
        if new_count == current_count:
            return f'at_limit_{current_count}'
        
        ecs.update_service(
            cluster=CLUSTER_NAME,
            service=SERVICE_NAME,
            desiredCount=new_count
        )
        
        print(f"Scaled {direction}: {current_count} -> {new_count}")
        return f'scaled_{direction}_{current_count}_to_{new_count}'
        
    except Exception as e:
        print(f"Scale error: {str(e)}")
        return f'error_{str(e)}'

def send_alert(severity, anomalies, avg_cpu, avg_mem, action):
    """Send SNS alert"""
    try:
        message = f"""
AIOps Anomaly Detection Alert

Severity: {severity}
Service: {SERVICE_NAME}

Metrics:
- CPU: {avg_cpu:.2f}%
- Memory: {avg_mem:.2f}%
- Anomalies: {len(anomalies)}

Action: {action}

Details:
"""
        for i, anomaly in enumerate(anomalies[:3], 1):
            message += f"\n{i}. {', '.join(anomaly['reasons'])}"
            message += f"\n   Time: {anomaly['timestamp']}\n"
        
        sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject=f"[{severity}] Anomaly - {SERVICE_NAME}",
            Message=message
        )
        
        print(f"Alert sent: {severity}")
        
    except Exception as e:
        print(f"Alert error: {str(e)}")
