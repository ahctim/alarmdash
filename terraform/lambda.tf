
resource "null_resource" "lambda_zip" {
  triggers = {
    on_version_change = var.loader_zip_url
  }

  provisioner "local-exec" {
    command = "wget -O loader.zip ${var.loader_zip_url}"
  }
}

resource "aws_lambda_function" "loader" {
  function_name = var.loader_function_name
  filename      = "loader.zip"
  memory_size   = 128
  package_type  = "Zip"
  runtime       = "go1.x"
  handler       = "loader"
  timeout       = 5
  role          = aws_iam_role.loader.arn
  reserved_concurrent_executions = var.lambda_reserved_concurrent_executions

  environment {
    variables = {
      LOADER_ALARMS_TABLE = var.alarms_table_name
    }
  }

  tags = var.loader_function_tags

  depends_on = [
    null_resource.lambda_zip
  ]
  
}

resource "aws_lambda_function_event_invoke_config" "loader" {
  function_name                = aws_lambda_function.loader.function_name
  maximum_event_age_in_seconds = 300
  maximum_retry_attempts       = 1 // In the event of a DDB error
}