resource "aws_launch_template" "template" {
  name_prefix            = var.name_prefix
  image_id               = "ami-060e838bdb16a275f"
  instance_type          = "t2.micro"
  vpc_security_group_ids = ["${var.security_group}"]
}

resource "aws_autoscaling_group" "autoscale" {
  name                 = "test-autoscaling-group"
  desired_capacity     = 1
  max_size             = 2
  min_size             = 1
  health_check_type    = "EC2"
  termination_policies = ["OldestInstance"]
  vpc_zone_identifier  = ["${var.public_sub}"]

  launch_template {
    id      = aws_launch_template.template.id
    version = "$Latest"
  }
}