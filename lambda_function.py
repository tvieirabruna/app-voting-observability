import os
import requests
import json
import boto3
from requests.auth import HTTPBasicAuth
from botocore.exceptions import ClientError

# Lambda handler function
def lambda_handler(event, context):
    # Environment variables for Grafana URL, S3 bucket, and credentials
    grafana_url = os.getenv("GRAFANA_URL")
    grafana_user = os.getenv("GRAFANA_USER")
    grafana_password = os.getenv("GRAFANA_PASSWORD")
    s3_bucket = os.getenv("S3_BUCKET")

    # Basic authentication for Grafana
    auth = HTTPBasicAuth(grafana_user, grafana_password)

    # Create a Grafana snapshot
    snapshot_data = {
        "public": True,
        "expires": 3600,  # Expiry time in seconds (optional)
    }

    # POST request to create a snapshot in Grafana
    response = requests.post(
        f"{grafana_url}/api/snapshots",
        auth=auth,
        json=snapshot_data
    )

    if response.status_code != 200:
        return {
            "statusCode": response.status_code,
            "body": json.dumps({
                "message": "Failed to create snapshot",
                "error": response.text
            })
        }

    # Get the snapshot link
    snapshot_info = response.json()
    snapshot_link = snapshot_info.get("url")

    # Store the snapshot link in S3
    s3 = boto3.client("s3")

    try:
        s3.put_object(
            Bucket=s3_bucket,
            Key="grafana_snapshot_link.json",
            Body=json.dumps({"snapshot_link": snapshot_link}),
            ContentType="application/json",
        )

        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Snapshot link stored successfully",
                "snapshot_link": snapshot_link
            })
        }

    except ClientError as e:
        return {
            "statusCode": 500,
            "body": json.dumps({
                "message": "Failed to store snapshot link in S3",
                "error": str(e),
            })
        }
