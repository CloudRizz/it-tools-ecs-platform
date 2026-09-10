variable "aws_region" {
  description = "AWS region used for bootstrap resources"
  type        = string
  default     = "eu-west-2"
}

variable "terraform_state_bucket" {
  description = "Globally unique S3 bucket used to store Terraform state"
  type        = string
  default     = "it-tools-terraform-state-bdee587c"
}