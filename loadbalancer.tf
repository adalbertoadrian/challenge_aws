# load balancer security group
resource "aws_security_group" "lb_security_group" {
  name        = "lb_security_group"
  description = "lb_security_group"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
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

# load balancer 
resource "aws_lb" "wordpress_lb" {
  name            = "wordpress-lb"
  internal        = false
  security_groups = ["${aws_security_group.lb_security_group.id}"]
  subnets         = ["subnet-0116ba0c90d686a6b", "subnet-0b02a111f2875be85"]

}

# load balancer listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.wordpress_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wordpress_target_group.arn // Redirigir al grupo de destino
  }
}

# load balancer target group
resource "aws_lb_target_group" "wordpress_target_group" {
  vpc_id   = "vpc-0c0f19362c0d3d2d7"
  name     = "wordpress-targets"
  port     = 80
  protocol = "HTTP"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# instances security group
resource "aws_security_group" "instance_security_group" {
  name        = "instance_security_group"
  description = "Grupo de seguridad para las instancias de WordPress"

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

# template
resource "aws_launch_template" "wordpress_template" {
  name_prefix   = "challenger"
  image_id      = "ami-0ef93f10e57da46b4"
  instance_type = "t2.micro"

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.instance_security_group.id]
  }
}

# autoscaling group
resource "aws_autoscaling_group" "wordpress_autoscaling" {
  availability_zones = ["us-east-1a", "us-east-1b"]
  desired_capacity   = 2
  max_size           = 3
  min_size           = 1

  launch_template {
    id      = aws_launch_template.wordpress_template.id
    version = "$Latest"
  }
}

# autoscaling group attachment
resource "aws_autoscaling_attachment" "wordpress_template_attachment" {
  autoscaling_group_name = aws_autoscaling_group.wordpress_autoscaling.id
  lb_target_group_arn    = aws_lb_target_group.wordpress_target_group.arn
}