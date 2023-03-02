project_name = var.gcp_name
project_number = 5002341089
project_region_multi = "EU"
project_region = var.gcp_region
project_zone = "europe-west1-b"
app_name = var.gcp_app_name

apis_to_enable    = [
"bigquery.googleapis.com",
"bigquerymigration.googleapis.com",
"bigquerystorage.googleapis.com",
"cloudbuild.googleapis.com",
"cloudfunctions.googleapis.com",
"run.googleapis.com"
]

vm_instance_type = "f1-micro"
vm_instance_image = "debian-cloud/debian-11"

