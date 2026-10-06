# ============================================================================
# PROJECT CONFIGURATION
# ============================================================================

variable "project_name" {
  description = "Name of the project - used to prefix all resources"
  type        = string
  default     = "aiops-monitoring"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-west-2"  # Change to your preferred region
}

# ============================================================================
# NETWORK CONFIGURATION
# ============================================================================

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]  # Must match your region
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

# ============================================================================
# ECS CONFIGURATION
# ============================================================================

variable "app_image_tag" {
  description = "Docker image tag for the Flask application"
  type        = string
  default     = "latest"
}

variable "app_container_port" {
  description = "Port the Flask application listens on"
  type        = number
  default     = 5000
}

variable "app_cpu" {
  description = "CPU units for the application task (1024 = 1 vCPU)"
  type        = number
  default     = 512  # 0.5 vCPU
}

variable "app_memory" {
  description = "Memory for the application task (in MB)"
  type        = number
  default     = 1024  # 1 GB
}

variable "app_desired_count" {
  description = "Desired number of application tasks"
  type        = number
  default     = 2  # Run 2 instances for high availability
}

variable "prometheus_cpu" {
  description = "CPU units for Prometheus task"
  type        = number
  default     = 512  # 0.5 vCPU
}

variable "prometheus_memory" {
  description = "Memory for Prometheus task (in MB)"
  type        = number
  default     = 1024  # 1 GB
}

variable "grafana_cpu" {
  description = "CPU units for Grafana task"
  type        = number
  default     = 512  # 0.5 vCPU
}

variable "grafana_memory" {
  description = "Memory for Grafana task (in MB)"
  type        = number
  default     = 1024  # 1 GB
}

# ============================================================================
# LOAD BALANCER CONFIGURATION
# ============================================================================

variable "alb_healthy_threshold" {
  description = "Number of consecutive health check successes required"
  type        = number
  default     = 2
}

variable "alb_unhealthy_threshold" {
  description = "Number of consecutive health check failures required"
  type        = number
  default     = 3
}

variable "alb_health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 30
}

variable "alb_health_check_timeout" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 5
}

variable "alert_email" {
  description = "Email address for anomaly alerts"
  type        = string
  default     = "felixdaniellet@gmail.com"  
}

# ============================================================================
# TAGS
# ============================================================================

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "AIOps Monitoring"
    ManagedBy   = "Terraform"
    Environment = "dev"
  }
}