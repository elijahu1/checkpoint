import json
import boto3
from flask import Flask, jsonify, request
import os

app = Flask(__name__)

SECRET_NAME = os.getenv("SECRET_NAME", "my-app-config")
REGION = os.getenv("AWS_REGION", "us-east-1")

_secret_cache = None


def get_secret():
    client = boto3.client("secretsmanager", region_name=REGION)
    response = client.get_secret_value(SecretId=SECRET_NAME)

    # secret is a plain string, return it as-is.
    # Example: "my-sagemaker-endpoint-name"
    return response["SecretString"]


def get_config():
    return get_secret()

@app.route("/invoke", methods=["POST"])
def invoke():
    endpoint_name = get_config()
    payload = request.get_json(silent=True) or {}
    
    runtime = boto3.client("sagemaker-runtime", region_name=REGION)
    response = runtime.invoke_endpoint(
        EndpointName=endpoint_name,
        ContentType="application/json",
        Accept="application/json",
        Body=json.dumps({"inputs": payload["text"]}).encode("utf-8"),
    )
    result = json.loads(response["Body"].read().decode("utf-8"))
    translation = result[0].get("translation_text", "No translation found")
    return jsonify({"translation": translation})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
