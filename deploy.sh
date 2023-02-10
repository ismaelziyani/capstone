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
gcloud projects add-iam-policy-binding ${GCP_PROJECT_ID} --member="serviceAccount:${sa_capstone_email}" --role='roles/bigquery.dataEditor'
gcloud projects add-iam-policy-binding ${GCP_PROJECT_ID} --member="serviceAccount:${sa_capstone_email}" --role='roles/bigquery.user'
gcloud projects add-iam-policy-binding ${GCP_PROJECT_ID} --member="serviceAccount:${sa_capstone_email}" --role='roles/iam.serviceAccountUser'

#Create Pubsub topic
gcloud pubsub topics create capstone-topic

# Create push subscription


# Create notifications from Cloud Storage to PubSub
gcloud storage buckets notifications create gs://${GCP_BUCKET} --topic=${GCP_TOPIC}

gcloud builds submit 