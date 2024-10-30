# database security group
resource "aws_security_group" "db_security_group" {
  name        = "db_security_group"
  description = "Security group for the database"

  ingress {
    from_port   = 3306
    to_port     = 3306
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

# webapplication database
resource "aws_db_instance" "webapplication_database" {
  identifier                = "webapplication-database"
  allocated_storage         = 20
  storage_type              = "gp2"
  engine                    = "mysql"
  engine_version            = "8.0"
  instance_class            = "db.t4g.small"
  username                  = var.database_user
  password                  = var.database_password
  multi_az                  = true
  backup_retention_period   = 7
  skip_final_snapshot       = false
  final_snapshot_identifier = "finalSnapshotWebapplicationDatabase"

  vpc_security_group_ids = [aws_security_group.db_security_group.id]
}

# database cpu alarm
resource "aws_cloudwatch_metric_alarm" "cpu_alarm" {
  alarm_name          = "CPU_Utilization_Alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "80% cpu alarm for webapplication_database"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.webapplication_database.id
  }
  alarm_actions = ["arn:aws:sns:us-east-1:879381245435:Notifications"]
}

# database connections alarm 
resource "aws_cloudwatch_metric_alarm" "connections_alarm" {
  alarm_name          = "Database_Connections_Alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Average"
  threshold           = "100"
  alarm_description   = "connections > 100 for webapplication_database"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.webapplication_database.id
  }
  alarm_actions = ["arn:aws:sns:us-east-1:879381245435:Notifications"]
}

# database disk alarm
resource "aws_cloudwatch_metric_alarm" "disk_space_alarm" {
  alarm_name          = "FreeStorageSpace_Alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Average"
  threshold           = "5000000000"
  alarm_description   = "5GB alarm for webapplication_database"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.webapplication_database.id
  }
  alarm_actions = ["arn:aws:sns:us-east-1:879381245435:Notifications"]
}