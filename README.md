# IT Tools — Production-Style AWS ECS Platform

A production-style AWS deployment of the open-source **IT Tools** application, built to demonstrate practical Cloud, DevOps, Infrastructure as Code and CI/CD engineering.

The application is containerised with Docker and deployed to **Amazon ECS Fargate** behind an **Application Load Balancer**, with infrastructure provisioned using **Terraform** and deployments automated through **GitHub Actions using AWS OIDC**.

The final architecture keeps ECS workloads inside **private subnets with no public IP addresses and no NAT Gateway**. Private connectivity to AWS services is provided through **VPC endpoints**.

> **Project status:** Successfully deployed, validated over HTTPS, tested through the CI/CD pipeline, and subsequently torn down using the project's automated Terraform teardown process to avoid unnecessary AWS costs.

---

## What I Built

This project progressed through several stages rather than going directly from source code to Terraform.

I first ran and validated the application locally, then containerised it with Docker and deployed it manually to AWS ECS.

Once the manual deployment was working, I rebuilt the architecture using Terraform and introduced private networking, VPC endpoints, remote Terraform state and automated CI/CD.

The completed platform demonstrates:

- Multi-stage Docker builds
- Non-root Nginx runtime container
- Dedicated application health endpoint
- Amazon ECR image storage
- Amazon ECS Fargate
- Application Load Balancer
- Public and private subnet architecture
- Security-group-to-security-group access
- AWS PrivateLink / VPC endpoints
- Route 53 DNS
- ACM TLS certificates
- Terraform Infrastructure as Code
- Remote Terraform state in S3
- GitHub Actions CI/CD
- AWS OIDC authentication
- Immutable commit-SHA container tags
- Automated deployment health validation
- Automated infrastructure teardown
- Post-destroy AWS verification

---

## Architecture

```text
                            Internet
                               │
                               ▼
                     Route 53 DNS
                  it-tools.twrz.co.uk
                               │
                               ▼
                        HTTPS :443
                               │
                     ┌─────────▼─────────┐
                     │ Application Load │
                     │     Balancer     │
                     └─────────┬─────────┘
                               │
                         HTTP :8080
                               │
              ┌────────────────┴────────────────┐
              │                                 │
       Public Subnet A                   Public Subnet B
              │                                 │
              └────────────────┬────────────────┘
                               │
                         Target Group
                               │
                ┌──────────────┴──────────────┐
                │                             │
         Private Subnet A              Private Subnet B
                │                             │
         ECS Fargate Task              ECS Fargate Task
                │                             │
                └──────────────┬──────────────┘
                               │
                    Private AWS Connectivity
                               │
              ┌────────────────┼────────────────┐
              │                │                │
          ECR API          ECR Docker      CloudWatch
          Endpoint          Endpoint      Logs Endpoint
              │                │                │
              └────────────────┼────────────────┘
                               │
                        S3 Gateway Endpoint
```

### Network Design

The Terraform deployment uses:

- 1 VPC — `10.0.0.0/16`
- 2 public subnets
- 2 private subnets
- Internet Gateway
- Public route table
- Private route table
- Internet-facing Application Load Balancer
- ECS Fargate tasks deployed only into private subnets
- `assign_public_ip = false`
- No NAT Gateway

The ECS tasks therefore have **no direct route to the public internet**.

Instead, the tasks communicate privately with the AWS services required during container startup.

### VPC Endpoints

The following endpoints are provisioned:

| Endpoint | Type | Purpose |
|---|---|---|
| ECR API | Interface | ECR API communication |
| ECR DKR | Interface | Docker image registry access |
| CloudWatch Logs | Interface | ECS application log delivery |
| S3 | Gateway | Retrieval of ECR image layers stored in S3 |

This was an intentional architectural decision.

The application is a static frontend served by Nginx and does not require arbitrary outbound internet connectivity from the ECS task. VPC endpoints therefore allow the workload to remain private without introducing a NAT Gateway solely for AWS service access.

---

## Security Architecture

Security groups follow a restricted communication model rather than allowing broad access between components.

### ALB Security Group

Inbound:

