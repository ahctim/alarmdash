variable "region" {
  type        = string
  description = "The AWS region to deploy resources to"
}

variable "loader_function_name" {
  type        = string
  description = "Name of loader Lambda function"
  default     = "alarmdash-loader"
}

variable "alarms_table_name" {
  type        = string
  description = "The name of the DynamoDB table to store alarms in"
  default     = "alarmdash"
}

variable "sns_topic_name" {
  type        = string
  description = "The name of the SNS topic that alarms will send messages to"
  default     = "alarmdash-loader"
}

variable "usage_plan_tags" {
  type = map(any)
}

variable "api_gw_role_tags" {
  type = map(any)
}

variable "alarms_table_tags" {
  type = map(any)
}

variable "loader_function_tags" {
  type = map(any)
}

variable "sns_topic_tags" {
  type = map(any)
}

variable "sns_topic_kms_key_id" {
  type    = string
  default = null
}


variable "loader_zip_url" {
  type    = string
  default = "https://github.com/ahctim/alarmdash/releases/download/v0.1.0/loader.zip"
}