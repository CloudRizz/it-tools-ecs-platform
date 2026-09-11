# IT Tools — AWS ECS Fargate Platform

A containerised web application deployed to **AWS ECS Fargate** using **Docker, modular Terraform and GitHub Actions**.

```text
Source → Docker → ECR → ECS Fargate → ALB → HTTPS
```

The application runs in **private ECS tasks** across a two-AZ network behind an internet-facing Application Load Balancer. Infrastructure is managed with Terraform, while GitHub Actions authenticates to AWS using **GitHub OIDC**, removing the need to store long-lived AWS credentials in GitHub.

> **Status:** Successfully deployed, tested, security-hardened and destroyed through GitHub Actions.

---

## Project at a Glance

![IT Tools ECS Fargate Project Cheat Sheet](docs/images/project_at_a_glance.png)

> **Quick reference:** Build → Bootstrap → Deploy → Architecture → Terraform → Verify → Troubleshoot → Destroy

---

## Application Demo

**Application:** `https://it-tools.twrz.co.uk`  
**Health:** `https://it-tools.twrz.co.uk/health`

Expected health response:

```json
{"status":"ok"}
```

![IT Tools Demo](docs/images/manual-https-app.png)

> The application is only available while the portfolio environment is deployed.

---

## Project Overview

### What is IT Tools?