```text
Internet → TCP 80
Internet → TCP 443
```

Outbound:

```text
ALB → ECS Security Group :8080
```

### ECS Security Group

Inbound:

```text
ALB Security Group → TCP 8080
```

Outbound:

```text
ECS → VPC Endpoint Security Group :443
ECS → S3 Prefix List :443
```

### VPC Endpoint Security Group

Inbound:

```text
ECS Security Group → TCP 443
```

This means port `8080` on the application container is **not exposed directly to the internet**.

Traffic must pass through the Application Load Balancer.

---

# Project Journey

## 1. Running IT Tools Locally

The project uses the open-source **IT Tools** application as the workload.

Before introducing containers or AWS infrastructure, I validated that the application could build and run successfully locally.

The project uses:

```text
Node.js 18.18.2
pnpm 9.11.0
Vue / Vite
```

The application was successfully served locally before moving to containerisation.

This separated application problems from Docker or AWS infrastructure problems during later troubleshooting.

---

## 2. Docker Containerisation

The application uses a multi-stage Docker build.

### Build Stage

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

The first stage installs the application's dependencies and generates the production build.

### Runtime Stage

```dockerfile
FROM nginxinc/nginx-unprivileged:stable-alpine AS runtime

COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
```

Only the compiled application is copied into the final image.

Node.js, pnpm, source dependencies and the build toolchain are not required inside the production container.

The runtime image also uses **nginx-unprivileged**, allowing Nginx to run without root privileges.

During local validation the resulting image was approximately **108 MB on disk / 29.6 MB content size**.

---

## 3. Application Health Check

A dedicated health endpoint was added to Nginx:

```nginx
location = /health {
    default_type application/json;
    return 200 '{"status":"ok"}';
}
```

Testing:

```bash
curl http://localhost:8080/health
```

Expected response:

```json
{"status":"ok"}
```

The same endpoint is used by:

- local Docker testing
- the Application Load Balancer target group
- ECS deployment validation
- GitHub Actions post-deployment verification

Using the same health contract throughout the platform reduces differences between local and production validation.

---

## 4. Manual AWS Deployment

Before writing the Terraform implementation, I deployed the application manually to AWS.

This helped me understand how the individual AWS services interact before abstracting them into Infrastructure as Code.

The manual deployment included:

```text
Docker
   │
   ▼
Amazon ECR
   │
   ▼
ECS Fargate
   │
   ▼
Application Load Balancer
   │
   ▼
Route 53
   │
   ▼
ACM / HTTPS
```

The container image was pushed to ECR and an ECS Fargate service was configured behind an Application Load Balancer.

The ALB target group used:

```text
Protocol: HTTP
Port:     8080
Target:   IP
Health:   /health
Matcher:  200
```

The application was then exposed through:

```text
https://it-tools.twrz.co.uk
```

and successfully returned:

```json
{"status":"ok"}
```

over HTTPS.

Once the manual deployment was proven, the manual project resources were removed before rebuilding the platform with Terraform.

---

# Infrastructure as Code

## Terraform Structure

Terraform is separated into two roots:

```text
.
├── bootstrap/
│   ├── ecr.tf
│   ├── github-oidc.tf
│   ├── github-role.tf
│   ├── state.tf
│   └── ...
│
├── infra/
│   ├── alb.tf
│   ├── backend.tf
│   ├── data.tf
│   ├── dns.tf
│   ├── ecs.tf
│   ├── iam.tf
│   ├── logs.tf
│   ├── network.tf
│   ├── security.tf
│   └── ...
│
├── app/
├── scripts/
└── .github/workflows/
```

This separation solves an important Terraform bootstrap problem.

The main infrastructure uses remote Terraform state and GitHub Actions uses AWS OIDC authentication, but those resources must exist **before** the main infrastructure can be deployed.

---

## Bootstrap Infrastructure

The `bootstrap/` Terraform configuration creates the persistent resources required by the deployment platform:

```text
S3 Terraform State Bucket
Amazon ECR Repository
GitHub OIDC Provider
GitHub Actions IAM Role
```

The state bucket uses:

