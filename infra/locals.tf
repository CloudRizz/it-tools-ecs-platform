locals {
  project_name = "it-tools"

  common_tags = {
    Project   = local.project_name
    ManagedBy = "Terraform"
  }
}