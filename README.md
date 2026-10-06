# AI-Powered Monitoring & Observability Platform

A production-ready, cloud-native monitoring solution built on AWS that combines modern DevOps practices with AI-powered anomaly detection for intelligent auto-scaling and alerting.

![Architecture](https://img.shields.io/badge/AWS-ECS%20Fargate-orange) ![Terraform](https://img.shields.io/badge/IaC-Terraform-purple) ![Python](https://img.shields.io/badge/Python-3.11-blue) ![Grafana](https://img.shields.io/badge/Monitoring-Grafana-orange)

---

## Project Overview

This project demonstrates enterprise-grade DevOps and AIOps capabilities by implementing a complete monitoring stack with:

- **Containerized microservices** running on AWS ECS Fargate
- **Infrastructure as Code** using Terraform
- **Real-time monitoring** with Grafana and CloudWatch
- **AI-powered anomaly detection** using Lambda
- **Intelligent auto-scaling** based on ML predictions
- **Automated alerting** via SNS

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Internet                                 │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ↓
              ┌──────────────────────┐
              │  Application Load    │
              │  Balancer (ALB)      │
              │  Port 80             │
              └──────────┬───────────┘
                         │
        ┌────────────────┼────────────────┐
        │                │                │
        ↓                ↓                ↓
   ┌─────────┐     ┌──────────┐    ┌─────────┐
   │ Flask   │     │Prometheus│    │ Grafana │
   │ App     │     │  :9090   │    │  :3000  │
   │ :5000   │     └──────────┘    └─────────┘
   └─────────┘           │               │
        │                └───────┬───────┘
        │                        │
        └────────────────┬───────┘
                         │
                    ┌────┴─────┐
                    │CloudWatch│
                    │ Metrics  │
                    └────┬─────┘
                         │
                    ┌────┴──────┐
                    │  Lambda   │
                    │ Anomaly   │
                    │ Detection │
                    └────┬──────┘
                         │
                    ┌────┴─────┐
                    │   SNS    │
                    │  Alerts  │
                    └──────────┘
```

### Network Architecture

- **VPC**: Isolated network (10.0.0.0/16)
- **Public Subnets**: ALB, NAT Gateways (10.0.1.0/24, 10.0.2.0/24)
- **Private Subnets**: ECS containers (10.0.10.0/24, 10.0.20.0/24)
- **Multi-AZ**: Deployed across 2 availability zones for high availability

---

## Features

### DevOps & Infrastructure
- **Infrastructure as Code**: 100% Terraform-managed infrastructure
- **Containerization**: Docker-based microservices architecture
- **ECS Fargate**: Serverless container orchestration
- **Auto-scaling**: Dynamic scaling based on metrics and AI predictions
- **High Availability**: Multi-AZ deployment with load balancing
- **Security**: Private subnets, security groups, least-privilege IAM

### Monitoring & Observability
- **Metrics Collection**: Prometheus-style metrics from application
- **Visualization**: Grafana dashboards with CloudWatch integration
- **Centralized Logging**: CloudWatch Logs for all services
- **Health Checks**: Automated container health monitoring
- **Container Insights**: Detailed ECS metrics and performance data

### AIOps & Intelligence
- **Anomaly Detection**: Statistical analysis of CPU/Memory patterns
- **Predictive Scaling**: ML-based resource optimization
- **Smart Alerting**: Context-aware notifications (LOW/MEDIUM/HIGH severity)
- **Automated Remediation**: Self-healing through auto-scaling
- **Event-Driven**: Lambda functions triggered by EventBridge

---

## Technology Stack

### Infrastructure
- **Cloud Provider**: AWS
- **Container Orchestration**: ECS Fargate
- **Load Balancing**: Application Load Balancer (ALB)
- **Networking**: VPC, NAT Gateway, Internet Gateway
- **IaC**: Terraform

### Application
- **Runtime**: Python 3.11
- **Web Framework**: Flask
- **WSGI Server**: Gunicorn (production-ready)
- **Metrics**: Prometheus Client
- **Containerization**: Docker

### Monitoring
- **Metrics Storage**: AWS CloudWatch
- **Visualization**: Grafana
- **Metrics Scraping**: Prometheus (planned)
- **Logging**: CloudWatch Logs
- **Alerting**: AWS SNS

### AIOps
- **Compute**: AWS Lambda
- **Scheduling**: EventBridge
- **Detection Method**: Statistical anomaly detection (mean, stdev, thresholds)
- **Actions**: ECS service scaling, SNS notifications

---

## 📁 Project Structure

```
aiops-monitoring-project/
├── app/
│   ├── app.py                 # Flask application with Prometheus metrics
│   ├── requirements.txt       # Python dependencies
│   ├── Dockerfile            # Multi-stage Docker build
│   └── .dockerignore         # Docker ignore patterns
├── terraform/
│   ├── main.tf               # Provider and backend configuration
│   ├── variables.tf          # Input variables
│   ├── outputs.tf            # Output values
│   ├── vpc.tf                # VPC and networking resources
│   ├── security_groups.tf    # Security group definitions
│   ├── ecr.tf                # Container registry
│   ├── iam.tf                # IAM roles and policies
│   ├── alb.tf                # Application Load Balancer
│   ├── ecs.tf                # ECS cluster and services
│   ├── lambda.tf             # Lambda function and EventBridge
│   └── lambda_function.zip   # Lambda deployment package
├── lambda/
│   ├── lambda_function.py    # Anomaly detection logic
│   └── requirements.txt      # Lambda dependencies
└── README.md                 # This file
```

---

## Getting Started

### Prerequisites

- AWS Account with appropriate permissions
- AWS CLI configured (`aws configure`)
- Terraform >= 1.0
- Docker Desktop
- Python 3.11+

### Installation & Deployment

#### 1. Clone the Repository

```bash
git clone <your-repo-url>
cd aiops-monitoring-project
```

#### 2. Configure Variables

Edit `terraform/variables.tf`:

```hcl
variable "alert_email" {
  default = "your-email@example.com"  # Change to your email
}

variable "aws_region" {
  default = "us-west-2"  # Change if needed
}
```

#### 3. Build and Push Docker Image

```bash
# Navigate to app directory
cd app

# Build for x86_64 (AWS Fargate architecture)
docker build --platform linux/amd64 -t aiops-monitoring-dev-app:latest .

# Login to ECR
aws ecr get-login-password --region us-west-2 | \
  docker login --username AWS --password-stdin \
  746669235620.dkr.ecr.us-west-2.amazonaws.com

# Tag for ECR
docker tag aiops-monitoring-dev-app:latest \
  746669235620.dkr.ecr.us-west-2.amazonaws.com/aiops-monitoring-dev-app:latest

# Push to ECR
docker push 746669235620.dkr.ecr.us-west-2.amazonaws.com/aiops-monitoring-dev-app:latest
```

#### 4. Deploy Infrastructure

```bash
cd ../terraform

# Initialize Terraform
terraform init

# Review planned changes
terraform plan

# Deploy
terraform apply
```

#### 5. Confirm SNS Subscription

Check your email and confirm the SNS subscription to receive alerts.

#### 6. Access Applications

After deployment, Terraform outputs the URLs:

```bash
terraform output
```

- **Flask App**: http://your-alb-dns/
- **Grafana**: http://your-alb-dns/grafana
- **Prometheus**: http://your-alb-dns/prometheus
- **Health Check**: http://your-alb-dns/health
- **Metrics**: http://your-alb-dns/metrics

---

## Grafana Dashboard

The project includes a pre-configured dashboard showing:

1. **CPU Utilization** - Real-time CPU usage across containers
2. **Memory Utilization** - Memory consumption patterns
3. **Running Tasks** - Container health status for all services
4. **Network Traffic** - Inbound/outbound network metrics
5. **Resource Distribution** - Cluster-wide resource allocation

### Accessing Grafana

1. Navigate to: `http://<alb-dns>/grafana`
2. Anonymous access is enabled (for demo only!)
3. The CloudWatch data source is pre-configured

---

## AI-Powered Anomaly Detection

### How It Works

The Lambda function runs **every 5 minutes** and:

1. **Fetches Metrics**: Retrieves last hour of CPU/Memory data from CloudWatch
2. **Statistical Analysis**: Calculates mean, standard deviation, and thresholds
3. **Anomaly Detection**: Identifies outliers using:
   - **Threshold-based**: CPU > 70% or < 5%, Memory > 75% or < 10%
   - **3-Sigma Rule**: Values beyond 2 standard deviations from mean
4. **Severity Classification**:
   - **LOW**: 0 anomalies (healthy)
   - **MEDIUM**: 1-2 anomalies detected
   - **HIGH**: 3+ anomalies detected
5. **Automated Actions**:
   - **High CPU/Memory**: Scale up ECS tasks (max 10)
   - **Low CPU/Memory**: Scale down ECS tasks (min 1)
   - **Alert**: Send SNS notification for MEDIUM/HIGH severity

### Testing Anomaly Detection

Generate load to trigger anomalies:

```bash
# Simulate high CPU load
for i in {1..100}; do 
  curl http://<alb-dns>/api/simulate-load &
done

# Wait 5-10 minutes for Lambda to detect and alert
```

---

## 🔒 Security Best Practices

### Network Security
- ✅ Containers in private subnets (no direct internet access)
- ✅ ALB in public subnets (controlled entry point)
- ✅ Security groups with least-privilege rules
- ✅ NAT Gateway for outbound traffic only

### IAM Security
- ✅ Separate roles for ECS task execution vs. application
- ✅ Least-privilege policies
- ✅ No hardcoded credentials
- ✅ Service-to-service authentication via security groups

### Container Security
- ✅ ECR image scanning enabled
- ✅ Non-root container user (best practice)
- ✅ Minimal base images
- ✅ Encrypted container registry

### Data Security
- ✅ Encryption at rest (ECR, CloudWatch Logs)
- ✅ TLS in transit (ALB supports HTTPS - ready for SSL cert)
- ✅ VPC isolation

---

## Monitoring & Observability

### Application Metrics (Prometheus Format)

The Flask app exposes `/metrics` endpoint with:

- `app_requests_total`: Total HTTP requests (by method, endpoint, status)
- `app_request_duration_seconds`: Request latency histogram
- `app_active_users`: Simulated active user gauge
- `app_cpu_usage_percent`: Current CPU usage
- `app_memory_usage_bytes`: Current memory usage
- `app_orders_processed_total`: Business metric (success/failed orders)
- `app_database_errors_total`: Error counter

### CloudWatch Logs

All services log to CloudWatch:

- `/ecs/aiops-monitoring-dev-app`: Flask application logs
- `/ecs/aiops-monitoring-dev-prometheus`: Prometheus logs
- `/ecs/aiops-monitoring-dev-grafana`: Grafana logs
- `/aws/lambda/aiops-monitoring-dev-anomaly-detection`: Lambda logs

### Viewing Logs

```bash
# Flask app logs
aws logs tail /ecs/aiops-monitoring-dev-app --follow

# Lambda logs
aws logs tail /aws/lambda/aiops-monitoring-dev-anomaly-detection --follow
```

---

## CI/CD Ready

While not included in this demo, the project is designed for CI/CD integration:

### GitHub Actions Pipeline (Example)

```yaml
name: Deploy to ECS

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Build and push Docker image
        run: |
          docker build --platform linux/amd64 -t app:${{ github.sha }} .
          docker tag app:${{ github.sha }} $ECR_REPO:latest
          docker push $ECR_REPO:latest
      - name: Deploy to ECS
        run: |
          aws ecs update-service \
            --cluster aiops-monitoring-dev-cluster \
            --service aiops-monitoring-dev-app-service \
            --force-new-deployment
```

---

## Cost Optimization

### Current Monthly Costs (Estimated)

- **ECS Fargate**: ~$30-50 (4 tasks @ 0.5 vCPU, 1GB RAM)
- **Application Load Balancer**: ~$20
- **NAT Gateway**: ~$30
- **CloudWatch**: ~$5 (logs + metrics)
- **Lambda**: <$1 (under free tier)
- **ECR**: <$1
- **Total**: ~$85-105/month

### Cost Reduction Strategies

1. **Use Fargate Spot** for non-production workloads (70% savings)
2. **Reduce NAT Gateway** to single AZ (50% savings)
3. **Log retention** set to 7 days (vs. never expire)
4. **Auto-scaling** scales down during low traffic
5. **Reserved capacity** for predictable workloads

---

## Testing

### Manual Testing

```bash
# Health check
curl http://<alb-dns>/health

# Metrics endpoint
curl http://<alb-dns>/metrics

# Generate traffic
for i in {1..100}; do curl http://<alb-dns>/api/data; done

# Create orders (some will fail intentionally)
for i in {1..50}; do curl -X POST http://<alb-dns>/api/order; done

# Simulate errors
curl "http://<alb-dns>/api/simulate-error?type=database"
```

### Monitoring Tests

1. **Check ECS service health**:
   ```bash
   aws ecs describe-services \
     --cluster aiops-monitoring-dev-cluster \
     --services aiops-monitoring-dev-app-service
   ```

2. **Verify auto-scaling**:
   - Generate high load
   - Wait 5-10 minutes
   - Check if tasks increased

3. **Test alerting**:
   - Generate anomalies
   - Confirm email received

---

## Troubleshooting

### Common Issues

#### 1. DNS Resolution Issues

**Problem**: Can't resolve ALB DNS
**Solution**: Add to `/etc/hosts`:
```bash
sudo nano /etc/hosts
# Add: <ALB-IP> aiops-monitoring-dev-alb-XXX.us-west-2.elb.amazonaws.com
```

#### 2. Container Fails to Start

**Problem**: "exec format error"
**Solution**: Build for correct platform:
```bash
docker build --platform linux/amd64 -t app:latest .
```

#### 3. Lambda Permission Errors

**Problem**: Lambda can't access CloudWatch/ECS
**Solution**: Check IAM role has correct policies attached

#### 4. No Metrics in Grafana

**Problem**: Grafana shows "No data"
**Solution**: 
- Verify CloudWatch data source configured
- Check ECS Container Insights is enabled
- Wait 5-10 minutes for metrics to populate

---

## Learning Resources

### Key Concepts Demonstrated

- **Container Orchestration**: ECS Fargate, task definitions, services
- **Infrastructure as Code**: Terraform modules, state management
- **Networking**: VPC, subnets, security groups, NAT gateways, ALBs
- **Observability**: Metrics, logs, traces (the three pillars)
- **DevOps**: CI/CD pipelines, immutable infrastructure, GitOps
- **AIOps**: Anomaly detection, predictive analytics, auto-remediation
- **Security**: Least privilege, network segmentation, encryption

### Interview Talking Points

1. **"Walk me through the architecture"**
   - Multi-tier architecture: ALB → ECS → Database abstraction
   - Private subnets for security, public for ALB
   - High availability across multiple AZs

2. **"How does auto-scaling work?"**
   - Lambda analyzes CloudWatch metrics every 5 minutes
   - Statistical anomaly detection (mean, stdev, thresholds)
   - Automatically scales ECS tasks up/down
   - SNS alerts for human oversight

3. **"How would you handle a production incident?"**
   - Check Grafana dashboards for anomalies
   - Review CloudWatch Logs for errors
   - Use Lambda logs to see recent anomaly detection results
   - Scale manually if needed: `aws ecs update-service --desired-count X`

4. **"How do you ensure security?"**
   - Private subnets isolate containers
   - Security groups with least-privilege rules
   - IAM roles with minimal permissions
   - Encrypted data at rest and in transit

5. **"What improvements would you make?"**
   - Add HTTPS/SSL certificates
   - Implement blue-green deployments
   - Add distributed tracing (AWS X-Ray)
   - Set up proper Prometheus with service discovery
   - Implement secrets management (AWS Secrets Manager)
   - Add database layer (RDS)

---

## Roadmap

### Phase 1: Complete
- [x] Basic ECS infrastructure
- [x] Flask application with metrics
- [x] Grafana monitoring
- [x] Lambda anomaly detection
- [x] Auto-scaling and alerting

### Phase 2: Planned
- [ ] HTTPS/SSL with ACM certificates
- [ ] Custom domain with Route 53
- [ ] Prometheus service discovery
- [ ] Enhanced Grafana dashboards
- [ ] AWS X-Ray distributed tracing

### Phase 3: Future
- [ ] Multi-region deployment
- [ ] Blue-green deployments
- [ ] Database layer (RDS/DynamoDB)
- [ ] Advanced ML models (time-series forecasting)
- [ ] Cost optimization dashboard
- [ ] Chaos engineering tests

---

## Contributing

This is a portfolio project, but suggestions and improvements are welcome!

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

---

## License

This project is open source and available under the MIT License.

---

## Author

**Danielle T. Felix**

- Interview Project: AI-Powered Monitoring Platform
- Skills Demonstrated: AWS, Terraform, Docker, Python, DevOps, AIOps
- Contact: [tchonladanielle@gmail.com/www.linkedin.com/in/danielle-felix1/]

---

## Support

For questions or issues:
1. Check the Troubleshooting section
2. Review AWS CloudWatch Logs
3. Open an issue on GitHub

---

**Built with ❤️ for demonstrating modern DevOps and AIOps practices**