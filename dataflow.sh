#!/bin/bash

#source .env

export GCP_APP_NAME="capstonev4"
export GCP_PROJECT_ID=$(gcloud config list --format 'value(core.project)')
export GCP_REGION=$(gcloud config list --format 'value(compute.region)')

# gcloud config set project ${GCP_PROJECT_ID}

# # Cloud Build default SA
# cloudbuild_sa="${GCP_PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"

# # Add necessary roles to default cloudbuild SA
# gcloud projects add-iam-policy-binding ${GCP_PROJECT_ID} --member="serviceAccount:${cloudbuild_sa}" --role='roles/iam.serviceAccountUser'
# gcloud projects add-iam-policy-binding ${GCP_PROJECT_ID} --member="serviceAccount:${cloudbuild_sa}" --role='roles/run.developer'


# # Service account for Cloud Run service
# sa_capstone_email="${SA_CAPSTONE}@${GCP_PROJECT_ID}.iam.gserviceaccount.com"
# sa_exists=`gcloud iam service-accounts describe ${sa_capstone_email} --format="value(email)" 2>/dev/null`

# if [ ! -z "${sa_exists}" ]; then
# echo "${sa_capstone_email} already exists in this GCP project."
# else
# gcloud iam service-accounts create ${SA_CAPSTONE} --description="The Cloud Run service account"
# fi

# # Add necessary roles
# gcloud projects add-iam-policy-binding ${GCP_PROJECT_ID} --member="serviceAccount:${sa_capstone_email}" --role='roles/iam.serviceAccountUser'
# gcloud projects add-iam-policy-binding ${GCP_PROJECT_ID} --member="serviceAccount:${sa_capstone_email}" --role='roles/storage.objectViewer'
# gcloud projects add-iam-policy-binding ${GCP_PROJECT_ID} --member="serviceAccount:${sa_capstone_email}" --role='roles/bigquery.dataEditor'
# gcloud projects add-iam-policy-binding ${GCP_PROJECT_ID} --member="serviceAccount:${sa_capstone_email}" --role='roles/bigquery.user'

# # Create bucket
# gcloud storage buckets create gs://${GCP_APP_NAME}-bucket --location=${GCP_REGION_MULTI} --project=${GCP_PROJECT_ID}


# # Create dataset
# dataset=${GCP_PROJECT_ID}:${GCP_APP_NAME}_dataset
# bq --location=${GCP_REGION_MULTI} mk --dataset $dataset

# # Create table with schema
# bq mk -t \
#   ${dataset}.${GCP_APP_NAME}_table \
#   id:INTEGER,first_name:STRING,last_name:STRING,email:STRING,gender:STRING,ip_address:STRING


# # Create Pubsub topics
# gcloud pubsub topics create ${GCP_APP_NAME}-batch-topic
# gcloud pubsub topics create ${GCP_APP_NAME}-stream-topic

# # Create Pubsub deadletter topics
# gcloud pubsub topics create ${GCP_APP_NAME}-batch-deadletter-topic

# # Create Pubsub subscriptions 
# gcloud pubsub subscriptions create --topic ${GCP_APP_NAME}-stream-topic ${GCP_APP_NAME}-stream-subscription
# gcloud pubsub subscriptions create --topic ${GCP_APP_NAME}-batch-deadletter-topic ${GCP_APP_NAME}-batch-deadletter-subscription

# # Create notifications from Cloud Storage to PubSub
# gcloud storage buckets notifications create gs://${GCP_APP_NAME}-bucket --topic=${GCP_APP_NAME}-batch-topic

# Create dataflow job
# gcloud dataflow jobs run ${GCP_APP_NAME}-$RANDOM \
#     --gcs-location gs://dataflow-templates/latest/PubSub_Subscription_to_BigQuery \
#     --region ${GCP_REGION} \
#     --staging-location gs://${GCP_APP_NAME}-bucket/temp \
#     --parameters \
# inputSubscription=projects/${GCP_PROJECT_ID}/subscriptions/${GCP_APP_NAME}-stream-subscription,\
# outputTableSpec=${dataset}.${GCP_APP_NAME}_table

gcloud dataflow flex-template run ${GCP_APP_NAME}-$RANDOM \
    --template-file-gcs-location=gs://dataflow-templates/latest/PubSub_Subscription_to_BigQuery \
    --region=${GCP_REGION} --staging-location gs://${GCP_APP_NAME}-bucket \
    --parameters \
        inputSubscription=projects/${GCP_PROJECT_ID}/subscriptions/${GCP_APP_NAME}-stream-subscription,outputTableSpec=${GCP_PROJECT_ID}:${GCP_APP_NAME}_dataset.${GCP_APP_NAME}_table


# gcloud dataflow flex-template run "streaming-beam-sql-`date +%Y%m%d-%H%M%S`" \
#     --template-file-gcs-location "gs://BUCKET_NAME/samples/dataflow/templates/streaming-beam-sql.json" \
#     --parameters inputSubscription="SUBSCRIPTION_ID" \
#     --parameters outputTable="PROJECT_ID:DATASET_ID.TABLE_ID" \
#     --region "REGION"




# # zip and move Cloud Function
# zip -r -j ${GCP_APP_NAME}-function.zip tester/main.py tester/requirements.txt
# gsutil mv ${GCP_APP_NAME}-function.zip gs://${GCP_PROJECT_ID}-function-zip
# Create Cloud Function
# gcloud functions deploy ${GCP_APP_NAME} \
# --runtime=python37 \
# --region=${GCP_REGION} \
# --source=functions/ \
# --entry-point=random_person \
# --trigger-http \
# --allow-unauthenticated


# # Run the build yaml file
# gcloud builds submit 