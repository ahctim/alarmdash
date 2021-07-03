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