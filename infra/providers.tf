# Setting the Provider for AWS - using a variable for region to allow for flexibility in deployment

provider "aws" {
  region = var.aws_region
}