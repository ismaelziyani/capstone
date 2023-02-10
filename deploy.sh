#!/bin/bash

source .env

gcloud config set project ${GCP_PROJECT_ID}

# Cloud Build default SA
cloudbuild_sa="${GCP_PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"

# Add necessary roles to default cloudbuild SA
gcloud projects add-iam-policy-binding ${GCP_PROJECT_ID} --member="serviceAccount:${cloudbuild_sa}" --role='roles/iam.serviceAccountUser'
gcloud projects add-iam-policy-binding ${GCP_PROJECT_ID} --member="serviceAccount:${cloudbuild_sa}" --role='roles/run.developer'


# Service account for Cloud Run service
sa_capstone_email="${SA_CAPSTONE}@${GCP_PROJECT_ID}.iam.gserviceaccount.com"
sa_exists=`gcloud iam service-accounts describe ${sa_capstone_email} --format="value(email)" 2>/dev/null`

if [ ! -z "${sa_exists}" ]; then
echo "${sa_capstone_email} already exists in this GCP project."
else
gcloud iam service-accounts create ${SA_CAPSTONE} --description="The Cloud Run service account"
fi

# Add necessary roles
gcloud projects add-iam-policy-binding ${GCP_PROJECT_ID} --member="serviceAccount:${sa_capstone_email}" --role='roles/iam.serviceAccountUser'
gcloud projects add-iam-policy-binding ${GCP_PROJECT_ID} --member="serviceAccount:${sa_capstone_email}" --role='roles/storage.objectViewer'
gcloud projects add-iam-policy-binding ${GCP_PROJECT_ID} --member="serviceAccount:${sa_capstone_email}" --role='roles/bigquery.dataEditor'
gcloud projects add-iam-policy-binding ${GCP_PROJECT_ID} --member="serviceAccount:${sa_capstone_email}" --role='roles/bigquery.user'

# Create bucket
gcloud storage buckets create gs://${GCP_APP_NAME}-bucket --location=EU --project=${GCP_PROJECT_ID}


# Create dataset
dataset=${GCP_PROJECT_ID}:${GCP_APP_NAME}_dataset
bq --location=${GCP_REGION} mk --dataset $dataset

# Create table with schema
bq mk -t \
  ${dataset}.${GCP_APP_NAME}_table \
  id:INTEGER,first_name:STRING,last_name:STRING,email:STRING,gender:STRING,ip_adress:STRING


#Create Pubsub topic
gcloud pubsub topics create ${GCP_APP_NAME}-topic

#Create Pubsub deadletter topic
gcloud pubsub topics create ${GCP_APP_NAME}-deadletter-topic
#Deadletter subscription
 


# Create notifications from Cloud Storage to PubSub
gcloud storage buckets notifications create gs://${GCP_APP_NAME}-bucket --topic=${GCP_APP_NAME}-topic

gcloud builds submit 