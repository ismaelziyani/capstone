import logging
import yaml
import os

from google.cloud import bigquery
import google.cloud.logging
from flask import Flask, request

app = Flask(__name__)


#Credentials for local testing
#os.environ["GOOGLE_APPLICATION_CREDENTIALS"]="cloud-consulting-sandbox-9a6ddcd19a01.json"

# Construct a BigQuery client object.
client = bigquery.Client()

#Google Cloud Logging client
logging_client = google.cloud.logging.Client()

# Retrieves a Cloud Logging handler based on the environment
# you're running in and integrates the handler with the
# Python logging module. By default this captures all logs
# at INFO level and higher
logging_client.setup_logging()

# Load config file
def load_config(file):
    """
    loads the yaml config file and retunrs it
    :param: file: path for the yaml config file
    """
    with open(file, "r") as stream:
        try:
            return yaml.safe_load(stream)
        except yaml.YAMLError as exc:
            print("Unable to load yaml config...")

config = load_config("./config.yaml")

# Config variables
project_id = config['project_id']
dataset = config['dataset']
table = config['table']
bucket = config['bucket']
table_id = f"{project_id}.{dataset}.{table}"


@app.route("/trigger", methods=["POST"])  # type: ignore
def csv_loader():
    logging.warning("Trigger router is triggered!")
    payload = request.get_json()
    #print(payload)
    
    if not payload:
        msg = "no Pub/Sub message received"
        logging.error(f"Bad Request. error: {msg}")
        return (f"Bad Request: {msg}", 400)

    if not isinstance(payload, dict) or "message" not in payload:
        msg = "invalid Pub/Sub message format"
        logging.error(f"Bad Request. error: {msg}")
        return (f"Bad Request2: {msg}", 400)
    
    pubsub_message: dict = payload["message"]

    object_id = pubsub_message['attributes']['objectId']
    
    if not object_id.endswith('.csv'):
        msg = "Wrong file format!"
        logging.error(f"Bad Request. error: {msg}")
        return (f"Bad Request: {msg}", 405)
    

    if pubsub_message['attributes']['eventType'] == 'OBJECT_FINALIZE':
        
        logging.info(f"Object detected in {bucket} : {object_id}")    
        
        job_config = bigquery.LoadJobConfig(
            schema=[
                bigquery.SchemaField('id', 'INTEGER'),
                bigquery.SchemaField('first_name', 'STRING'),
                bigquery.SchemaField('last_name', 'STRING'),
                bigquery.SchemaField('email', 'STRING'),
                bigquery.SchemaField('gender', 'STRING'),
                bigquery.SchemaField('ip_address', 'STRING')
            ],
            skip_leading_rows=1,
            # The source format defaults to CSV, so the line below is optional.
            source_format=bigquery.SourceFormat.CSV,
        )

        #uri = "gs://my-capstone-bucket/mock-data.csv"
        uri = "gs://" + bucket + "/" + object_id    

        load_job = client.load_table_from_uri(
            uri, table_id, job_config=job_config
        )  # Make an API request.

        # Waits for the job to complete.
        load_job.result()

        # Make an API request. destination_table = client.get_table(table_id)  
        logging.info(f"Michael Jackson has loaded {object_id} into BigQuery")
        return (f"Michael Jackson has loaded {object_id} into BigQuery.", 200)
 
    return ("", 204)
    
if __name__ == '__main__':
      app.run(debug=True, host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))