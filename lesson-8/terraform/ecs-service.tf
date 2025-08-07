resource "aws_ecs_cluster" "lesson8" {
  name = "lesson8"
}

resource "aws_cloudwatch_log_group" "lesson8" {
  name              = "/ecs/lesson8"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "lesson8" {
  family                   = "lesson8"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  task_role_arn            = aws_iam_role.ecs_role.arn
  execution_role_arn       = aws_iam_role.ecs_role.arn

  container_definitions = jsonencode([
    {
      name      = "web"
      image     = "${var.aws_account_id}.dkr.ecr.eu-central-1.amazonaws.com/mynginx:latest"
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.lesson8.name
          "awslogs-region"        = "eu-central-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}


resource "aws_ecs_service" "lesson8" {
  name            = "lesson8"
  cluster        = aws_ecs_cluster.lesson8.id
  task_definition = aws_ecs_task_definition.lesson8.arn
  desired_count   = 1

  launch_type = "FARGATE"

  network_configuration {
    subnets          = [data.aws_subnets.ecssubnets.ids[0], data.aws_subnets.ecssubnets.ids[1]]
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

    load_balancer {
        target_group_arn = aws_lb_target_group.main.arn
        container_name   = "web"
        container_port   = 80
    }
}