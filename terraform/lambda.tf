# ============================================================================
# SNS TOPIC FOR ALERTS
# ============================================================================

resource "aws_sns_topic" "anomaly_alerts" {
  name = "${var.project_name}-${var.environment}-anomaly-alerts"

  tags = {
    Name = "${var.project_name}-${var.environment}-anomaly-alerts"
  }
}

resource "aws_sns_topic_subscription" "anomaly_alerts_email" {
  topic_arn = aws_sns_topic.anomaly_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email  # We'll add this variable
}

# ============================================================================
# IAM ROLE FOR LAMBDA
# ============================================================================

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_anomaly_detection" {
  name               = "${var.project_name}-${var.environment}-lambda-anomaly"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = {
    Name = "${var.project_name}-${var.environment}-lambda-anomaly-role"
  }
}

# Lambda execution policy
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_anomaly_detection.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Custom policy for CloudWatch, ECS, and SNS access
resource "aws_iam_role_policy" "lambda_anomaly_policy" {
  name = "${var.project_name}-${var.environment}-lambda-anomaly-policy"
  role = aws_iam_role.lambda_anomaly_detection.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricData"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:DescribeServices",
          "ecs:UpdateService",
          "ecs:DescribeTasks",
          "ecs:ListTasks"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.anomaly_alerts.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# ============================================================================
# LAMBDA LAYER FOR DEPENDENCIES (numpy, scikit-learn)
# ============================================================================


# ============================================================================
# LAMBDA FUNCTION
# ============================================================================

resource "aws_lambda_function" "anomaly_detection" {
  filename      = "lambda_function.zip"  # We'll create this
  function_name = "${var.project_name}-${var.environment}-anomaly-detection"
  role          = aws_iam_role.lambda_anomaly_detection.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"
  timeout       = 300  # 5 minutes
  memory_size   = 512



  environment {
    variables = {
      CLUSTER_NAME  = aws_ecs_cluster.main.name
      SERVICE_NAME  = aws_ecs_service.app.name
      SNS_TOPIC_ARN = aws_sns_topic.anomaly_alerts.arn
      MIN_TASKS     = var.app_desired_count
      MAX_TASKS     = 10
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-anomaly-detection"
  }
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_anomaly" {
  name              = "/aws/lambda/${aws_lambda_function.anomaly_detection.function_name}"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-${var.environment}-lambda-anomaly-logs"
  }
}

# ============================================================================
# EVENTBRIDGE RULE TO TRIGGER LAMBDA EVERY 5 MINUTES
# ============================================================================

resource "aws_cloudwatch_event_rule" "anomaly_detection_schedule" {
  name                = "${var.project_name}-${var.environment}-anomaly-schedule"
  description         = "Trigger anomaly detection every 5 minutes"
  schedule_expression = "rate(5 minutes)"

  tags = {
    Name = "${var.project_name}-${var.environment}-anomaly-schedule"
  }
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.anomaly_detection_schedule.name
  target_id = "AnomalyDetectionLambda"
  arn       = aws_lambda_function.anomaly_detection.arn
}

# Allow EventBridge to invoke Lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.anomaly_detection.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.anomaly_detection_schedule.arn
}