[IT Tools](https://github.com/CorentinTh/it-tools) is an open-source collection of browser-based utilities for developers and IT professionals, including encoders, converters, generators, formatters and networking tools.

I did **not** develop the application itself. My work focuses on engineering the platform around it:

- Docker containerisation
- AWS infrastructure
- networking and security
- Terraform infrastructure as code
- CI/CD automation
- logging and monitoring
- security scanning and infrastructure hardening
- deployment and teardown

### Why did I choose it?

I wanted to deploy a real application rather than a hello-world container while keeping the project focused on Cloud and DevOps engineering.

IT Tools is lightweight, can be served using Nginx and does not require a database. This allowed the project to focus on **AWS, Docker, Terraform, networking, security and CI/CD**.

### Why ECS Fargate?

I deliberately chose ECS Fargate rather than EC2, Vercel or Netlify.

**EC2** would require additional host management, including operating-system patching, Docker installation and instance maintenance.

**Vercel/Netlify** would be simpler for this application but would remove much of the container infrastructure I wanted to demonstrate.

**ECS Fargate** allows me to work with containers, VPC networking, IAM, load balancing and scaling without managing the underlying EC2 hosts.

**Trade-off:** Fargate can cost more than well-utilised EC2 infrastructure at larger scale.

### Expected Usage

This is a portfolio deployment rather than an application with an established production user base.

The platform spans **two Availability Zones**, but one task means there is currently no task-level redundancy. For the portfolio I set the desired count to 1 to keep costs low.

```hcl
desired_count = 1
```

For a production workload, I would run multiple tasks and add **ECS Service Auto Scaling**, allowing ECS to distribute workloads across the configured Availability Zones where possible and provide task-level redundancy.

---

## Architecture

![IT Tools AWS ECS Fargate Architecture](<docs/images/architecture - IT - tools.png>)

### Request Flow

```text
Internet
   │
   ▼
Route 53
   │
   ▼
Application Load Balancer
HTTPS :443
   │
   ▼
ECS Fargate Service
Private Subnets
   │
   ▼
Nginx :8080
   │
   ▼
IT Tools
```

| Component | Implementation |
|---|---|
| Region | `eu-west-2` |
| Availability | 2 AZs |
| Network | Custom VPC |
| Public Layer | Application Load Balancer |
| Compute | ECS Fargate |
| Container Registry | Amazon ECR |
| DNS | Route 53 |
| HTTPS | ACM |
| Application Logging | CloudWatch Logs |
| Monitoring | ECS Container Insights |
| Network Logging | VPC Flow Logs |
| Load Balancer Logging | ALB Access Logs → S3 |
| Private AWS Access | VPC Endpoints |
| Infrastructure | Terraform |
| Terraform State | S3 + native locking |
| CI/CD | GitHub Actions |
| Container Security | Trivy |
| IaC Security | Checkov |
| AWS Authentication | GitHub OIDC |

### Network Design

The custom VPC spans:

```text
eu-west-2a
eu-west-2b
```

with a **public and private subnet in each Availability Zone**.

The Application Load Balancer runs in the public subnets, while ECS tasks run in the private subnets with:

```hcl
assign_public_ip = false
```

This keeps application containers private. Only the Application Load Balancer accepts public application traffic.

The project deliberately does **not** use a NAT Gateway. Private ECS tasks access the AWS services required at runtime through VPC endpoints:

| Service | Endpoint |
|---|---|
| ECR API | Interface |
| ECR DKR | Interface |
| CloudWatch Logs | Interface |
| S3 | Gateway |

This design keeps ECS tasks private and avoids NAT Gateway cost, although interface endpoints introduce their own cost and configuration overhead.

### Security

Traffic is restricted using security-group references:

```text
Internet → ALB :443
ALB SG   → ECS :8080
ECS SG   → VPC Endpoints :443
```

HTTP traffic on port `80` is redirected to HTTPS on port `443`.

The ECS tasks have **no public IP addresses**, and application traffic reaches them only through the ALB security group.

The existing `twrz.co.uk` Route 53 hosted zone is looked up rather than created by this project. Terraform manages the `it-tools.twrz.co.uk` application record and creates and validates the ACM certificate required for HTTPS.

---

## Repository Structure

```text
it-tools-ecs-platform/
│
├── app/
│   ├── Dockerfile
│   ├── nginx.conf
│   └── application source
│
├── bootstrap/
│   └── foundational AWS resources
│
├── infra/
│   ├── backend.tf
│   ├── providers.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── modules/
│       ├── acm/
│       ├── alb/
│       ├── cloudwatch/
│       ├── ecs/
│       ├── iam/
│       ├── route53/
│       ├── security_groups/
│       ├── vpc/
│       └── vpc_endpoints/
│
├── .github/workflows/
│   ├── app-pipeline.yml
│   ├── terraform-deploy.yml
│   └── terraform-destroy.yml
│
├── scripts/
│   ├── destroy.sh
│   └── verify-destroy.sh
│
└── docs/images/
```

---

## Local Setup

### Application

```bash
git clone https://github.com/CloudRizz/it-tools-ecs-platform.git
cd it-tools-ecs-platform/app

nvm use
corepack enable
corepack prepare pnpm@9.11.0 --activate

pnpm install --frozen-lockfile
pnpm dev
```

Verify:

```bash
curl -I http://localhost:5173
```

### Docker

From the repository root:

```bash
docker build -t it-tools-local ./app

docker run --rm \
  -p 8080:8080 \
  it-tools-local
```

Verify:

```bash
curl -i http://localhost:8080/health
```

Expected:

```json
{"status":"ok"}
```

![Docker Health Check](docs/images/docker-health-nonroot.png)

---

## Terraform

Infrastructure is split into **nine Terraform modules**:

```text
acm
alb
cloudwatch
ecs
iam
route53
security_groups
vpc
vpc_endpoints
```

This separates networking, compute, security, DNS and supporting services rather than maintaining the entire platform in one large Terraform configuration.

### Remote State

Terraform uses an encrypted S3 backend with **native S3 state locking**:

```hcl
terraform {
  backend "s3" {
    key          = "infra/terraform.tfstate"
    region       = "eu-west-2"
    encrypt      = true
    use_lockfile = true
  }
}
```

The state bucket is supplied during initialisation:

```bash
terraform init \
  -backend-config="bucket=$TF_STATE_BUCKET"
```

---

## Bootstrap

Before the main infrastructure can be deployed, `bootstrap/` creates the foundational resources required by Terraform and GitHub Actions:

```text
S3 Terraform State Bucket
ECR Repository
GitHub OIDC Provider
GitHub Actions IAM Role
```

Run:

```bash
cd bootstrap

terraform init
terraform validate
terraform plan
terraform apply
terraform output
```

The resulting values are configured as GitHub repository variables:

```text
AWS_REGION
AWS_ROLE_ARN
ECR_REPOSITORY_URL
TF_STATE_BUCKET
```

GitHub then authenticates to AWS using:

```text
GitHub Actions
      ↓
GitHub OIDC
      ↓
AWS IAM Role
      ↓
Temporary Credentials
```

No long-lived AWS access keys are required.

---

## CI/CD

Three GitHub Actions workflows manage the platform:

```text
Application Pipeline
        │
        ▼
Docker Build
        │
        ▼
ECR:<Git SHA>
        │
        ▼
Terraform Deploy
        │
        ▼
ECS Fargate
```

### 1. Application Pipeline

Triggered by application changes on `main`.

```text
Checkout
   ↓
AWS OIDC
   ↓
ECR Login
   ↓
Docker Build
   ↓
Docker Push
```

Images are tagged using the **Git commit SHA** rather than `latest`, providing a traceable link between the source commit, container image and deployed ECS task.

A later security-hardening pass introduced a **Trivy security gate** between the Docker build and ECR push. This is documented in the Security & Observability Hardening section below.

### 2. Terraform Deploy

A successful Application Pipeline automatically triggers Terraform Deploy.

```text
workflow_run.head_sha
        ↓
IMAGE_TAG
        ↓
terraform plan
        ↓
terraform apply
```

The same Git SHA produced by the Application Pipeline is therefore passed to Terraform and deployed to ECS.

The original workflow runs:

```text
terraform fmt
terraform init
terraform validate
terraform plan
terraform apply
```

A later hardening pass introduced **Checkov** between Terraform validation and planning.

### 3. Terraform Destroy

Terraform Destroy is manually triggered and requires:

```text
DESTROY
```

as confirmation.

It removes the main application infrastructure while leaving bootstrap resources available so GitHub can continue to authenticate and access Terraform state.

---

## Pipeline Evidence

All three core pipelines completed successfully.

### Application Pipeline

![Application Pipeline](<docs/images/application pipeline deployed.png>)

### Automatic Application → Terraform Deployment

![Automatic Deployment](<docs/images/application pipeline auto into terraform deploy.png>)

### All Pipelines

![All Pipelines Completed](<docs/images/all 3 pipelines completed.png>)

```text
Application Pipeline    ✅
Terraform Deploy        ✅
Terraform Destroy       ✅
```

---

## Deployment Verification

### ECS

```bash
aws ecs describe-services \
  --cluster it-tools-cluster \
  --services it-tools-service \
  --region eu-west-2 \
  --query 'services[0].[desiredCount,runningCount,pendingCount]'
```

Expected:

```text
[1, 1, 0]
```

### HTTPS

```bash
curl -I https://it-tools.twrz.co.uk
```

Expected:

```text
HTTP/2 200
```

### Health

```bash
curl -i https://it-tools.twrz.co.uk/health
```

Expected:

```text
HTTP/2 200
{"status":"ok"}
```

![HTTPS Health Verification](docs/images/terraform-https-health.png)

---

## Destroy

The GitHub **Terraform Destroy** workflow removes the main `infra/` stack.

The scripts below provide a complete teardown to avoid unnecessary AWS charges. They do not need to be used if the application will be redeployed after running Terraform Destroy.

Run for a complete teardown including bootstrap resources:

```bash
./scripts/destroy.sh
```

Verify that project resources have been removed:

```bash
./scripts/verify-destroy.sh
```

Expected:

```text
TEARDOWN VERIFIED
No live IT Tools project resources detected.
```

Pre-existing shared resources, such as the existing Route 53 hosted zone, are not owned by the project and are preserved.

---

## Key Engineering Decisions

| Decision | Why |
|---|---|
| ECS Fargate | Run containers without managing EC2 hosts |
| Private ECS tasks | Prevent application containers from being directly exposed to the internet |
| Application Load Balancer | Controlled HTTPS entry point and application health checking |
| Two AZ network | Provides the foundation for multi-AZ availability and load balancing |
| No NAT Gateway | No requirement for general outbound internet access from ECS |
| VPC Endpoints | Private access to ECR, S3 and CloudWatch |
| Git SHA image tags | Traceable and immutable application deployments |
| GitHub OIDC | Temporary AWS credentials instead of stored access keys |
| Modular Terraform | Clear separation of infrastructure responsibilities |
| S3 remote state | Remote CI/CD state with native locking |
| Read-only container filesystem | Reduces the writable surface of the running container |
| Trivy | Automated container vulnerability scanning in CI/CD |
| Checkov | Automated Terraform security scanning before deployment |
| VPC Flow Logs | Visibility into network traffic |
| ALB Access Logs | Request-level load balancer logging |
| ECS Container Insights | Additional ECS monitoring and operational visibility |

---

## Security & Observability Hardening

After completing the original ECS platform, I carried out a second engineering pass focused on **CI/CD security, container hardening and observability**.

### CI/CD Security

Two automated security gates were added to the existing GitHub Actions workflows.

#### Application Pipeline

```text
Docker Build
     ↓
Trivy Scan
     ↓
ECR Push
```

**Trivy** scans the container image for HIGH and CRITICAL vulnerabilities before the image is pushed to ECR.

The pipeline is configured to fail when applicable HIGH or CRITICAL vulnerabilities are detected.

#### Terraform Deploy

```text
terraform validate
        ↓
     Checkov
        ↓
terraform plan
        ↓
terraform apply
```

**Checkov** scans the Terraform configuration before infrastructure is planned or deployed, with failed security checks blocking the pipeline.

Final local validation:

```text
Passed checks: 127
Failed checks: 0
Skipped checks: 14
```

The skipped checks are documented within the Terraform configuration and represent intentional portfolio-environment decisions or verified cross-module findings.

### Container Hardening

The ECS task was updated to use a **read-only root filesystem**.

During local testing, Nginx failed because it required writable temporary storage under `/tmp`. Rather than making the entire filesystem writable again, only `/tmp` was provided as writable storage.

```text
Container Root Filesystem
        │
        ├── /             Read-only
        │
        └── /tmp          Writable
```

This allowed Nginx to operate while retaining the read-only root filesystem.

### Infrastructure Hardening

The security review resulted in several additional improvements:

- read-only ECS container root filesystem
- writable `/tmp` only where required by Nginx
- ALB invalid HTTP header dropping
- restricted default VPC security group
- security group rule descriptions
- ECS Container Insights
- VPC Flow Logs to CloudWatch
- ALB access logging to S3
- S3 public access blocking for the ALB log bucket
- SSE-S3 encryption for ALB logs
- 30-day lifecycle policy for ALB access logs

### Result

The updated platform was successfully deployed through the hardened pipelines and the application was verified over HTTPS.

The environment was then torn down and checked using:

```bash
./scripts/verify-destroy.sh
```

Expected successful verification:

```text
TEARDOWN VERIFIED
No live IT Tools project resources detected.
```

---

## Future Improvements

For a production workload I would add:

- multiple ECS tasks for task-level redundancy
- ECS Service Auto Scaling
- CloudWatch alarms and alerting
- AWS WAF
- deployment rollback controls
- tighter action/resource-level IAM permissions
- customer-managed KMS keys where required

---

## Final Result

```text
SOURCE
  ↓
DOCKER
  ↓
TRIVY
  ↓
ECR
  ↓
TERRAFORM
  ↓
CHECKOV
  ↓
AWS
  ↓
ROUTE 53 + ACM
  ↓
HTTPS ALB
  ↓
PRIVATE ECS FARGATE
  ↓
CLOUDWATCH / FLOW LOGS / ALB LOGS
```

The project demonstrates a complete container delivery platform using **Docker, AWS, Terraform and GitHub Actions**, from source code and automated security scanning through private ECS deployment, HTTPS delivery, observability and controlled infrastructure teardown.

---

## Author

**Rizwan Hussain**  
Cloud / DevOps Engineering Portfolio  
GitHub: **CloudRizz**

Application credit: [IT Tools](https://github.com/CorentinTh/it-tools), created by Corentin Thomasse.