import base64
import json
import os
import boto3

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["NOTIFICATION_TABLE_NAME"])


def handler(event, context):
    for records in event.get("records", {}).values():
        for record in records:
            payload = json.loads(base64.b64decode(record["value"]))
            event_id = payload.get("event_id")

            if not event_id:
                continue

            # Idempotency check (outbox pattern): skip if already processed.
            existing = table.get_item(Key={"id": event_id}).get("Item")
            if existing:
                continue

            # TODO: send the actual notification (e.g. via SES).
            table.put_item(Item={"id": event_id, "payload": payload, "status": "SENT"})

    return {"statusCode": 200}
