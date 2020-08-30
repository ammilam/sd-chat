
variable "description" {
  type        = string
  description = "Shore description on the resources created and their usage"
  default     = "This is a Cloud Function that integrates Jira and Hangouts Chat"
}


#Cloud Function specific inputs
variable "project" {
  type        = string
  description = "Project where Cloud Function is to be deployed"
}

variable "location" {
  type        = string
  default     = "us-central1"
  description = "Location (region or zone) where cloud function will be created."
}

variable "runtime" {
  type        = string
  default     = "nodejs10"
  description = "Runtime environment for the cloud function"
}

variable "function_name" {
  type        = string
  description = "Name of the cloud function"
}



variable "source_dir" {
  type        = string
  description = "Name of the directory with Function Code"
  default     = "function"
}

variable "env_variables" {
  type        = map
  description = "Environment variables used by cloud function"
}

variable "entry_point" {
  description = "Entrypoint of the cloud function"
  type        = string
  #default     = "jiraGp2"
}

variable "memory_size_mb" {
  type        = string
  description = "Memory of the cloud function in MB"
  default     = 128
}

variable "timeout" {
  type        = string
  description = "Maximum amount of time your cloud function can run in seconds."
  default     = 60
}

variable "max_instances" {
  type        = string
  description = "Maximum number of concurrent function instances that can be run."
  default     = 5
}
