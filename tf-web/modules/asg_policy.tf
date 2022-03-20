resource "aws_autoscaling_policy" "web_policy_up" {
  name = "web_policy_up"
  scaling_adjustment = 1
  adjustment_type = "ChangeInCapacity"
  cooldown = 200
  autoscaling_group_name = "${aws_autoscaling_group.web.name}"
}
resource "aws_cloudwatch_metric_alarm" "web_cpu_alarm_up" {
  alarm_name = "web_cpu_alarm_up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "50"
dimensions = {
  AutoScalingGroupName = "${aws_autoscaling_group.web.name}"
}
alarm_description = "This metric monitor EC2 instance CPU scale up utilization"
alarm_actions = [ "${aws_autoscaling_policy.web_policy_up.arn}" ]
}
resource "aws_autoscaling_policy" "web_policy_down" {
  name = "web_policy_down"
  scaling_adjustment = -1
  adjustment_type = "ChangeInCapacity"
  cooldown = 200
  autoscaling_group_name = "${aws_autoscaling_group.web.name}"
}
resource "aws_cloudwatch_metric_alarm" "web_cpu_alarm_down" {
  alarm_name = "web_cpu_alarm_down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "20"
dimensions = {
  AutoScalingGroupName = "${aws_autoscaling_group.web.name}"
}
alarm_description = "This metric monitor EC2 instance CPU scale down utilization"
alarm_actions = [ "${aws_autoscaling_policy.web_policy_down.arn}" ]
}