output "usage_plan_name" {
  value = aws_api_gateway_usage_plan.plan.name
}

output "usage_plan_id" {
  value = aws_api_gateway_usage_plan.plan.id
}

output "usage_plan_arn" {
  value = aws_api_gateway_usage_plan.plan.arn
}

output "sns_topic_arn" {
  value = aws_sns_topic.loader.arn
}

output "sns_topic_id" {
  value = aws_sns_topic.loader.id
}