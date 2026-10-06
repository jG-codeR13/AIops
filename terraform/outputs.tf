# ============================================================================
# NETWORK OUTPUTS
# ============================================================================

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

# ============================================================================
# ECR REPOSITORY OUTPUTS
# ============================================================================

output "ecr_repository_url_app" {
  description = "ECR repository URL for Flask application"
  value       = aws_ecr_repository.app.repository_url
}

output "ecr_repository_url_prometheus" {
  description = "ECR repository URL for Prometheus"
  value       = aws_ecr_repository.prometheus.repository_url
}

output "ecr_repository_url_grafana" {
  description = "ECR repository URL for Grafana"
  value       = aws_ecr_repository.grafana.repository_url
}

# ============================================================================
# LOAD BALANCER OUTPUTS
# ============================================================================

output "load_balancer_dns" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "load_balancer_url" {
  description = "Full URL to access the load balancer"
  value       = "http://${aws_lb.main.dns_name}"
}

# ============================================================================
# APPLICATION URLS
# ============================================================================

output "app_url" {
  description = "URL to access Flask application"
  value       = "http://${aws_lb.main.dns_name}/"
}

output "app_health_url" {
  description = "URL to check Flask app health"
  value       = "http://${aws_lb.main.dns_name}/health"
}

output "app_metrics_url" {
  description = "URL to view Flask app Prometheus metrics"
  value       = "http://${aws_lb.main.dns_name}/metrics"
}

output "prometheus_url" {
  description = "URL to access Prometheus UI"
  value       = "http://${aws_lb.main.dns_name}/prometheus"
}

output "grafana_url" {
  description = "URL to access Grafana dashboards"
  value       = "http://${aws_lb.main.dns_name}/grafana"
}

# ============================================================================
# ECS OUTPUTS
# ============================================================================

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

output "app_service_name" {
  description = "Name of the Flask app ECS service"
  value       = aws_ecs_service.app.name
}

output "prometheus_service_name" {
  description = "Name of the Prometheus ECS service"
  value       = aws_ecs_service.prometheus.name
}

output "grafana_service_name" {
  description = "Name of the Grafana ECS service"
  value       = aws_ecs_service.grafana.name
}

# ============================================================================
# CLOUDWATCH LOG GROUPS
# ============================================================================

output "app_log_group" {
  description = "CloudWatch log group for Flask app"
  value       = aws_cloudwatch_log_group.app.name
}

output "prometheus_log_group" {
  description = "CloudWatch log group for Prometheus"
  value       = aws_cloudwatch_log_group.prometheus.name
}

output "grafana_log_group" {
  description = "CloudWatch log group for Grafana"
  value       = aws_cloudwatch_log_group.grafana.name
}

# ============================================================================
# SECURITY GROUP IDs
# ============================================================================

output "alb_security_group_id" {
  description = "Security group ID for ALB"
  value       = aws_security_group.alb.id
}

output "app_security_group_id" {
  description = "Security group ID for Flask app"
  value       = aws_security_group.app.id
}

# ============================================================================
# DEPLOYMENT INSTRUCTIONS
# ============================================================================

output "deployment_instructions" {
  description = "Instructions for deploying the application"
  value = <<-EOT
  
  ========================================
  DEPLOYMENT INSTRUCTIONS
  ========================================
  
  1. LOGIN TO ECR:
     aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com
  
  2. BUILD FLASK APP IMAGE:
     cd ../app
     docker build -t ${var.project_name}-${var.environment}-app:latest .
  
  3. TAG IMAGE FOR ECR:
     docker tag ${var.project_name}-${var.environment}-app:latest ${aws_ecr_repository.app.repository_url}:latest
  
  4. PUSH TO ECR:
     docker push ${aws_ecr_repository.app.repository_url}:latest
  
  5. FORCE ECS TO REDEPLOY (pull new image):
     aws ecs update-service --cluster ${aws_ecs_cluster.main.name} --service ${aws_ecs_service.app.name} --force-new-deployment --region ${var.aws_region}
  
  6. ACCESS YOUR APPLICATIONS:
     Flask App:   http://${aws_lb.main.dns_name}/
     Prometheus:  http://${aws_lb.main.dns_name}/prometheus
     Grafana:     http://${aws_lb.main.dns_name}/grafana
  
  7. CHECK LOGS:
     aws logs tail ${aws_cloudwatch_log_group.app.name} --follow --region ${var.aws_region}
  
  ========================================
  EOT
}

# ============================================================================
# AWS ACCOUNT INFO
# ============================================================================

output "aws_account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  description = "AWS Region"
  value       = var.aws_region
}