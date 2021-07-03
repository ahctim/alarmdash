resource "aws_sns_topic" "loader" {
  name              = var.sns_topic_name
  kms_master_key_id = var.sns_topic_kms_key_id
  tags              = var.sns_topic_tags
}

resource "aws_sns_topic_subscription" "sns-topic" {
  topic_arn = aws_sns_topic.loader.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.loader.arn
}