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

func transformEvent(event events.SNSEvent) ([]types.AlarmEvent, error) {
	var rv []types.AlarmEvent

	for _, e := range event.Records {
		var alarm types.AlarmEvent
		alarm.ID = e.SNS.MessageID
		alarm.Created = time.Now().String()

		m := e.SNS.Message

		err := json.Unmarshal([]byte(m), &alarm)

		if err != nil {
			fmt.Println("Error unmarshalling e.SNS.Message into types.AlarmEvent", err.Error())
			return rv, err
		}

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
			err = ddbBucket.Put(context.Background(), ev)

			if err != nil {
				return err
			}

			fmt.Println("Successfully added record for alarm", ev.ID)
		} else {
			err = ddbBucket.Remove(context.Background(), ev.AlarmName)

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
