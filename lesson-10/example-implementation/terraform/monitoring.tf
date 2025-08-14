

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "example-app"
}

variable "alert_email" {
  description = "Email for alerts"
  type        = string
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/aws/ec2/${var.app_name}"
  retention_in_days = 7
  
  tags = {
    Environment = var.environment
    Application = var.app_name
  }
}

# SNS Topic for alerts
resource "aws_sns_topic" "alerts" {
  name = "${var.app_name}-alerts"
  
  tags = {
    Environment = var.environment
    Application = var.app_name
  }
}

# SNS Topic Subscription
resource "aws_sns_topic_subscription" "email_alerts" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "high_response_time" {
  alarm_name          = "${var.app_name}-high-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ResponseTime"
  namespace           = "ExampleApp/Performance"
  period              = "180"
  statistic           = "Maximum"
  threshold           = "1"
  alarm_description   = "This metric monitors response time"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    Endpoint = "/api/users"
  }

  tags = {
    Environment = var.environment
    Application = var.app_name
  }
}

resource "aws_cloudwatch_metric_alarm" "high_error_rate" {
  alarm_name          = "${var.app_name}-high-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "RequestCount"
  namespace           = "ExampleApp/Performance"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors error rate"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    StatusCode = "500"
  }

  tags = {
    Environment = var.environment
    Application = var.app_name
  }
}

resource "aws_cloudwatch_metric_alarm" "app_down" {
  alarm_name          = "${var.app_name}-application-down"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "RequestCount"
  namespace           = "ExampleApp/Performance"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Application appears to be down - no requests received"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "breaching"

  tags = {
    Environment = var.environment
    Application = var.app_name
  }
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.app_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["ExampleApp/Performance", "ResponseTime", "Endpoint", "/api/users"],
            [".", ".", ".", "/api/orders"],
            [".", ".", ".", "/health"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Response Time by Endpoint"
          period  = 300
          stat    = "Average"
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["ExampleApp/Performance", "RequestCount", "StatusCode", "200"],
            [".", ".", ".", "404"],
            [".", ".", ".", "500"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Request Count by Status Code"
          period  = 300
          stat    = "Sum"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["ExampleApp/Performance", "RequestCount", "Endpoint", "/api/users"],
            [".", ".", ".", "/api/orders"],
            [".", ".", ".", "/health"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Request Count by Endpoint"
          period  = 300
          stat    = "Sum"
        }
      },
      {
        type   = "log"
        x      = 12
        y      = 6
        width  = 12
        height = 6

        properties = {
          query   = "SOURCE '${aws_cloudwatch_log_group.app_logs.name}'\n| fields @timestamp, level, message, correlationId\n| filter level = \"ERROR\"\n| sort @timestamp desc\n| limit 20"
          region  = var.aws_region
          title   = "Recent Errors"
          view    = "table"
        }
      }
    ]
  })
}

# IAM Role for EC2 to write to CloudWatch
resource "aws_iam_role" "cloudwatch_role" {
  name = "${var.app_name}-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    Application = var.app_name
  }
}

resource "aws_iam_role_policy" "cloudwatch_policy" {
  name = "${var.app_name}-cloudwatch-policy"
  role = aws_iam_role.cloudwatch_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "cloudwatch_profile" {
  name = "${var.app_name}-cloudwatch-profile"
  role = aws_iam_role.cloudwatch_role.name
}

# Outputs
output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = aws_sns_topic.alerts.arn
}

output "dashboard_url" {
  description = "URL of the CloudWatch dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.app_logs.name
}

output "iam_instance_profile_name" {
  description = "Name of the IAM instance profile for EC2"
  value       = aws_iam_instance_profile.cloudwatch_profile.name
}