- S3 versioning
- server-side encryption
- public access blocking

The ECR repository uses:

- immutable image tags
- scan-on-push
- server-side encryption

Once bootstrap is created, the main Terraform configuration can use the S3 backend.

---

## Main Infrastructure

The `infra/` configuration provisions the application infrastructure:

```text
VPC
├── Public Subnet A
├── Public Subnet B
├── Private Subnet A
├── Private Subnet B
├── Internet Gateway
├── Route Tables
└── VPC Endpoints

Application Load Balancer
├── HTTP Listener
├── HTTPS Listener
└── Target Group

ECS
├── Cluster
├── Task Definition
└── Fargate Service

Security Groups
CloudWatch Logs
IAM Execution Role
ACM Certificate
Route 53 Records
```

The existing `twrz.co.uk` Route 53 hosted zone is treated as a shared resource and is **looked up rather than created or destroyed by this project**.

---

# CI/CD Pipeline

The deployment pipeline is implemented using GitHub Actions.

```text
Developer
    │
    │ git push
    ▼
GitHub
    │
    ▼
GitHub Actions
    │
    ├── Authenticate to AWS using OIDC
    │
    ├── Build Docker image
    │
    ├── Push SHA-tagged image to ECR
    │
    ├── Terraform init
    │
    ├── Terraform plan
    │
    ├── Terraform apply
    │
    ├── Wait for ECS service stability
    │
    └── Validate /health over HTTPS
    │
    ▼
AWS ECS Fargate
```

The workflow runs when changes are pushed to `main` affecting:

```text
app/**
infra/**
.github/workflows/deploy.yml
```

Documentation and teardown-script changes therefore do not unnecessarily redeploy the application.

---

## Keyless AWS Authentication with OIDC

The pipeline does **not** store long-lived AWS access keys in GitHub.

GitHub Actions requests an OIDC identity token which AWS validates before allowing the workflow to assume the project's IAM deployment role.

```text
GitHub Actions
      │
      │ OIDC token
      ▼
AWS IAM OIDC Provider
      │
      │ sts:AssumeRoleWithWebIdentity
      ▼
GitHub Actions IAM Role
      │
      ▼
AWS
```

This removes the need for:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
```

inside the GitHub repository.

---

## Immutable Container Deployments

Each deployment uses the Git commit SHA as the Docker image tag.

Conceptually:

```text
Git commit
    │
    ▼
f4d5ca1...
    │
    ▼
Docker image
    │
    ▼
ECR
    │
    ▼
ECS Task Definition
```

This creates traceability between:

```text
Source Code → Git Commit → Docker Image → ECS Deployment
```

ECR image tags are configured as immutable.

The workflow also checks whether an image for the commit already exists before attempting to build and push it again, allowing retries without conflicting with immutable tags.

---

# HTTPS and DNS

The public endpoint uses:

- Amazon Route 53
- AWS Certificate Manager
- Application Load Balancer

HTTP traffic is redirected to HTTPS:

```text
HTTP :80
   │
   ▼
301 Redirect
   │
   ▼
HTTPS :443
   │
   ▼
ALB Target Group
   │
   ▼
ECS :8080
```

The Terraform configuration creates and validates the ACM certificate through Route 53 DNS records.

---

# Logging

ECS uses the AWS `awslogs` logging driver.

Container logs are delivered to:

```text
/ecs/it-tools
```

The CloudWatch log group is managed by Terraform with a defined retention period.

Because the ECS tasks are private, CloudWatch Logs traffic is sent through the dedicated CloudWatch Logs VPC interface endpoint.

---

# Deployment Validation

The pipeline does not treat a successful `terraform apply` as proof that the application is working.

After deployment, GitHub Actions waits for the ECS service to become stable and then performs an application-level test against:

```text
https://it-tools.twrz.co.uk/health
```

A successful deployment must return:

```json
{"status":"ok"}
```

This validates more than infrastructure creation.

It verifies the complete path:

```text
DNS
 ↓
