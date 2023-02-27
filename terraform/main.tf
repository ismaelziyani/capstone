terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
        source  = "hashicorp/google"
        version = "~> 4.0"  
    }
  }
}

provider "google" {
    project     = var.project_name
    region = var.project_region
    zone = var.project_zone
}

#Service accounts
resource "google_service_account" "cloudrun_service_account" {
  account_id   = "sa-${var.app_name}"
  display_name = "Cloud Run Service Account"
}


resource "google_project_iam_member" "cloudbuild_sa" {
  for_each = toset([
        "roles/iam.serviceAccountUser",
        "roles/run.developer"
        ])
  role   = each.key
  member = "serviceAccount:${var.project_number}@cloudbuild.gserviceaccount.com"
  project = var.project_name
}

resource "google_project_iam_member" "cloudrun_service_account" {
    for_each = toset([
        "roles/iam.serviceAccountUser", 
        "roles/storage.objectViewer",
        "roles/bigquery.dataEditor", 
        "roles/bigquery.user"
        ])
  role    = each.key
  member = "serviceAccount:sa-${var.app_name}@${var.project_name}.iam.gserviceaccount.com"
  project = var.project_name
}

#Storage bucket
resource "google_storage_bucket" "bucket-batch" {
  project       = var.project_name
  name          = "${var.app_name}-bucket"
  location      = var.project_region_multi
  storage_class = "STANDARD"
  force_destroy = true

  versioning {
    enabled = false
  }
}

#Bigquery
resource "google_bigquery_dataset" "mydataset" {
  dataset_id                  = "${var.app_name}_dataset"
  description                 = "This is the dataset for batch and streaming person data"
  location                    = var.project_region_multi
  delete_contents_on_destroy = true
  #check if this is necessary
  #default_table_expiration_ms = 3600000

  #Check where this is appended...
  labels = {
    env = var.vm_instance_type
  }
}

resource "google_bigquery_table" "mytable" {
  dataset_id = google_bigquery_dataset.mydataset.dataset_id
  table_id   = "${var.app_name}_table"
  deletion_protection = false

  schema = <<EOF
[
  {
    "name": "id",
    "type": "INTEGER",
    "mode": "REQUIRED"
  },
  {
    "name": "first_name",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "last_name",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "gender",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "year",
    "type": "STRING",
    "mode": "REQUIRED"
  },
  {
    "name": "country",
    "type": "STRING",
    "mode": "REQUIRED"
  },
  {
    "name": "email",
    "type": "STRING",
    "mode": "REQUIRED"
  }
]
EOF

depends_on = [
  google_bigquery_dataset.mydataset
]
}

#Pubsub
resource "google_pubsub_topic" "batch-topic" {
  name = "${var.app_name}-batch-topic"
}
resource "google_pubsub_topic" "batch-deadletter-topic" {
  name = "${var.app_name}-batch-deadletter-topic"
}
resource "google_pubsub_topic" "stream-topic" {
  name = "${var.app_name}-stream-topic"
}
resource "google_pubsub_subscription" "batch-deadletter-subscription" {
  name  = "${var.app_name}-batch-deadletter-subscription"
  topic = google_pubsub_topic.batch-deadletter-topic.name
  ack_deadline_seconds = 20

  depends_on = [
    google_pubsub_topic.batch-deadletter-topic
  ]
}
resource "google_pubsub_subscription" "stream-subscription" {
  name  = "${var.app_name}-stream-subscription"
  topic = google_pubsub_topic.stream-topic.name
  ack_deadline_seconds = 20

  depends_on = [
    google_pubsub_topic.stream-topic
  ]
}

#Storage notification
resource "google_storage_notification" "storage_notification" {
  bucket         = google_storage_bucket.bucket-batch.name
  payload_format = "JSON_API_V1"
  topic          = google_pubsub_topic.batch-topic.name
  event_types    = ["OBJECT_FINALIZE", "OBJECT_METADATA_UPDATE"]

  depends_on = [
    google_storage_bucket.bucket-batch
  ]
}

# #Dataflow 
# resource "random_id" "rng" {
#   keepers = {
#     first = "${timestamp()}"
#   }     
#   byte_length = 8
# }
# resource "google_dataflow_job" "dataflow_job" {
#     project = var.project_name
#     region = var.project_region
#     name = "${var.app_name}-${random_id.rng.hex}"
#     template_gcs_path = "gs://dataflow-templates/latest/PubSub_Subscription_to_BigQuery"
#     temp_gcs_location = "gs://${var.project_name}-bucket"
#     skip_wait_on_job_termination = false
#     on_delete = "cancel"

#     parameters = {
#         inputSubscription = "projects/${var.project_name}/subscriptions/${var.project_name}-stream-subscription"
#         outputTableSpec = "${var.project_name}:${var.app_name}_dataset.${var.app_name}_table"
#     }
#     depends_on = [
#       google_storage_bucket.bucket-batch,
#       google_pubsub_subscription.stream-subscription,
#       google_bigquery_table.mytable,
#       random_id.rng
#     ]
# }


#Cloud Functions
resource "google_storage_bucket" "function-bucket" {
  name     = "${var.app_name}-function-bucket"
  location = var.project_region_multi
}

resource "google_storage_bucket_object" "cloudfunction" {
  name   = "function.zip"
  bucket = google_storage_bucket.function-bucket.name
  source = "/Users/ziyanii/dev/exercises/capstone/function.zip"
  
  depends_on = [
    google_storage_bucket.function-bucket
  ]
}
resource "google_cloudfunctions_function" "function" {
  name        = "${var.app_name}-function"
  description = "Function that returns random people when triggered"
  runtime     = "python37"
  region = var.project_region

  source_archive_bucket        = google_storage_bucket.function-bucket.name
  source_archive_object        = google_storage_bucket_object.cloudfunction.name
  source_repository {
    url = 
  }
  trigger_http                 = true
  timeout                      = 100
  entry_point                  = "random_person"
  ingress_settings = "ALLOW_ALL"

  depends_on = [
    google_storage_bucket_object.cloudfunction
  ]
}

#Cloud scheduler cron
resource "google_cloud_scheduler_job" "job" {
  name        = "${var.app_name}-stream-cron-job"
  description = "cron job that triggers cloud function"
  schedule    = "*/2 * * * *"
  region = var.project_region
  
  http_target {
    http_method = "GET"
    uri = "https://${var.project_region}-${var.project_name}.cloudfunctions.net/${var.app_name}"
  }

  depends_on = [
    google_cloudfunctions_function.function
  ]
}