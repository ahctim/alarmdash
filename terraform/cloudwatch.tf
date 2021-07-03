resource "aws_cloudwatch_log_group" "loader" {
  name              = "/aws/lambda/${aws_lambda_function.loader.function_name}"
  retention_in_days = 1
  tags              = var.loader_function_tags
}