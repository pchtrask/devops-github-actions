# Lambda function for secret rotation
resource "aws_lambda_function" "secret_rotation" {
  count = var.enable_secret_rotation ? 1 : 0

  filename         = data.archive_file.secret_rotation_zip[0].output_path
  source_code_hash = data.archive_file.secret_rotation_zip[0].output_base64sha256
  function_name = "devops-lesson-13-secret-rotation"
  role          = aws_iam_role.secret_rotation_role[0].arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"
  timeout       = 30

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      SECRETS_MANAGER_ENDPOINT = "https://secretsmanager.${var.aws_region}.amazonaws.com"
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.secret_rotation_logs,
    aws_iam_role_policy_attachment.secret_rotation_vpc,
    aws_cloudwatch_log_group.secret_rotation_logs,
  ]

  tags = {
    Name = "devops-lesson-13-secret-rotation"
  }
}

# CloudWatch Log Group for secret rotation Lambda
resource "aws_cloudwatch_log_group" "secret_rotation_logs" {
  count = var.enable_secret_rotation ? 1 : 0

  name              = "/aws/lambda/devops-lesson-13-secret-rotation"
  retention_in_days = 14
  kms_key_id        = aws_kms_key.main.arn

  tags = {
    Name = "devops-lesson-13-secret-rotation-logs"
  }
}

# IAM role for secret rotation Lambda
resource "aws_iam_role" "secret_rotation_role" {
  count = var.enable_secret_rotation ? 1 : 0

  name = "devops-lesson-13-secret-rotation-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for secret rotation
resource "aws_iam_role_policy" "secret_rotation_policy" {
  count = var.enable_secret_rotation ? 1 : 0

  name = "secret-rotation-policy"
  role = aws_iam_role.secret_rotation_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
          "secretsmanager:UpdateSecretVersionStage"
        ]
        Resource = aws_secretsmanager_secret.db_credentials.arn
      },
      {
        Effect = "Allow"
        Action = [
          "rds:ModifyDBInstance",
          "rds:DescribeDBInstances"
        ]
        Resource = aws_db_instance.main.arn
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = aws_kms_key.main.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "secret_rotation_logs" {
  count = var.enable_secret_rotation ? 1 : 0

  role       = aws_iam_role.secret_rotation_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "secret_rotation_vpc" {
  count = var.enable_secret_rotation ? 1 : 0

  role       = aws_iam_role.secret_rotation_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Lambda permission for Secrets Manager to invoke the rotation function
resource "aws_lambda_permission" "allow_secret_manager_call_Lambda" {
  count = var.enable_secret_rotation ? 1 : 0

  function_name = aws_lambda_function.secret_rotation[0].function_name
  statement_id  = "AllowExecutionFromSecretsManager"
  action        = "lambda:InvokeFunction"
  principal     = "secretsmanager.amazonaws.com"
}

# Secret rotation configuration
resource "aws_secretsmanager_secret_rotation" "db_credentials" {
  count = var.enable_secret_rotation ? 1 : 0

  secret_id           = aws_secretsmanager_secret.db_credentials.id
  rotation_lambda_arn = aws_lambda_function.secret_rotation[0].arn

  rotation_rules {
    automatically_after_days = var.secret_rotation_days
  }

  depends_on = [aws_lambda_permission.allow_secret_manager_call_Lambda]
}

# Create the rotation Lambda function code
data "archive_file" "secret_rotation_zip" {
  count = var.enable_secret_rotation ? 1 : 0

  type        = "zip"
  output_path = "secret_rotation.zip"

  source {
    content = templatefile("${path.module}/secret_rotation_lambda.py", {
      db_instance_identifier = aws_db_instance.main.identifier
    })
    filename = "lambda_function.py"
  }
}

# EventBridge rule for monitoring secret rotation
resource "aws_cloudwatch_event_rule" "secret_rotation_monitor" {
  count = var.enable_secret_rotation ? 1 : 0

  name        = "devops-lesson-13-secret-rotation-monitor"
  description = "Monitor secret rotation events"

  event_pattern = jsonencode({
    source      = ["aws.secretsmanager"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventSource = ["secretsmanager.amazonaws.com"]
      eventName   = ["RotateSecret"]
      resources = {
        ARN = [aws_secretsmanager_secret.db_credentials.arn]
      }
    }
  })

  tags = {
    Name = "devops-lesson-13-secret-rotation-monitor"
  }
}

# CloudWatch alarm for failed secret rotations
resource "aws_cloudwatch_metric_alarm" "secret_rotation_failures" {
  count = var.enable_secret_rotation ? 1 : 0

  alarm_name          = "devops-lesson-13-secret-rotation-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors secret rotation failures"
  alarm_actions       = [aws_sns_topic.alerts[0].arn]

  dimensions = {
    FunctionName = aws_lambda_function.secret_rotation[0].function_name
  }

  tags = {
    Name = "devops-lesson-13-secret-rotation-alarm"
  }
}

# SNS topic for alerts
resource "aws_sns_topic" "alerts" {
  count = var.enable_secret_rotation ? 1 : 0

  name              = "devops-lesson-13-alerts"
  kms_master_key_id = aws_kms_key.main.key_id

  tags = {
    Name = "devops-lesson-13-alerts"
  }
}
