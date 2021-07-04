#!/usr/bin/env bash

TABLE=alarmdash

aws dynamodb put-item \
--table-name $TABLE \
--item '{"alarm_source": {"S": "EXTERNAL_WEBHOOK"}, "alarm_name": {"S": "test one"}, "alarm_region": {"S": "US West"}, "description": {"S": "Test one"}, "alarm_reason": {"S": "testing"}, "alarm_state": {"S": "ALARM"} }'

aws dynamodb put-item \
--table-name $TABLE \
--item '{"alarm_source": {"S": "CLOUDWATCH"}, "alarm_name": {"S": "test one"}, "alarm_region": {"S": "US West"}, "description": {"S": "Test one"}, "alarm_reason": {"S": "testing"}, "alarm_state": {"S": "ALARM"} }'