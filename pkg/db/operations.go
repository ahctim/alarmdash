package db

import (
	"context"
	"fmt"

	"github.com/ahctim/alarmdash/pkg/types"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	ddbtypes "github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
)

type DDBClient interface {
	PutItem(ctx context.Context, params *dynamodb.PutItemInput, optFns ...func(*dynamodb.Options)) (*dynamodb.PutItemOutput, error)
	DeleteItem(ctx context.Context, params *dynamodb.DeleteItemInput, optFns ...func(*dynamodb.Options)) (*dynamodb.DeleteItemOutput, error)
}

type DynamoBucket struct {
	Client DDBClient
	Table  string
}

// Put writes a record to DynamoDB
func (b DynamoBucket) Put(ctx context.Context, a types.AlarmEvent) error {

	i := map[string]ddbtypes.AttributeValue{
		"alarm_source": &ddbtypes.AttributeValueMemberS{
			Value: a.AlarmSource,
		},
		"alarm_name": &ddbtypes.AttributeValueMemberS{
			Value: a.AlarmName,
		},
		"description": &ddbtypes.AttributeValueMemberS{
			Value: a.AlarmDescription,
		},
		"region": &ddbtypes.AttributeValueMemberS{
			Value: a.Region,
		},
		"alarm_state": &ddbtypes.AttributeValueMemberS{
			Value: a.NewStateValue,
		},
		"alarm_reason": &ddbtypes.AttributeValueMemberS{
			Value: a.NewStateReason,
		},
		"created": &ddbtypes.AttributeValueMemberS{
			Value: a.Created,
		},
	}

	input := dynamodb.PutItemInput{
		TableName: aws.String(b.Table),
		Item:      i,
	}

	_, err := b.Client.PutItem(ctx, &input)

	if err != nil {
		fmt.Println("Error putting DynamoDB item", err.Error())
	}

	return err

}

func (b DynamoBucket) Remove(ctx context.Context, source string, name string) error {

	key := map[string]ddbtypes.AttributeValue{
		"alarm_source": &ddbtypes.AttributeValueMemberS{
			Value: source,
		},
		"alarm_name": &ddbtypes.AttributeValueMemberS{
			Value: name,
		},
	}

	p := dynamodb.DeleteItemInput{
		Key:       key,
		TableName: aws.String(b.Table),
	}

	_, err := b.Client.DeleteItem(ctx, &p)

	if err != nil {
		fmt.Println("Error deleting item", err.Error())
	}

	return err
}
