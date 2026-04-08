resource "aws_launch_template" "web_template" {
  name_prefix   = "web-template"
  image_id      = "ami-0f5ee92e2d63afc18"
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = base64encode("""
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo \"<h1>AutoScaling Demo by Arif</h1>\" > /var/www/html/index.html
              """)
}

