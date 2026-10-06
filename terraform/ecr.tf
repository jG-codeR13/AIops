# ============================================================================
# ECR REPOSITORY - FLASK APPLICATION
# ============================================================================

resource "aws_ecr_repository" "app" {
  name                 = "${var.project_name}-${var.environment}-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true  # Automatically scan images for vulnerabilities
  }

  encryption_configuration {
    encryption_type = "AES256"  # Encrypt images at rest
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-app-repo"
  }
}

# Lifecycle policy to clean up old images (keep last 10)
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus     = "any"
        countType     = "imageCountMoreThan"
        countNumber   = 10
      }
      action = {
        type = "expire"
      }
    }]
  })
}

# ============================================================================
# ECR REPOSITORY - PROMETHEUS (Optional - can use public image)
# ============================================================================

# Note: We can use the official Prometheus image from Docker Hub
# But if you want to customize Prometheus config, create a custom image here

resource "aws_ecr_repository" "prometheus" {
  name                 = "${var.project_name}-${var.environment}-prometheus"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-prometheus-repo"
  }
}

resource "aws_ecr_lifecycle_policy" "prometheus" {
  repository = aws_ecr_repository.prometheus.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 5 images"
      selection = {
        tagStatus     = "any"
        countType     = "imageCountMoreThan"
        countNumber   = 5
      }
      action = {
        type = "expire"
      }
    }]
  })
}

# ============================================================================
# ECR REPOSITORY - GRAFANA (Optional - can use public image)
# ============================================================================

resource "aws_ecr_repository" "grafana" {
  name                 = "${var.project_name}-${var.environment}-grafana"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-grafana-repo"
  }
}

resource "aws_ecr_lifecycle_policy" "grafana" {
  repository = aws_ecr_repository.grafana.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 5 images"
      selection = {
        tagStatus     = "any"
        countType     = "imageCountMoreThan"
        countNumber   = 5
      }
      action = {
        type = "expire"
      }
    }]
  })
}
