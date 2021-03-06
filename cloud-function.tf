data "archive_file" "zip" {
  type        = "zip"
  source_dir = "${path.module}/${var.source_dir}/"
  output_path = "${path.module}/files/index.zip"
}

resource "google_storage_bucket" "cf_bucket" {
  name = "${var.function_name}_bu"
  project = var.project
  bucket_policy_only = "true"
}

resource "google_storage_bucket_object" "archive" {
  name   = "${var.function_name}/index.zip"
  bucket = google_storage_bucket.cf_bucket.name
  source = data.archive_file.zip.output_path
}

resource "google_cloudfunctions_function" "cloud_function" {
  name                  = var.function_name
  description           = var.description
  runtime               = var.runtime
  project               = var.project
  available_memory_mb   = var.memory_size_mb
  source_archive_bucket = google_storage_bucket.cf_bucket.name
  source_archive_object = google_storage_bucket_object.archive.name
  trigger_http          = true
  timeout               = var.timeout
  entry_point           = var.entry_point
  region                = var.location
  environment_variables = var.env_variables
  max_instances         = var.max_instances
}

resource "google_cloudfunctions_function_iam_member" "invoker" {
  project        = google_cloudfunctions_function.cloud_function.project
  region         = google_cloudfunctions_function.cloud_function.region
  cloud_function = google_cloudfunctions_function.cloud_function.name

  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}

resource "google_logging_metric" "logging_metric" {
  name    = "flux"
  project = var.project
  filter  = "labels.k8s-pod/app=\"flux\" textPayload=~\"Error.*\""
  metric_descriptor {
    metric_kind  = "DELTA"
    value_type   = "INT64"
    display_name = "flux-errors"
  }
}

resource "google_monitoring_notification_channel" "basic" {
  project = var.project
  display_name = "Test Notification Channel"
  type         = "webhook_tokenauth"
  labels = {
    url = google_cloudfunctions_function.cloud_function.https_trigger_url
  }
}

locals {
    error_log_filter = "resource.type=\"k8s_container\" AND metric.type=\"logging.googleapis.com/user/${google_logging_metric.logging_metric.id}\""
}

  resource "google_monitoring_alert_policy" "alert_policy" {
  display_name = "My Alert Policy"
  notification_channels = [google_monitoring_notification_channel.basic.id]
  combiner     = "OR"
  conditions {
    display_name = "test condition"
    condition_threshold {
      filter     = local.error_log_filter
      duration   = "60s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }
}
