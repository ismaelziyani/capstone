#!/bin/bash

export TF_VAR_gcp_app_name="capstonev4"
export TF_VAR_gcp_project_id=$(gcloud config list --format 'value(core.project)')
export TF_VAR_gcp_region=$(gcloud config list --format 'value(compute.region)')

#zip -r -j ${TF_VAR_gcp_app_name}-function.zip tester/main.py tester/requirements.txt
#gsutil mv ${TF_VAR_gcp_app_name}-function.zip gs://${TF_VAR_gcp_project_id}-function-zip

# terraform init
# terraform plan
# terraform apply -auto-approve

terraform destroy -auto-approve