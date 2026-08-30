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

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    app_port       = var.app_port
    s3_bucket_name = aws_s3_bucket.app_bucket.id
    app_version    = aws_s3_object.app_zip.etag
  }))
}

resource "aws_autoscaling_group" "web_asg" {
  name                      = "web-asg"
  min_size                  = var.min_size
  desired_capacity          = var.desired_capacity
  max_size                  = var.max_size
  vpc_zone_identifier       = local.effective_subnet_ids
  target_group_arns         = [aws_lb_target_group.app_tg.arn]
  health_check_type         = "ELB"
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

  # Ensure IAM roles/policies are fully attached before instances scale up
  depends_on = [
    aws_iam_role_policy_attachment.s3_read_attach,
    aws_iam_role_policy_attachment.ssm_attach
  ]
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

# Private S3 Bucket for Storing Application Builds
resource "aws_s3_bucket" "app_bucket" {
  bucket_prefix = "auto-scaling-app-bucket-"
  force_destroy = true
}

# Block Public Access to S3 Bucket
resource "aws_s3_bucket_public_access_block" "app_bucket_public_access" {
  bucket = aws_s3_bucket.app_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Object containing the application package
resource "aws_s3_object" "app_zip" {
  bucket = aws_s3_bucket.app_bucket.id
  key    = "app.zip"
  source = data.archive_file.app_zip.output_path
  etag   = data.archive_file.app_zip.output_md5
}

# IAM Role for EC2 Instances
resource "aws_iam_role" "ec2_role" {
  name = "web-ec2-s3-ssm-role"

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
}

# Least-privilege IAM Policy allowing read access only to app.zip in the bucket
resource "aws_iam_policy" "s3_read_policy" {
  name        = "web-ec2-s3-read-policy"
  description = "Allows EC2 instances to read app.zip from the application S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = [
          "${aws_s3_bucket.app_bucket.arn}/app.zip"
        ]
      }
    ]
  })
}

# Attach the custom S3 policy to the EC2 IAM Role
resource "aws_iam_role_policy_attachment" "s3_read_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_read_policy.arn
}

# Attach SSM Core policy to allow Session Manager access
resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM Instance Profile referencing the EC2 IAM Role
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "web-ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}
