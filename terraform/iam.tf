// Loader Lambda
data "aws_iam_policy_document" "loader_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "loader" {
  name               = "alarmdash-loader-lambda"
  assume_role_policy = data.aws_iam_policy_document.loader_role.json
  tags               = var.loader_function_tags
}

data "aws_iam_policy_document" "loader_policy" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]
    resources = [
      "${aws_dynamodb_table.table.arn}"
    ]
  }
}

resource "aws_iam_policy" "loader" {
  name   = "alarmdash-loader-lambda"
  path   = "/"
  policy = data.aws_iam_policy_document.loader_policy.json
}

resource "aws_iam_role_policy_attachment" "loader_ddb" {
  role       = aws_iam_role.loader.name
  policy_arn = aws_iam_policy.loader.arn
}

resource "aws_iam_role_policy_attachment" "loader_logs" {
  role       = aws_iam_role.loader.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

// API Gateway
data "aws_iam_policy_document" "api_gw_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "api_gw" {
  name               = "alarmdash-api-gw"
  assume_role_policy = data.aws_iam_policy_document.api_gw_role.json
  tags               = var.api_gw_role_tags
}

data "aws_iam_policy_document" "api_gw" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:DeleteItem",
      "dynamodb:Scan"
    ]
    resources = [
      "${aws_dynamodb_table.table.arn}",
      "${aws_dynamodb_table.table.arn}/index/*",
    ]
  }
}

resource "aws_iam_policy" "api_gw" {
  name   = "alarmdash-api-gw"
  path   = "/"
  policy = data.aws_iam_policy_document.api_gw.json
}

resource "aws_iam_role_policy_attachment" "api_gw_ddb" {
  role       = aws_iam_role.api_gw.name
  policy_arn = aws_iam_policy.api_gw.arn
}

resource "aws_iam_role_policy_attachment" "api_gw_logs" {
  role       = aws_iam_role.api_gw.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

// SNS invoke Lambda

resource "aws_lambda_permission" "allow_sns_invoke_lambda" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.loader.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.loader.arn
}