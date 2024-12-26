resource "aws_cloudwatch_log_group" "log_group" {
  name = "${var.project_name}-log-group"
  tags = local.tags
}
