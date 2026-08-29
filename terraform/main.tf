resource "aws_security_group" "alb_sg" {
  name = "alb-sg"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "web_sg" {
  name = "web-sg"

  ingress {
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "archive_file" "app_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../app"
  output_path = "${path.module}/app.zip"
  excludes = [
    "backend/node_modules",
    "frontend/node_modules",
    "frontend/dist",
    "backend/public",
    "backend/package-lock.json",
    "frontend/package-lock.json",
    "Dockerfile",
    "app.zip"
  ]
}

resource "aws_launch_template" "web_lt" {
  name_prefix   = "web-lt-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    app_port       = var.app_port
    app_zip_base64 = filebase64(data.archive_file.app_zip.output_path)
  }))
}

resource "aws_autoscaling_group" "web_asg" {
  name                = "web-asg"
  min_size            = var.min_size
  desired_capacity    = var.desired_capacity
  max_size            = var.max_size
  vpc_zone_identifier = local.effective_subnet_ids
  target_group_arns   = [aws_lb_target_group.app_tg.arn]
  health_check_type   = "ELB"
  health_check_grace_period = 300

  instance_refresh {
    strategy = "Rolling"

    preferences {
      min_healthy_percentage = 50
    }
  }

  launch_template {
    id      = aws_launch_template.web_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "web-autoscale-instance"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "cpu_target_tracking" {
  name                   = "web-asg-cpu-target"
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = var.cpu_target_utilization
  }
}
