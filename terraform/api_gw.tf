resource "aws_api_gateway_rest_api" "gw" {
  name = "alarmdash"
}

resource "aws_api_gateway_resource" "alarms" {
  parent_id   = aws_api_gateway_rest_api.gw.root_resource_id
  path_part   = "alarms"
  rest_api_id = aws_api_gateway_rest_api.gw.id
}

resource "aws_api_gateway_resource" "bugsnag" {
  parent_id   = aws_api_gateway_resource.alarms.id
  path_part   = "bugsnag"
  rest_api_id = aws_api_gateway_rest_api.gw.id
}

resource "aws_api_gateway_method" "get_alarms" {
  authorization    = "NONE"
  http_method      = "GET"
  resource_id      = aws_api_gateway_resource.alarms.id
  rest_api_id      = aws_api_gateway_rest_api.gw.id
  api_key_required = true
}

resource "aws_api_gateway_method" "delete_alarm" {
  authorization    = "NONE"
  http_method      = "DELETE"
  resource_id      = aws_api_gateway_resource.alarms.id
  rest_api_id      = aws_api_gateway_rest_api.gw.id
  api_key_required = true
}

resource "aws_api_gateway_method" "bugsnag" {
  authorization    = "NONE"
  http_method      = "POST"
  resource_id      = aws_api_gateway_resource.bugsnag.id
  rest_api_id      = aws_api_gateway_rest_api.gw.id
  api_key_required = false
}

resource "aws_api_gateway_integration" "ddb_scan" {
  http_method             = aws_api_gateway_method.get_alarms.http_method
  resource_id             = aws_api_gateway_resource.alarms.id
  rest_api_id             = aws_api_gateway_rest_api.gw.id
  credentials             = aws_iam_role.api_gw.arn
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${var.region}:dynamodb:action/Scan"
  integration_http_method = "POST"
  passthrough_behavior    = "WHEN_NO_TEMPLATES"

  request_templates = {
    "application/json" = <<EOF
{
    "TableName": "${var.alarms_table_name}"
}
EOF
  }
}

resource "aws_api_gateway_integration" "ddb_delete" {
  http_method             = aws_api_gateway_method.delete_alarm.http_method
  resource_id             = aws_api_gateway_resource.alarms.id
  rest_api_id             = aws_api_gateway_rest_api.gw.id
  credentials             = aws_iam_role.api_gw.arn
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${var.region}:dynamodb:action/DeleteItem"
  integration_http_method = "POST"
  passthrough_behavior    = "WHEN_NO_TEMPLATES"

  request_templates = {
    "application/json" = <<EOF
{
    "TableName": "${var.alarms_table_name}",
    "Key": {
      "alarm_source": {
          "S": $input.json('$.alarm_source')
        },
        "alarm_name": {
            "S": $input.json('$.alarm_name')
        }
    }
}
EOF
  }
}

// Bugsnag webhook docs: https://docs.bugsnag.com/product/integrations/data-forwarding/webhook/
resource "aws_api_gateway_integration" "bugsnag_add" {
  http_method             = aws_api_gateway_method.bugsnag.http_method
  resource_id             = aws_api_gateway_resource.bugsnag.id
  rest_api_id             = aws_api_gateway_rest_api.gw.id
  credentials             = aws_iam_role.api_gw.arn
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${var.region}:dynamodb:action/PutItem"
  integration_http_method = "POST"
  passthrough_behavior    = "WHEN_NO_TEMPLATES"

  request_templates = {
    "application/json" = <<EOF
{
    "TableName": "${var.alarms_table_name}",
    "Key": {
      "alarm_source": {
          "S": BUGSNAG
        },
        "alarm_name": {
            "S": $input.json('$.error.message')
        },
        "description": {
          "S": $input.json('$.error.exceptionClass')
        },
        "alarm_state": {
          "S": $input.json('$.error.status')
        },
        "alarm_reason": {
          "S": $input.json('$.trigger.message')
        },
        "created": {
          "S": $input.json('$.error.receivedAt')
        },
    }
}
EOF
  }
}

resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.gw.id
  resource_id = aws_api_gateway_resource.alarms.id
  http_method = aws_api_gateway_method.get_alarms.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "get_alarms" {
  rest_api_id = aws_api_gateway_rest_api.gw.id
  resource_id = aws_api_gateway_resource.alarms.id
  http_method = aws_api_gateway_method.get_alarms.http_method
  status_code = aws_api_gateway_method_response.response_200.status_code

  response_templates = {
    "application/json" = <<EOF
#set($inputRoot = $input.path('$'))
{
    "alarms": [
        #foreach($elem in $inputRoot.Items) {
            "alarm_source": "$elem.alarm_source.S",
            "alarm_name": "$elem.alarm_name.S",
            "alarm_created": "$elem.created.S",
            "alarm_description": "$elem.description.S",
            "alarm_reason": "$elem.alarm_reason.S",
            "alarm_region": "$elem.region.S",
        }#if($foreach.hasNext),#end
	#end
    ]
}
EOF
  }
}

resource "aws_api_gateway_integration_response" "delete_alarm" {
  rest_api_id = aws_api_gateway_rest_api.gw.id
  resource_id = aws_api_gateway_resource.alarms.id
  http_method = aws_api_gateway_method.delete_alarm.http_method
  status_code = aws_api_gateway_method_response.response_200.status_code

  response_templates = {
    "application/json" = <<EOF
{"ok": "yes"}
EOF
  }
}

resource "aws_api_gateway_method_response" "bugsnag_response_200" {
  rest_api_id = aws_api_gateway_rest_api.gw.id
  resource_id = aws_api_gateway_resource.bugsnag.id
  http_method = aws_api_gateway_method.bugsnag.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "bugsnag" {
  rest_api_id = aws_api_gateway_rest_api.gw.id
  resource_id = aws_api_gateway_resource.bugsnag.id
  http_method = aws_api_gateway_method.bugsnag.http_method
  status_code = aws_api_gateway_method_response.bugsnag_response_200.status_code

  response_templates = {
    "application/json" = <<EOF
{"ok": "yes"}
EOF
  }

  depends_on = [
    aws_api_gateway_method_response.bugsnag_response_200
  ]
}

resource "aws_api_gateway_method_response" "response_200_delete" {
  rest_api_id = aws_api_gateway_rest_api.gw.id
  resource_id = aws_api_gateway_resource.alarms.id
  http_method = aws_api_gateway_method.delete_alarm.http_method
  status_code = "200"
}

resource "aws_api_gateway_deployment" "live" {
  rest_api_id = aws_api_gateway_rest_api.gw.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.alarms.id,
      aws_api_gateway_method.get_alarms.id,
      aws_api_gateway_integration.ddb_scan.id,
      aws_api_gateway_integration.ddb_delete.id,
      aws_api_gateway_integration.bugsnag_add.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "live" {
  deployment_id = aws_api_gateway_deployment.live.id
  rest_api_id   = aws_api_gateway_rest_api.gw.id
  stage_name    = "live"

}


resource "aws_api_gateway_usage_plan" "plan" {
  name        = "alarmdash"
  description = "alarmdash usage plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.gw.id
    stage  = aws_api_gateway_stage.live.stage_name
  }

  throttle_settings {
    burst_limit = 2
    rate_limit  = 1 // 1 request / second
  }

  tags = var.usage_plan_tags
}