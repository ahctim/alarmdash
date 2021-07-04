package main

import (
	"context"
	"fmt"
	"reflect"
	"testing"

	"github.com/ahctim/alarmdash/pkg/types"
	"github.com/aws/aws-lambda-go/events"
)

// alarmState must be one of OK, ALARM, or INSUFFICIENT_DATA
func generateSNSMessage(alarmState string) events.SNSEvent {
	var e events.SNSEvent
	var sr events.SNSEventRecord
	var se events.SNSEntity

	se.Message = fmt.Sprintf(`{"AlarmName":"loader-test","AlarmDescription":null,"AWSAccountId":"111111111111","NewStateValue":"%s","NewStateReason":"Threshold Crossed","StateChangeTime":"2021-07-02T19:56:05.650+0000","Region":"US West (Oregon)","AlarmArn":"arn:aws:cloudwatch:us-west-2:111111111111:alarm:loader-test","OldStateValue":"INSUFFICIENT_DATA","Trigger":{"MetricName":"ThrottledEvents","Namespace":"AWS/Foo","StatisticType":"Statistic","Statistic":"AVERAGE","Unit":null,"Dimensions":[{"value":"Whiz","name":"Bang"}],"Period":300,"EvaluationPeriods":1,"ComparisonOperator":"LessThanOrEqualToThreshold","Threshold":1.0,"TreatMissingData":"- TreatMissingData: breaching","EvaluateLowSampleCountPercentile":""}}`, alarmState)

	sr.EventSource = "aws:sns"
	sr.EventVersion = "1.0"
	sr.SNS = se

	e.Records = append(e.Records, sr)

	return e
}

func Test_transformEvent(t *testing.T) {
	type args struct {
		ctx   context.Context
		event events.SNSEvent
	}
	tests := []struct {
		name    string
		args    args
		want    []types.AlarmEvent
		wantErr bool
	}{
		{
			name: "ok-null-description",
			args: args{
				ctx:   context.Background(),
				event: generateSNSMessage("OK"),
			},
			want: []types.AlarmEvent{
				{
					AlarmName:      "loader-test",
					AlarmSource:    "CLOUDWATCH",
					Region:         "US West (Oregon)",
					NewStateValue:  "OK",
					NewStateReason: "Threshold Crossed",
					AWSAccountId:   "111111111111",
				},
			},
			wantErr: false,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := transformEvent(tt.args.event)
			if (err != nil) != tt.wantErr {
				t.Errorf("transformEvent() error = %v, wantErr %v", err, tt.wantErr)
				return
			}
			if !reflect.DeepEqual(got, tt.want) {
				t.Errorf("transformEvent() = %v, want %v", got, tt.want)
			}
		})
	}
}
