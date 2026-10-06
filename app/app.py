"""
Flask Application with Prometheus Metrics
This app demonstrates a microservice with built-in observability
"""
from flask import Flask, jsonify, request
from prometheus_client import Counter, Histogram, Gauge, generate_latest, CONTENT_TYPE_LATEST
import time
import random
import psutil
import os

app = Flask(__name__)

# ============================================================================
# PROMETHEUS METRICS DEFINITIONS
# ============================================================================

# Counter: Tracks total number of requests (only increases)
request_count = Counter(
    'app_requests_total',
    'Total number of requests',
    ['method', 'endpoint', 'status']
)

# Histogram: Tracks distribution of request durations
request_duration = Histogram(
    'app_request_duration_seconds',
    'Request duration in seconds',
    ['method', 'endpoint']
)

# Gauge: Tracks current values (can go up or down)
active_users = Gauge(
    'app_active_users',
    'Number of currently active users'
)

memory_usage = Gauge(
    'app_memory_usage_bytes',
    'Current memory usage in bytes'
)

cpu_usage = Gauge(
    'app_cpu_usage_percent',
    'Current CPU usage percentage'
)

# Business metrics
orders_processed = Counter(
    'app_orders_processed_total',
    'Total orders processed',
    ['status']
)

database_errors = Counter(
    'app_database_errors_total',
    'Total database errors'
)

# ============================================================================
# MIDDLEWARE: Track all requests automatically
# ============================================================================

@app.before_request
def before_request():
    """Start timer before each request"""
    request.start_time = time.time()

@app.after_request
def after_request(response):
    """Record metrics after each request"""
    request_duration_seconds = time.time() - request.start_time
    
    # Record duration
    request_duration.labels(
        method=request.method,
        endpoint=request.endpoint or 'unknown'
    ).observe(request_duration_seconds)
    
    # Record request count
    request_count.labels(
        method=request.method,
        endpoint=request.endpoint or 'unknown',
        status=response.status_code
    ).inc()
    
    return response

# ============================================================================
# APPLICATION ENDPOINTS
# ============================================================================

@app.route('/')
def home():
    """Home endpoint"""
    return jsonify({
        'service': 'AIOps Demo Application',
        'status': 'healthy',
        'version': '1.0.0'
    })

@app.route('/health')
def health():
    """Health check endpoint"""
    # Simulate health check
    health_status = {
        'status': 'healthy',
        'database': 'connected',
        'cache': 'connected',
        'timestamp': time.time()
    }
    return jsonify(health_status)

@app.route('/api/data')
def get_data():
    """Simulated data endpoint with variable latency"""
    # Simulate varying response times
    time.sleep(random.uniform(0.01, 0.3))
    
    # Update active users (simulate)
    active_users.set(random.randint(10, 100))
    
    return jsonify({
        'data': [
            {'id': 1, 'value': random.randint(1, 100)},
            {'id': 2, 'value': random.randint(1, 100)},
            {'id': 3, 'value': random.randint(1, 100)}
        ],
        'timestamp': time.time()
    })

@app.route('/api/order', methods=['POST'])
def create_order():
    """Simulated order creation endpoint"""
    # Simulate occasional failures (10% failure rate)
    if random.random() < 0.1:
        orders_processed.labels(status='failed').inc()
        return jsonify({'error': 'Order processing failed'}), 500
    
    # Simulate occasional database errors (5% error rate)
    if random.random() < 0.05:
        database_errors.inc()
    
    # Success case
    time.sleep(random.uniform(0.05, 0.2))
    orders_processed.labels(status='success').inc()
    
    return jsonify({
        'order_id': random.randint(1000, 9999),
        'status': 'created',
        'timestamp': time.time()
    })

@app.route('/api/simulate-load')
def simulate_load():
    """Endpoint to simulate high CPU load"""
    # Simulate some CPU work
    result = sum([i ** 2 for i in range(10000)])
    return jsonify({
        'message': 'Load simulation completed',
        'result': result
    })

@app.route('/api/simulate-error')
def simulate_error():
    """Endpoint to intentionally trigger errors for testing"""
    error_type = request.args.get('type', 'generic')
    
    if error_type == 'database':
        database_errors.inc()
        return jsonify({'error': 'Database connection failed'}), 503
    elif error_type == 'timeout':
        time.sleep(5)  # Simulate timeout
        return jsonify({'error': 'Request timeout'}), 504
    else:
        return jsonify({'error': 'Internal server error'}), 500

# ============================================================================
# METRICS ENDPOINT (Prometheus scrapes this)
# ============================================================================

@app.route('/metrics')
def metrics():
    """
    Prometheus metrics endpoint
    This is what Prometheus will scrape to collect metrics
    """
    # Update system metrics
    memory_usage.set(psutil.virtual_memory().used)
    cpu_usage.set(psutil.cpu_percent(interval=0.1))
    
    # Return metrics in Prometheus format
    return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}

# ============================================================================
# RUN APPLICATION
# ============================================================================

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)