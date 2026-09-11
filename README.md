# IT Tools — AWS ECS Fargate Platform

A production-style AWS container platform built with:

- Docker
- Amazon ECS Fargate
- Terraform
- GitHub Actions
- AWS OIDC
- Route 53
- ACM
- CloudWatch

I used the open-source **IT Tools** application as the workload and focused the project on the platform around it.

The application runs inside **private ECS Fargate tasks**, behind an **internet-facing Application Load Balancer**, with infrastructure managed through **modular Terraform**.

CI/CD is handled by GitHub Actions.

No long-lived AWS access keys are stored in GitHub.

> **Status:** Successfully deployed, tested and destroyed through GitHub Actions.

---

# Demo

Application:

```text
https://it-tools.twrz.co.uk
```

Health endpoint:

```text
https://it-tools.twrz.co.uk/health
```

Expected response:

```json
{"status":"ok"}
```

### Application Demo

[IT Tools Demo](https://github.com/user-attachments/assets/fa1489bc-1522-47a4-ad0d-b8080ce39ef7)

---

# Project Overview

The aim of this project was not simply to get a Docker container running.

I wanted to understand the full path from source code to a working AWS deployment.

That meant working with:

- Docker
- Amazon ECR
- Amazon ECS
- AWS Fargate
- VPC networking
- public and private subnets
- security groups
- Application Load Balancer
- Route 53
- ACM
- VPC endpoints
- CloudWatch
- Terraform
- Terraform remote state
- GitHub Actions
- AWS OIDC
- CI/CD
- infrastructure teardown

I first deployed the application manually.

Once I understood how the AWS services fitted together, I removed that environment and rebuilt it using Terraform.

The Terraform version also improved the architecture rather than simply copying the original manual setup.

---

# What Is IT Tools?

[IT Tools](https://github.com/CorentinTh/it-tools) is an open-source collection of browser-based utilities for developers and IT professionals.

It contains tools such as:

- encoders
- decoders
- converters
- generators
- formatters
- networking tools
- text utilities
- development helpers

The application uses:

```text
Vue
Vite
Node.js
```

I did **not** build the IT Tools application.

My work in this repository focuses on:

- containerisation
- AWS infrastructure
- networking
- security
- Terraform
- CI/CD
- deployment
- logging
- teardown

---

# Why I Chose IT Tools

I wanted a real application rather than another hello-world container.

At the same time, I wanted the focus of the project to remain on Cloud and DevOps engineering.

IT Tools worked well because:

- it is a real open-source application
- it builds into static frontend files
- it can be served with Nginx
- it is easy to containerise
- it has a simple health endpoint
- it does not require a database
- it lets me focus on infrastructure

### Benefit

Most of my time could be spent on:

```text
AWS
Docker
Terraform
Networking
CI/CD
Security
```

### Drawback

Because IT Tools is mainly a static frontend, this project does not demonstrate:

- databases
- queues
- backend APIs
- secrets management
- service-to-service communication

Those would make sense in a future project.

---

# Why ECS Fargate?

I deliberately chose **Amazon ECS Fargate** instead of:

- EC2
- Vercel
- Netlify
- static S3 hosting

The point of the project was to demonstrate container infrastructure.

---

## Why Not EC2?

EC2 would have worked.

However, I would also have needed to manage:

- the operating system
- instance patching
- Docker installation
- host availability
- instance sizing
- container host maintenance

Fargate removes most of that host management.

I can focus on:

- containers
- networking
- IAM
- load balancing
- scaling
- deployment

### Benefit

Less infrastructure to manage at host level.

### Drawback

Fargate can be more expensive than well-utilised EC2 at larger scale.

It also gives less control over the underlying compute host.

For this project, the reduced management overhead was more useful.

---

## Why Not Vercel or Netlify?

IT Tools could easily run on a simpler frontend hosting platform.

That would be cheaper and easier.

However, it would hide most of the infrastructure I wanted to practise.

Using ECS meant I had to work with:

- VPCs
- subnets
- routing
- security groups
- ECR
- ECS
- IAM
- ALB
- Route 53
- ACM
- CloudWatch
- Terraform
- GitHub Actions

That made ECS a much better fit for the learning goal.

---

# Expected Usage

This is a portfolio deployment rather than a production application with an established user base.

During development I normally use:

```hcl
desired_count = 1
```

This keeps AWS costs lower while I repeatedly deploy and destroy the environment.

The platform itself is already designed across **two Availability Zones**.

The ECS desired task count can be increased without redesigning the network.

For example:

```hcl
desired_count = 2
```

allows ECS to run multiple copies of the application across the configured private subnets.

More healthy tasks provide:

- more capacity
- task redundancy
- greater resilience

For a production workload I would combine multiple tasks with **ECS Service Auto Scaling**.

---

# Architecture

![IT Tools AWS ECS Fargate Architecture](<docs/images/architecture - IT - tools.png>)

The final platform is built across two Availability Zones in:

```text
eu-west-2
```

The ECS tasks are private.

Only the Application Load Balancer accepts public application traffic.

---

# Architecture Summary

| Layer | Technology |
|---|---|
| Application | IT Tools |
| Frontend | Vue / Vite |
| Runtime | Nginx |
| Container | Docker |
| Registry | Amazon ECR |
| Compute | ECS Fargate |
| Networking | Custom VPC |
| Availability | Two AZs |
| Load Balancer | ALB |
| DNS | Route 53 |
| HTTPS | ACM |
| Logging | CloudWatch |
| Private AWS Access | VPC Endpoints |
| Infrastructure | Terraform |
| Terraform State | S3 |
| CI/CD | GitHub Actions |
| AWS Authentication | OIDC |

---

# Request Flow

A normal application request follows:

```text
User
  ↓
Route 53
  ↓
Application Load Balancer
  ↓
Target Group
  ↓
ECS Service
  ↓
Fargate Task
  ↓
Nginx
  ↓
IT Tools
```

The Fargate tasks do not have public IP addresses.

---

# VPC Design

The final project uses a dedicated VPC rather than the default AWS VPC.

The VPC spans:

```text
eu-west-2a
eu-west-2b
```

Each Availability Zone contains:

- one public subnet
- one private subnet

Conceptually:

```text
VPC
│
├── eu-west-2a
│   ├── Public Subnet
│   └── Private Subnet
│
└── eu-west-2b
    ├── Public Subnet
    └── Private Subnet
```

---

# Why a Custom VPC?

My first manual ECS deployment used the default VPC.

That made the initial deployment easier to understand.

For the final project, I wanted explicit control over:

- subnet design
- routing
- internet access
- private connectivity
- security groups
- resource placement

### Benefit

The network is fully defined in Terraform and can be recreated consistently.

### Drawback

A custom VPC adds complexity.

There are more routing and security decisions to make.

For this project, that complexity was useful because networking was one of the areas I wanted to understand better.

---

# Public and Private Subnets

The Application Load Balancer is placed in the public subnets.

ECS tasks are placed in the private subnets.

```text
Internet
   ↓
Public ALB
   ↓
Private ECS
```

The ECS service uses:

```hcl
assign_public_ip = false
```

This means application tasks do not receive public IP addresses.

---

# Why Keep ECS Private?

I did not want application containers directly exposed to the internet.

All public requests must first pass through the ALB.

### Benefits

- ECS tasks are not directly public
- one controlled public entry point
- clearer security-group rules
- ALB health checking
- HTTPS termination at the ALB

### Drawback

Private tasks still need access to some AWS services.

That connectivity has to be designed deliberately.

---

# No NAT Gateway

The project deliberately does **not** use a NAT Gateway.

A common private subnet design looks like:

```text
Private ECS
     ↓
NAT Gateway
     ↓
Internet Gateway
     ↓
Internet
```

I did not need general internet access from the ECS task.

The application is a static frontend served by Nginx.

Once it is running, it has very limited outbound requirements.

---

# What ECS Still Needs

Even a private ECS task needs access to AWS services.

During startup it needs to:

- retrieve ECR authentication information
- access ECR
- download image layers
- send logs to CloudWatch

Without NAT, those routes still need to exist.

I solved this using VPC endpoints.

---

# VPC Endpoints

The project uses:

| Service | Endpoint Type |
|---|---|
| ECR API | Interface |
| ECR DKR | Interface |
| CloudWatch Logs | Interface |
| S3 | Gateway |

The path becomes:

```text
Private ECS
     ↓
VPC Endpoint
     ↓
AWS Service
```

---

## Why VPC Endpoints?

### Benefits

- no general internet route from ECS
- private connectivity to AWS services
- no NAT Gateway
- reduced NAT-related cost
- tighter network access

### Drawbacks

Interface endpoints have their own:

- hourly cost
- data-processing cost

For workloads requiring lots of general internet access, NAT may be simpler.

For this workload, endpoints were a better fit.

---

# High Availability Design

The infrastructure spans two Availability Zones.

The ALB uses both public subnets.

The ECS service uses both private subnets.

```text
               ALB
             ↙     ↘
      eu-west-2a   eu-west-2b
           ↓           ↓
     Private       Private
      Subnet        Subnet
```

The network therefore already supports a multi-AZ workload.

---

# Task Count and Availability

During development:

```hcl
desired_count = 1
```

With one running task:

```text
Multi-AZ VPC          ✅
Multi-AZ ALB          ✅
Multiple app tasks    ❌
Task redundancy       ❌
```

The architecture is multi-AZ capable, but the application only has one active task.

---

## Running Multiple Tasks

With:

```hcl
desired_count = 2
```

ECS can distribute service tasks across the configured Availability Zones.

Conceptually:

```text
                 ALB
              ↙       ↘
       eu-west-2a    eu-west-2b
            ↓            ↓
        ECS Task      ECS Task
```

If one task becomes unhealthy, the ALB can continue sending requests to another healthy target.

---

## Why More Tasks Improve Availability

More healthy tasks provide:

- more application capacity
- task-level redundancy
- greater resilience

The important distinction is:

> The infrastructure already supports high availability. Increasing the number of running ECS tasks allows the workload to make use of that design.

More tasks do not solve every possible failure.

A full production setup would also consider:

- ECS placement
- autoscaling
- deployment rollback
- monitoring
- application-level failures

---

# Security Groups

I use security-group references between components rather than broad internal CIDR rules.

---

## ALB Security Group

Inbound:

```text
Internet → TCP 80
Internet → TCP 443
```

HTTP redirects to HTTPS.

Outbound:

```text
ALB → ECS :8080
```

---

## ECS Security Group

Inbound:

```text
ALB Security Group
        ↓
TCP 8080
```

Outbound:

```text
ECS → Endpoint Security Group :443
ECS → S3 Prefix List :443
```

---

## Endpoint Security Group

Inbound:

```text
ECS Security Group
        ↓
TCP 443
```

This creates clear traffic paths between each layer.

---

# HTTPS

The public application uses:

```text
https://it-tools.twrz.co.uk
```

TLS is managed by AWS Certificate Manager.

HTTP requests are redirected:

```text
HTTP :80
   ↓
HTTPS :443
```

---

# Route 53

The existing hosted zone is:

```text
twrz.co.uk
```

The project does **not** create or own that zone.

Terraform looks it up as an existing resource.

It only manages the application-specific DNS records.

### Why?

Destroying this project must not delete unrelated DNS infrastructure.

---

# ACM

Terraform creates the certificate for:

```text
it-tools.twrz.co.uk
```

It also creates the DNS validation records required by ACM.

### Benefit

Certificate creation and validation are managed through Terraform.

### Drawback

HTTPS introduces more dependencies between:

- Route 53
- ACM
- ALB
- Terraform

It is more complex than HTTP-only hosting, but far closer to a real deployment.

---

# Docker

Before deploying anything to AWS, I made sure the application worked locally.

The application build uses:

```text
Node.js 18.18.2
pnpm 9.11.0
Vue
Vite
```

---

# Multi-Stage Docker Build

The Dockerfile uses a separate build and runtime stage.

## Build Stage

```dockerfile
FROM node:18.18.2-alpine AS builder

ENV NPM_CONFIG_LOGLEVEL=warn
ENV CI=true

WORKDIR /app

RUN corepack enable \
    && corepack prepare pnpm@9.11.0 --activate

COPY package.json pnpm-lock.yaml ./

RUN pnpm install --frozen-lockfile

COPY . .

RUN pnpm build
```

---

## Runtime Stage

```dockerfile
FROM nginxinc/nginx-unprivileged:stable-alpine AS runtime

COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
```

Only the compiled frontend is copied into the final image.

---

## Why Multi-Stage?

### Benefits

- smaller runtime image
- Node build tools are removed
- cleaner build/runtime separation
- less unnecessary software in production

### Drawback

The Dockerfile is slightly more complex.

For this project, the cleaner runtime image was worth it.

---

# Non-Root Nginx

The runtime uses:

```text
nginxinc/nginx-unprivileged
```

The application listens on:

```text
8080
```

### Benefit

Nginx does not need to run as root.

### Drawback

The container and ALB configuration both need to account for port `8080`.

---

# Health Endpoint

Nginx exposes:

```text
/health
```

Configuration:

```nginx
location = /health {
    default_type application/json;
    return 200 '{"status":"ok"}';
}
```

Expected response:

```json
{"status":"ok"}
```

The ALB target group uses this endpoint to check task health.

I also use it during manual validation.

---

# Local Testing

Build:

```bash
docker build -t it-tools:local ./app
```

Run:

```bash
docker run --rm -p 8080:8080 it-tools:local
```

Test:

```bash
curl -I http://localhost:8080
```

Health:

```bash
curl http://localhost:8080/health
```

---

# How the Project Evolved

I deliberately built the project in stages.

---

## Stage 1 — Local Application

I first ran IT Tools locally.

This gave me a known-good starting point before adding Docker.

---

## Stage 2 — Docker

I containerised the application and tested:

- build
- Nginx
- port 8080
- SPA routing
- `/health`
- non-root runtime

---

## Stage 3 — Manual AWS Deployment

Before writing Terraform, I deployed the application manually.

This helped me understand:

- ECR
- ECS
- Fargate
- IAM
- task definitions
- services
- ALB
- target groups
- Route 53
- ACM
- CloudWatch

The first version used:

- default VPC
- public ECS tasks
- public IP addresses

It was intentionally simple.

---

## Stage 4 — Terraform Redesign

Once the manual version worked, I removed it and redesigned the architecture.

```text
MANUAL VERSION

Default VPC
Public ECS
Public Task IPs

        ↓

FINAL VERSION

Custom VPC
Two Availability Zones
Public ALB
Private ECS
No Public Task IP
No NAT Gateway
VPC Endpoints
Terraform Modules
GitHub Actions
```

The Terraform version improved the design instead of simply recreating it.

---

# Terraform Structure

Terraform is split into:

```text
bootstrap/
infra/
```

They have separate responsibilities.

---

# Bootstrap

The bootstrap stack creates:

- Amazon ECR repository
- S3 Terraform state bucket
- GitHub OIDC provider
- GitHub Actions IAM role
- GitHub Actions IAM policy

These resources need to exist before the main CI/CD deployment can run.

---

# Why Bootstrap Is Separate

GitHub Actions needs:

```text
AWS Authentication
+
Terraform State
+
ECR
```

before deploying the application.

That creates a dependency problem.

I solve it like this:

```text
Local Terraform
      ↓
bootstrap/
      ↓
OIDC + IAM + S3 + ECR
      ↓
GitHub Actions
      ↓
infra/
```

### Benefit

The CI/CD foundation stays in place when I destroy the application environment.

### Drawback

There are two Terraform lifecycles to understand.

The application stack must be removed before bootstrap during a full teardown.

---

# Terraform Modules

The main infrastructure is modularised.

```text
infra/modules/
├── acm/
├── alb/
├── cloudwatch/
├── ecs/
├── iam/
├── route53/
├── security_groups/
├── vpc/
└── vpc_endpoints/
```

The root configuration calls these modules.

### Benefits

- easier to read
- clearer responsibilities
- easier to maintain
- easier to reuse
- cleaner root configuration

### Drawback

Modules create more files, variables and outputs.

For very small projects that can be unnecessary.

For this project, the separation made the infrastructure much easier to follow.

---

# Terraform Remote State

The main Terraform state is stored in Amazon S3.

Backend:

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

The bucket name is supplied during:

```bash
terraform init
```

---

## State Bucket Controls

The bucket uses:

- versioning
- AES256 encryption
- blocked public access
- native Terraform S3 locking

### Benefit

Local Terraform and GitHub Actions use the same state.

### Drawback

The state bucket becomes important infrastructure itself.

That is why it belongs in bootstrap.

---

# CI/CD

The project uses three GitHub Actions workflows:

```text
.github/workflows/
├── app-pipeline.yml
├── terraform-deploy.yml
└── terraform-destroy.yml
```

Each workflow has a clear responsibility.

---

# Application Pipeline

The Application Pipeline handles container delivery.

It:

- checks out the repository
- authenticates to AWS through OIDC
- logs into ECR
- builds the Docker image
- tags it with the Git commit SHA
- pushes it to ECR

Example:

```text
Git Commit
c19d0dad...
      ↓
ECR Image
it-tools:c19d0dad...
```

---

# Why Git SHA Tags?

Each Docker image maps directly to a Git commit.

### Benefits

- traceability
- immutable deployment references
- easier debugging
- easier rollback identification

The ECR repository uses immutable tags.

### Drawback

The same tag cannot simply be overwritten during a retry.

The CI/CD workflow therefore needs to manage image tags carefully.

---

# Terraform Deploy Pipeline

A successful Application Pipeline automatically triggers Terraform Deploy.

This uses:

```text
workflow_run
```

The deployment workflow uses the exact:

```text
head_sha
```

from the Application Pipeline.

That SHA becomes the Terraform image tag.

```text
Application Pipeline
     ↓
Build SHA X
     ↓
Push SHA X
     ↓
Terraform Deploy
     ↓
Deploy SHA X
```

This keeps the application build and infrastructure deployment aligned.

---

# Terraform Deploy Steps

The workflow performs:

```text
Checkout
   ↓
Set Image SHA
   ↓
AWS OIDC
   ↓
terraform fmt
   ↓
terraform init
   ↓
terraform validate
   ↓
terraform plan
   ↓
terraform apply
```

Terraform Deploy can also be triggered manually with an optional image tag.

---

# Terraform Destroy Pipeline

Infrastructure teardown uses a separate workflow.

Destroy is deliberately manual.

The workflow requires:

```text
DESTROY
```

to be entered before it continues.

Flow:

```text
Manual Trigger
      ↓
Confirm DESTROY
      ↓
AWS OIDC
      ↓
Terraform Init
      ↓
Terraform Destroy
```

The GitHub workflow destroys:

```text
infra/
```

only.

---

# Why Bootstrap Is Retained

The GitHub Destroy workflow leaves:

- ECR
- S3 Terraform state bucket
- GitHub OIDC provider
- GitHub Actions IAM role
- GitHub Actions IAM policy

These belong to:

```text
bootstrap/
```

### Benefit

The application environment can be redeployed without recreating the CI/CD foundation.

### Drawback

A GitHub destroy does not mean every project-related resource has been removed.

That is intentional.

---

# Full Teardown

For complete removal I use:

```bash
./scripts/destroy.sh
```

The project also contains:

```text
scripts/verify-destroy.sh
```

Full teardown order:

```text
Destroy infra/
      ↓
Destroy bootstrap/
      ↓
Verify AWS
```

The order matters because the application Terraform state depends on the bootstrap S3 bucket.

---

# GitHub OIDC

GitHub Actions authenticates to AWS using OpenID Connect.

```text
GitHub Actions
      ↓
OIDC Token
      ↓
AWS OIDC Provider
      ↓
STS AssumeRoleWithWebIdentity
      ↓
GitHub Actions IAM Role
      ↓
AWS
```

No permanent:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
```

are stored in GitHub.

### Benefit

The workflow receives temporary credentials.

### Drawback

OIDC trust policies are more complex than static access keys.

---

# Problems I Had to Solve

The troubleshooting was one of the most useful parts of this project.

---

## OIDC Trust Failure

My first Application Pipeline failed with:

```text
Not authorized to perform sts:AssumeRoleWithWebIdentity
```

The IAM trust relationship did not match the GitHub repository identity correctly.

After correcting the OIDC subject configuration, the workflow successfully assumed the AWS role.

This helped me understand:

```text
GitHub Identity
      ↓
OIDC Claims
      ↓
IAM Trust
      ↓
AWS STS
```

---

## Private ECS Connectivity

Moving ECS into private subnets caused another problem.

The task still needed access to:

- ECR API
- ECR Docker registry
- S3 image layers
- CloudWatch Logs

Without NAT, those services needed another network path.

The solution was the VPC endpoint design used in the final architecture.

---

## Image SHA Mismatch

During testing I manually triggered Terraform Deploy with an image SHA that did not exist in ECR.

ECS failed to pull the image.

That exposed a weakness in the deployment process.

The final solution was:

```text
Application Pipeline
      ↓
Build SHA X
      ↓
Push SHA X
      ↓
workflow_run
      ↓
Terraform Deploy SHA X
```

This removed the need to manually coordinate application image tags.

---

## Destroy IAM Permission

The first GitHub Terraform Destroy test also exposed a missing IAM permission.

Terraform needed:

```text
iam:ListInstanceProfilesForRole
```

while deleting the ECS execution role.

I added the permission to the Terraform-managed GitHub Actions IAM policy.

The destroy workflow then completed successfully.

This showed me that deployment permissions and teardown permissions are not always identical.

---

# CloudWatch Logging

ECS sends container logs to:

```text
/ecs/it-tools
```

using the `awslogs` driver.

Because ECS does not have general internet access, CloudWatch Logs is reached through a VPC interface endpoint.

During testing I confirmed the running task created CloudWatch log streams successfully.

---

# Final Deployment Validation

The complete deployment path was tested:

```text
Application Pipeline
        ↓
Docker Build
        ↓
Amazon ECR
        ↓
Terraform Deploy
        ↓
ECS Fargate
        ↓
ALB
        ↓
HTTPS
```

I verified:

```text
Application: HTTP/2 200
Health:      HTTP/2 200
Response:    {"status":"ok"}
```

I also confirmed:

```text
Desired Tasks: 1
Running Tasks: 1
Pending Tasks: 0
```

and confirmed CloudWatch logs were being created.

---

# Pipeline Evidence

## Application Pipeline

Successful stages:

```text
Configure AWS Credentials  ✅
Login to ECR               ✅
Docker Build               ✅
Docker Push                ✅
```

![Application Pipeline Deployed](<docs/images/application pipeline deployed.png>)

---

## Terraform Deploy

The successful Application Pipeline automatically triggered Terraform Deploy.

```text
Application Pipeline ✅
        ↓
workflow_run
        ↓
Terraform Deploy ✅
```

![Terraform Deployed Success](<docs/images/application pipeline auto into terraform deploy.png>)

---

## Terraform Destroy

The manually triggered Terraform Destroy workflow completed successfully.

```text
Confirmation       ✅
AWS Authentication ✅
Terraform Init     ✅
Terraform Destroy  ✅
```

![Terraform Destroy](<docs/images/all 3 pipelines completed.png>)
s
---

# Repository Structure

```text
it-tools-ecs-platform/
├── .github/
│   └── workflows/
│       ├── app-pipeline.yml
│       ├── terraform-deploy.yml
│       └── terraform-destroy.yml
├── app/
│   ├── Dockerfile
│   ├── .dockerignore
│   ├── nginx.conf
│   ├── LICENSE
│   └── application source
├── bootstrap/
│   ├── ecr.tf
│   ├── github-oidc.tf
│   ├── github-role.tf
│   ├── state.tf
│   └── supporting Terraform files
├── infra/
│   ├── backend.tf
│   ├── main.tf
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
├── scripts/
│   ├── destroy.sh
│   └── verify-destroy.sh
├── docs/
│   └── images/
└── README.md
```

---

# Security Controls

The current project includes:

- private ECS tasks
- no public task IP addresses
- ALB-only public ingress
- HTTPS
- ACM certificates
- HTTP-to-HTTPS redirection
- security-group references
- VPC endpoints
- no NAT Gateway
- non-root Nginx
- GitHub OIDC
- no permanent AWS keys
- immutable ECR image tags
- ECR scan-on-push
- encrypted Terraform state
- blocked public state bucket
- S3 native state locking
- dedicated ECS execution IAM role

---

# Main Design Trade-Offs

| Decision | Benefit | Drawback |
|---|---|---|
| ECS Fargate | No host management | Can cost more than EC2 |
| Private ECS | Reduced public exposure | More networking complexity |
| No NAT | Avoid NAT cost and open egress | Requires VPC endpoints |
| VPC Endpoints | Private AWS connectivity | Interface endpoint cost |
| Multi-AZ VPC | Supports resilient workloads | More network resources |
| ALB | Health checks and balancing | Additional cost |
| OIDC | No permanent AWS keys | More complex trust policy |
| Terraform Modules | Cleaner infrastructure | More files and interfaces |
| Git SHA Tags | Strong traceability | Tags cannot be overwritten |
| Separate Bootstrap | Easy redeployment | Two Terraform lifecycles |

---

# Future Considerations

There are several areas I would improve if this became a real production platform.

---

## ECS Service Auto Scaling

The architecture already supports multiple tasks across two Availability Zones.

I would add ECS Service Auto Scaling based on:

- CPU
- memory
- ALB request count

This would automatically increase or reduce task count depending on demand.

---

## Minimum Two Running Tasks

For a real production workload I would normally run at least:

```hcl
desired_count = 2
```

rather than the single task used during development.

This would give the application task-level redundancy across the existing multi-AZ architecture.

---

## Deployment Circuit Breaker

I would enable the ECS deployment circuit breaker.

This could automatically roll back failed ECS service deployments.

---

## Terraform Plan Pipeline

A separate pull-request pipeline could run:

```text
terraform fmt
terraform validate
terraform plan
```

before changes are merged.

This would make infrastructure changes easier to review.

---

## Terraform Security Scanning

I would add:

- TFLint
- Checkov
- tfsec

These would provide additional infrastructure validation.

---

## Container Scanning

I would add Trivy to scan the application image before deployment.

---

## Monitoring

Future monitoring improvements could include:

- CloudWatch alarms
- ECS CPU alarms
- ECS memory alarms
- ALB unhealthy-target alarms
- SNS notifications
- ALB access logs
- VPC Flow Logs

---

## GitHub Environment Protection

For production I would consider:

- protected environments
- manual production approvals
- branch protection
- required status checks
- GitHub Action SHA pinning

---

## Least-Privilege IAM

The GitHub Actions IAM role is project-specific.

I would continue reducing its permissions towards more granular resource-level access.

---

## ECR Lifecycle Policy

Every application deployment creates an immutable Git-SHA image.

Over time, old images would build up.

I would add an ECR lifecycle policy to automatically remove older unused images.

---

## Container Hardening

Additional runtime security could include:

- read-only root filesystem
- explicit container health checks
- reduced Linux capabilities
- tighter filesystem permissions
- stricter VPC endpoint policies

---

# What I Learned

The biggest lesson from this project was that getting the container running is only one part of the problem.

Once ECS became private, several dependencies became more obvious.

```text
Private ECS
    ↓
Needs ECR
    ↓
ECR layers use S3
    ↓
Logging needs CloudWatch
    ↓
Each service needs a network path
    ↓
Each path needs security rules
```

I also gained a much clearer understanding of high availability.

Simply drawing two Availability Zones does not make an application highly available.

The platform must actually support workloads across them.

In this project:

```text
ALB spans both AZs
        +
ECS uses subnets in both AZs
        +
Multiple tasks can run across them
        =
Multi-AZ workload capability
```

During development I use one task to reduce cost.

Increasing the number of healthy tasks provides more:

- capacity
- redundancy
- resilience

without needing to redesign the platform.

---

# Final Takeaway

This project started with a simple question:

```text
Can I deploy a Docker container to ECS?
```

It eventually became:

```text
How should I design,
secure,
automate,
observe
and remove
the platform around it?
```

That was the most useful part of the project.

It gave me hands-on experience with:

- AWS
- Docker
- Terraform
- ECS
- networking
- security
- GitHub Actions
- CI/CD
- troubleshooting

More importantly, it helped me understand **why** the infrastructure is designed this way rather than simply learning which commands create it.

---

# Application Credit

This project uses the open-source **IT Tools** application by Corentin Thomasset.

I did not create the upstream application.

My work focuses on:

- Docker
- AWS
- networking
- security
- Terraform
- CI/CD
- deployment automation
- operational validation
- teardown

The upstream GPLv3 licence is retained in the `app/` directory.

---

# Author

**Rizwan Hussain**

Cloud / DevOps Engineer

GitHub: `CloudRizz`