HTTPS certificate
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
Application Health Endpoint
```

---

# Automated Teardown

Because the project uses billable AWS resources such as an Application Load Balancer, interface VPC endpoints and Fargate tasks, I also built an automated teardown process.

```bash
./scripts/destroy.sh
```

The script requires explicit confirmation before destruction.

It destroys infrastructure in the correct order:

```text
1. Main application infrastructure
             ↓
2. Bootstrap infrastructure
             ↓
3. Post-destroy AWS verification
```

Bootstrap is destroyed last because the main Terraform deployment depends on its remote state bucket and other deployment resources.

The teardown intentionally leaves shared AWS infrastructure untouched.

For example:

```text
Existing Route 53 hosted zone → retained
Default AWS VPC              → retained
Unrelated portfolio resources → retained
```

---

## Teardown Verification

A separate verification script performs read-only AWS checks after Terraform finishes:

```bash
./scripts/verify-destroy.sh
```

It verifies that project resources such as the following are no longer live:

```text
ECS
Application Load Balancer
Project VPC
VPC Endpoints
CloudWatch Log Group
ECR Repository
GitHub Actions IAM Role
GitHub OIDC Provider
Terraform State Bucket
Route 53 Application Record
ACM Certificate
```

During testing I discovered that the AWS Resource Groups Tagging API could continue returning ARNs for already deleted VPC endpoints and inactive ECS historical records.

Rather than treating the tagging API as authoritative, the verifier uses direct service-specific AWS API checks to determine whether resources still exist.

This prevents stale AWS metadata from incorrectly reporting a failed teardown.

The final teardown successfully removed the live project infrastructure while leaving shared resources untouched.

---

# Challenges and Lessons Learned

## Terraform Partial Apply

During an early deployment, an invalid route CIDR:

```text
0.0.0/0
```

was used instead of:

```text
0.0.0.0/0
```

Terraform had already created some resources before encountering the error.

After correcting the configuration, Terraform used its state to determine what had already been created and continued from the remaining infrastructure rather than recreating everything.

This gave me practical experience with Terraform's state-driven reconciliation model.

---

## Private ECS Without NAT

Moving ECS tasks from the original manual public-subnet deployment into private subnets introduced another problem:

Fargate still needed access to ECR and CloudWatch during task startup.

Instead of giving the tasks public IP addresses or introducing a NAT Gateway, I configured:

```text
ECR API Interface Endpoint
ECR DKR Interface Endpoint
CloudWatch Logs Interface Endpoint
S3 Gateway Endpoint
```

This allowed the tasks to retrieve their container images and deliver logs using private AWS networking.

---

## GitHub OIDC Troubleshooting

The initial GitHub Actions deployment failed with:

```text
Not authorized to perform sts:AssumeRoleWithWebIdentity
```

Rather than switching to static AWS credentials, I inspected the OIDC token claims generated by GitHub and compared the actual `sub` claim with the IAM trust policy.

The repository identity contained GitHub's repository and owner identifiers in addition to the repository name.

I updated the IAM trust condition to match the actual identity presented by GitHub.

After correcting the trust relationship, GitHub Actions successfully assumed the AWS role and the deployment completed without long-lived AWS credentials.

---

## Immutable ECR Tags

Using immutable ECR tags improves deployment traceability but introduced an important CI/CD consideration.

A rerun of the same GitHub commit produces the same SHA tag.

Attempting to push that tag again would conflict with ECR immutability.

The pipeline therefore checks ECR first:

```text
Does image SHA already exist?
        │
    ┌───┴───┐
   Yes      No
    │        │
  Reuse    Build
  image    + Push
