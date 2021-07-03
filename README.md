# alarmdash

A simple way to visualize open Cloudwatch alarms.

There's no good way to quickly visualize open and important Cloudwatch alarms. Many AWS services create their own alarms (looking at you, target tracking scaling polices) and end up cluttering the alarms tab. Similarly, if you have an alarm configured to send to, say, Slack, it's very easy to lose that alarm.

## How It Works

alarmdash works by ingesting Cloudwatch alarms via SNS and sending important alarm info to DynamoDB.

How you want to expose the information in Dynamo is up to you. The alarmdash dashboard was built for AWS API Gateway with API key-based authentication.

### Alarm Pipeline

Cloudwatch alarm -> SNS -> Lambda -> Dynamo

### Dashboard

Users can view and delete records from DynamoDB from the dashboard.

## Usage

### Loader

#### Configuration

- LOADER_ALARMS_TABLE: The name of the DynamoDB table to store alarms in

### Frontend API

alarmdash uses AWS API Gateway to expose alarms for visualization. If you use the Terraform code located in `terraform/`, a usage plan will be created. **However**, no API keys will be generated. Once you've created API keys, you must pass them using the `x-api-key` header

Deleting an alarm:
```
curl -H "content-type: application/json" -H "x-api-key: KEY" -X DELETE -d '{"alarm_name": "alarm-name"}'   https://foo.execute-api.us-west-2.amazonaws.com/live/alarms
```

Retrieving all alarms:

```
curl -H "x-api-key: KEY" https://foo.execute-api.us-west-2.amazonaws.com/live/alarms
```

## External Alarms

In theory, you can ingest alarms from sources outside of Cloudwatch. As long as the SNS message satisfies the `AlarmEvent` struct, `loader` can add the event to DynamoDB. Alternatively, you could skip `loader` all together and have another process write to Dynamo.