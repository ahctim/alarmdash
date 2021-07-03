package types

// TODO I wasn't able to find anything in the
// v2 Go SDK to unmarshal into so I've created this struct
// Ideally we'd use something provided by the SDK
type AlarmEvent struct {
	AlarmName        string `json:"AlarmName"`
	AlarmDescription string `json:"AlarmDescription"` // This may be null
	Region           string `json:"Region"`
	NewStateValue    string `json:"NewStateValue"`
	NewStateReason   string `json:"NewStateReason"`
	ID               string
	Created          string
}