```

This keeps deployments reproducible while allowing workflow retries.

---

## AWS Eventual Consistency

During teardown verification, AWS's Resource Groups Tagging API continued to display deleted VPC endpoint ARNs and inactive ECS records even though direct service APIs confirmed that the resources no longer existed.

This demonstrated why infrastructure automation should distinguish between:

```text
resource metadata
```

and:

```text
actual live infrastructure
```

The final verifier therefore treats direct service-specific checks as authoritative.

---

# Repository Structure

```text
it-tools-ecs-platform/
│
├── .github/
│   └── workflows/
│       └── deploy.yml
│
├── app/
│   ├── Dockerfile
│   ├── nginx.conf
│   └── ...
│
├── bootstrap/
│   ├── ecr.tf
│   ├── github-oidc.tf
│   ├── github-role.tf
│   ├── state.tf
│   └── ...
│
├── infra/
│   ├── alb.tf
│   ├── backend.tf
│   ├── data.tf
│   ├── dns.tf
│   ├── ecs.tf
│   ├── iam.tf
│   ├── logs.tf
│   ├── network.tf
│   ├── security.tf
│   └── ...
│
├── scripts/
│   ├── destroy.sh
│   └── verify-destroy.sh
│
├── .gitignore
└── README.md
```

---

# Technologies

| Area | Technology |
|---|---|
| Cloud | AWS |
| Containers | Docker |
| Container Runtime | ECS Fargate |
| Container Registry | Amazon ECR |
| Infrastructure as Code | Terraform |
| CI/CD | GitHub Actions |
| Authentication | GitHub OIDC / AWS IAM |
| Networking | VPC, Subnets, Security Groups |
| Private Connectivity | AWS VPC Endpoints |
| Load Balancing | Application Load Balancer |
| DNS | Amazon Route 53 |
| TLS | AWS Certificate Manager |
| Logging | Amazon CloudWatch Logs |
| State | Amazon S3 |
| Web Server | Nginx |
| Application | Vue / Vite / IT Tools |

---

# Reproducing the Project

> Deploying this project creates billable AWS resources.

## Prerequisites

You will need:

```text
AWS account
AWS CLI
Terraform
Docker
Git
GitHub repository
Route 53 hosted zone / domain
```

### 1. Clone the Repository

```bash
git clone <repository-url>
cd it-tools-ecs-platform
```

### 2. Create Bootstrap Infrastructure

```bash
cd bootstrap

terraform init
terraform plan
terraform apply
```

This creates the resources required by the deployment system, including ECR, remote state storage and GitHub OIDC infrastructure.

### 3. Configure GitHub Repository Variables

Configure the repository with the values produced by the bootstrap Terraform outputs:

```text
AWS_ROLE_ARN
AWS_REGION
ECR_REPOSITORY_URL
TF_STATE_BUCKET
```

### 4. Initialise Main Terraform

The main Terraform configuration uses the S3 remote backend.

```bash
cd ../infra

terraform init \
  -backend-config="bucket=<terraform-state-bucket>"
```

### 5. Deploy

Push an application or infrastructure change to `main`.

GitHub Actions will:

```text
Authenticate to AWS
Build the application image
Push the SHA-tagged image to ECR
Run Terraform
Deploy/update ECS
Wait for service stability
Validate the HTTPS health endpoint
```

---

# Destroying the Environment

To remove the project infrastructure:

```bash
./scripts/destroy.sh
```

The script destroys the main infrastructure first and bootstrap infrastructure second.

Afterwards:

```bash
./scripts/verify-destroy.sh
```

can be used to independently confirm that no live project resources remain.

---

# Key Outcomes

Through this project I gained practical experience designing and troubleshooting a complete container deployment lifecycle rather than only creating individual AWS resources.

The project demonstrates my ability to:

- Containerise and validate an application
- Design AWS networking across public and private subnets
- Deploy private ECS Fargate workloads
- Implement restricted security-group communication
- Use VPC endpoints for private AWS service connectivity
- Provision infrastructure using Terraform
- Separate bootstrap and application infrastructure
- Manage remote Terraform state
- Implement keyless GitHub Actions authentication using OIDC
- Build immutable SHA-based container deployments
- Troubleshoot IAM trust relationships
- Validate deployments at the application layer
- Recover from Terraform partial applies
- Automate safe infrastructure teardown
- Verify AWS resources independently after destruction

---

## Application Credit

This project uses the open-source **IT Tools** application as its workload.

The application itself was not created as part of this project. My work focuses on its **containerisation, AWS architecture, Infrastructure as Code, security, deployment automation, operational validation and teardown**.

The upstream licence is retained in the `app/` directory.

---

## Author

**Rizwan Hussain**

Cloud / DevOps Engineer

