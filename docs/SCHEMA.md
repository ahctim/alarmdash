## Active Table

Partition key: alarm_source (S) -> The source of the alarm

Sort key: alarm_name (S) -> The alarm name. Alarm names must be unique

| alarm_source | description  |  alarm_reason | alarm_name   |  region | alarm_state |
|---|---|---|---|---|
| s | s |  s | int  | s | s |
