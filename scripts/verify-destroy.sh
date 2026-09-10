#!/usr/bin/env bash
set -u

# ----------------------------------------
# IT Tools AWS Teardown Verification
# ----------------------------------------

REGION="eu-west-2"
PROJECT="it-tools"
DOMAIN="it-tools.twrz.co.uk"
STATE_BUCKET="it-tools-terraform-state-bdee587c"

FAILURES=0

echo
echo "========================================"
echo "     IT TOOLS TEARDOWN VERIFICATION"
echo "========================================"
echo

check_gone() {
  local description="$1"
  local result="$2"

  if [[ -z "$result" || "$result" == "None" || "$result" == "null" ]]; then
    echo "PASS: $description"
  else
    echo "FAIL: $description"
    echo "      Found: $result"
    FAILURES=$((FAILURES + 1))
  fi
}

# ----------------------------------------
# ECS
# ----------------------------------------

echo "Checking ECS..."

ECS_CLUSTER=$(aws ecs describe-clusters \
  --clusters "${PROJECT}-cluster" \
  --region "$REGION" \
  --query 'clusters[?status==`ACTIVE`].clusterArn' \
  --output text 2>/dev/null || true)

check_gone "No active ECS cluster" "$ECS_CLUSTER"

# ----------------------------------------
# Application Load Balancer
# ----------------------------------------

echo "Checking load balancer..."

ALB=$(aws elbv2 describe-load-balancers \
  --names "${PROJECT}-alb" \
  --region "$REGION" \
  --query 'LoadBalancers[].LoadBalancerArn' \
  --output text 2>/dev/null || true)

check_gone "Application Load Balancer removed" "$ALB"

# ----------------------------------------
# VPC
# ----------------------------------------

echo "Checking project VPC..."

VPC=$(aws ec2 describe-vpcs \
  --region "$REGION" \
  --filters "Name=tag:Name,Values=${PROJECT}-vpc" \
  --query 'Vpcs[].VpcId' \
  --output text 2>/dev/null || true)

check_gone "Project VPC removed" "$VPC"

# ----------------------------------------
# VPC Endpoints
# ----------------------------------------

echo "Checking VPC endpoints..."

ENDPOINTS=$(aws ec2 describe-vpc-endpoints \
  --region "$REGION" \
  --filters "Name=tag:Project,Values=${PROJECT}" \
  --query 'VpcEndpoints[].VpcEndpointId' \
  --output text 2>/dev/null || true)

check_gone "Project VPC endpoints removed" "$ENDPOINTS"

# ----------------------------------------
# CloudWatch Logs
# ----------------------------------------

echo "Checking CloudWatch log group..."

LOG_GROUP=$(aws logs describe-log-groups \
  --region "$REGION" \
  --log-group-name-prefix "/ecs/${PROJECT}" \
  --query "logGroups[?logGroupName=='/ecs/${PROJECT}'].logGroupName" \
  --output text 2>/dev/null || true)

check_gone "CloudWatch log group removed" "$LOG_GROUP"

# ----------------------------------------
# ECR
# ----------------------------------------

echo "Checking ECR..."

ECR=$(aws ecr describe-repositories \
  --repository-names "$PROJECT" \
  --region "$REGION" \
  --query 'repositories[].repositoryArn' \
  --output text 2>/dev/null || true)

check_gone "ECR repository removed" "$ECR"

# ----------------------------------------
# IAM GitHub Actions role
# ----------------------------------------

echo "Checking GitHub Actions IAM role..."

IAM_ROLE=$(aws iam get-role \
  --role-name "${PROJECT}-github-actions-role" \
  --query 'Role.Arn' \
  --output text 2>/dev/null || true)

check_gone "GitHub Actions IAM role removed" "$IAM_ROLE"

# ----------------------------------------
# GitHub OIDC Provider
# ----------------------------------------

echo "Checking GitHub OIDC provider..."

OIDC=$(aws iam list-open-id-connect-providers \
  --query "OpenIDConnectProviderList[?contains(Arn, 'token.actions.githubusercontent.com')].Arn" \
  --output text 2>/dev/null || true)

check_gone "GitHub OIDC provider removed" "$OIDC"

# ----------------------------------------
# Terraform State Bucket
# ----------------------------------------

echo "Checking Terraform state bucket..."

if aws s3api head-bucket \
  --bucket "$STATE_BUCKET" \
  >/dev/null 2>&1; then

  check_gone "Terraform state bucket removed" "$STATE_BUCKET"
else
  check_gone "Terraform state bucket removed" ""
fi

# ----------------------------------------
# Route 53 application record
# ----------------------------------------

echo "Checking Route 53 application DNS record..."

HOSTED_ZONE=$(aws route53 list-hosted-zones-by-name \
  --dns-name "twrz.co.uk" \
  --query 'HostedZones[0].Id' \
  --output text 2>/dev/null || true)

if [[ -n "$HOSTED_ZONE" && "$HOSTED_ZONE" != "None" ]]; then

  DNS_RECORD=$(aws route53 list-resource-record-sets \
    --hosted-zone-id "$HOSTED_ZONE" \
    --query "ResourceRecordSets[?Name=='${DOMAIN}.'].Name" \
    --output text 2>/dev/null || true)

  check_gone "IT Tools Route 53 record removed" "$DNS_RECORD"

else
  echo "WARNING: Could not locate shared hosted zone."
fi

# ----------------------------------------
# ACM Certificate
# ----------------------------------------

echo "Checking ACM certificate..."

CERTIFICATE=$(aws acm list-certificates \
  --region "$REGION" \
  --query "CertificateSummaryList[?DomainName=='${DOMAIN}'].CertificateArn" \
  --output text 2>/dev/null || true)

check_gone "IT Tools ACM certificate removed" "$CERTIFICATE"


# ----------------------------------------
# Final project tag catch-all
# ----------------------------------------

echo "Checking for any remaining project-tagged AWS resources..."

TAGGED_RESOURCES=$(aws resourcegroupstaggingapi get-resources \
  --region "$REGION" \
  --tag-filters "Key=Project,Values=${PROJECT}" \
  --query 'ResourceTagMappingList[].ResourceARN' \
  --output text 2>/dev/null || true)

if [[ -z "$TAGGED_RESOURCES" || "$TAGGED_RESOURCES" == "None" ]]; then
  echo "PASS: No project-tagged AWS resources detected"
else
  echo "FAIL: Project-tagged AWS resources still exist"

  # Print each remaining ARN on its own line
  echo "$TAGGED_RESOURCES" | tr '\t' '\n' | while read -r RESOURCE; do
    [[ -n "$RESOURCE" ]] && echo "      $RESOURCE"
  done

  FAILURES=$((FAILURES + 1))
fi

# ----------------------------------------
# Final result
# ----------------------------------------

echo
echo "========================================"

if [[ "$FAILURES" -eq 0 ]]; then
  echo "TEARDOWN VERIFIED"
  echo "No live IT Tools project resources detected."
  echo "========================================"
  exit 0
else
  echo "TEARDOWN INCOMPLETE"
  echo "$FAILURES project resource check(s) failed."
  echo "========================================"
  echo
  echo "Review the resources above before performing"
  echo "any manual deletion."
  exit 1
fi