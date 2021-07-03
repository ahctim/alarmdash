resource "aws_dynamodb_table" "table" {
  name         = var.alarms_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "alarm_name"

  attribute {
    name = "alarm_name"
    type = "S"
  }

  tags = var.alarms_table_tags
}