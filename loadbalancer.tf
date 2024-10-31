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
    type = "redirect"
    redirect {
      host        = "#{host}"
      path        = "/"
      port        = "443"
      protocol    = "HTTPS"
      query       = "#{query}"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.wordpress_lb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:us-east-1:879381245435:certificate/95e34038-6e11-483e-9f52-e59623ada37b"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wordpress_target_group.arn
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

# template
resource "aws_launch_template" "wordpress_template" {
  name_prefix   = "challenger"
  image_id      = "ami-0ddac4781e05b61ec"
  instance_type = "t2.micro"

  monitoring {
    enabled = true
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.instance_security_group.id]
  }

  user_data = filebase64("${path.module}/ec2_launch.sh")
}

# autoscaling group
resource "aws_autoscaling_group" "wordpress_autoscaling" {
  availability_zones = ["us-east-1a", "us-east-1b"]
  desired_capacity   = 2
  max_size           = 3
  min_size           = 2

  launch_template {
    id      = aws_launch_template.wordpress_template.id
    version = "$Latest"
  }

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]
  metrics_granularity = "1Minute"
}

# autoscaling group attachment
resource "aws_autoscaling_attachment" "wordpress_template_attachment" {
  autoscaling_group_name = aws_autoscaling_group.wordpress_autoscaling.id
  lb_target_group_arn    = aws_lb_target_group.wordpress_target_group.arn
}

# scaling up cpu policy
resource "aws_autoscaling_policy" "wordpress_web_policy_up" {
  name                   = "web_policy_up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.wordpress_autoscaling.name
}

# scaling up cpu alarm
resource "aws_cloudwatch_metric_alarm" "wordpress_web_cpu_alarm_up" {
  alarm_name          = "web_cpu_alarm_up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "70"
  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.wordpress_autoscaling.name}"
  }
  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions = [
    "${aws_autoscaling_policy.wordpress_web_policy_up.arn}",
    var.sns_topic
  ]
}

# scaling down cpu policy
resource "aws_autoscaling_policy" "wordpress_web_policy_down" {
  name                   = "web_policy_down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.wordpress_autoscaling.name
}

# scaling down cpu alarm
resource "aws_cloudwatch_metric_alarm" "wordpress_web_cpu_alarm_down" {
  alarm_name          = "web_cpu_alarm_down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "60"
  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.wordpress_autoscaling.name}"
  }
  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions = [
    "${aws_autoscaling_policy.wordpress_web_policy_down.arn}",
    var.sns_topic
  ]
}