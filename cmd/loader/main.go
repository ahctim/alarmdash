package main

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"time"

	"github.com/ahctim/alarmdash/pkg/db"
	"github.com/ahctim/alarmdash/pkg/helper"
	"github.com/ahctim/alarmdash/pkg/types"
	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

func determineSource(a types.AlarmEvent) string {
	// This logic handles cases where a non-Cloudwatch-generated message invokes this function
	if a.AlarmSource != "" {
		fmt.Println("AlarmSource was provided in SNS message. Setting AlarmSource to", a.AlarmSource)
		return a.AlarmSource
	}

	// Cloudwatch will include the account ID in the message
	if awsAccountID := a.AWSAccountId; awsAccountID != "" {
		fmt.Println("Found AWS account ID. Assuming this alarm is from Cloudwatch")
		return "CLOUDWATCH"
	}

	return "UNKNOWN"
}

func transformEvent(event events.SNSEvent) ([]types.AlarmEvent, error) {
	var rv []types.AlarmEvent

	for _, e := range event.Records {
		var alarm types.AlarmEvent
		alarm.ID = e.SNS.MessageID

		m := e.SNS.Message

		err := json.Unmarshal([]byte(m), &alarm)

		if err != nil {
			fmt.Println("Error unmarshalling e.SNS.Message into types.AlarmEvent", err.Error())
			return rv, err
		}

		alarm.AlarmSource = determineSource(alarm)

		rv = append(rv, alarm)
	}

	return rv, nil
}

func handler(ctx context.Context, e events.SNSEvent) error {
	var eventArray []types.AlarmEvent
	var err error

	if eventArray, err = transformEvent(e); err != nil {
		return err
	}

	// Create DynamoDB client
	ac := helper.NewAWSConfig()

	ddbBucket := db.DynamoBucket{
		Client: helper.NewDDBClient(ac),
		Table:  os.Getenv("LOADER_ALARMS_TABLE"),
	}

	for _, ev := range eventArray {
		if ev.NewStateValue == "ALARM" {
			ev.Created = time.Now().String()
			err = ddbBucket.Put(context.Background(), ev)

			if err != nil {
				return err
			}

			fmt.Println("Successfully added record for alarm", ev.ID)
		} else {
			err = ddbBucket.Remove(context.Background(), ev.AlarmSource, ev.AlarmName)

			if err != nil {
				return err
			}
			fmt.Println("Removed alarm because it is in OK state")
		}

	}

	return nil
}

func main() {
	lambda.Start(handler)
}
