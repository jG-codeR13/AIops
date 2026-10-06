# ============================================================================
# SECURITY GROUP - APPLICATION LOAD BALANCER
# ============================================================================

resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-${var.environment}-alb-"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  # Inbound: Allow HTTP from anywhere
  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound: Allow HTTPS from anywhere
  ingress {
    description = "HTTPS from Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound: Allow all traffic
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-alb-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# SECURITY GROUP - FLASK APPLICATION
# ============================================================================

resource "aws_security_group" "app" {
  name_prefix = "${var.project_name}-${var.environment}-app-"
  description = "Security group for Flask application containers"
  vpc_id      = aws_vpc.main.id

  # Inbound: Allow traffic from ALB on port 5000
  ingress {
    description     = "Allow traffic from ALB"
    from_port       = var.app_container_port
    to_port         = var.app_container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Inbound: Allow traffic from Prometheus on port 5000
  ingress {
    description     = "Allow metrics scraping from Prometheus"
    from_port       = var.app_container_port
    to_port         = var.app_container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.prometheus.id]
  }

  # Outbound: Allow all traffic (for pulling images, calling APIs, etc.)
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-app-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# SECURITY GROUP - PROMETHEUS
# ============================================================================

resource "aws_security_group" "prometheus" {
  name_prefix = "${var.project_name}-${var.environment}-prometheus-"
  description = "Security group for Prometheus container"
  vpc_id      = aws_vpc.main.id

  # Inbound: Allow access from ALB on port 9090 (Prometheus UI)
  ingress {
    description     = "Prometheus UI from ALB"
    from_port       = 9090
    to_port         = 9090
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Inbound: Allow access from Grafana
  ingress {
    description     = "Allow Grafana to query Prometheus"
    from_port       = 9090
    to_port         = 9090
    protocol        = "tcp"
    security_groups = [aws_security_group.grafana.id]
  }

  # Outbound: Allow all traffic (to scrape metrics from app)
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-prometheus-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# SECURITY GROUP - GRAFANA
# ============================================================================

resource "aws_security_group" "grafana" {
  name_prefix = "${var.project_name}-${var.environment}-grafana-"
  description = "Security group for Grafana container"
  vpc_id      = aws_vpc.main.id

  # Inbound: Allow access from ALB on port 3000 (Grafana UI)
  ingress {
    description     = "Grafana UI from ALB"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Outbound: Allow all traffic (to query Prometheus, CloudWatch, etc.)
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-grafana-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# SECURITY GROUP - VPC ENDPOINTS (Optional but recommended)
# ============================================================================

resource "aws_security_group" "vpc_endpoints" {
  name_prefix = "${var.project_name}-${var.environment}-vpce-"
  description = "Security group for VPC endpoints"
  vpc_id      = aws_vpc.main.id

  # Inbound: Allow HTTPS from VPC
  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Outbound: Allow all traffic
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-vpce-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}