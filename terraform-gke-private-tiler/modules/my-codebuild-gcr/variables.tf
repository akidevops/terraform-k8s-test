variable "repository" {
  type        = "string"
  description = "Name of mirror repository on GCP"
}

variable "triggers" {
  type        = "list"
  default     = []
  description = "Options of trigger"
}