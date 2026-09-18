# Automated CI/CD Infrastructure & Website Deployment with Terraform and GitHub Actions

## 📌 Project Overview

This project demonstrates a complete **Infrastructure as Code (IaC) and CI/CD automation workflow** for deploying a website to an AWS EC2 instance.

The infrastructure is provisioned automatically using **Terraform**, the application server is configured using **Ansible**, the website is containerized with **Docker**, and **GitHub Actions** automates the CI/CD workflow.

The goal of this project is to eliminate manual infrastructure and application deployment by creating an automated pipeline from **code push → infrastructure → server configuration → Docker deployment → running website**.

---

## 🏗️ Architecture

```text
                    Developer
                        │
                        │ git push
                        ▼
                ┌─────────────────┐
                │     GitHub      │
                │   Repository    │
                └────────┬────────┘
                         │
                         ▼
                ┌─────────────────┐
                │ GitHub Actions  │
                │   CI/CD Pipeline│
                └────────┬────────┘
                         │
             ┌───────────┴───────────┐
             │                       │
             ▼                       ▼
      ┌─────────────┐        ┌─────────────┐
      │  Terraform  │        │   Website   │
      │     IaC     │        │    Build    │
      └──────┬──────┘        └──────┬──────┘
             │                       │
             ▼                       │
      ┌─────────────┐                │
      │    AWS      │                │
      │     VPC     │                │
      │   Subnet    │                │
      │     SG      │                │
      │    EC2      │                │
      └──────┬──────┘                │
             │                       │
             ▼                       ▼
      ┌──────────────────────────────────┐
      │            Ansible               │
      │      Server Configuration        │
      └────────────────┬─────────────────┘
                       │
                       ▼
                ┌─────────────┐
                │    Docker   │
                │  Container  │
                └──────┬──────┘
                       │
                       ▼
                ┌─────────────┐
                │   Website   │
                │   :80/HTTP  │
                └─────────────┘
```

---

# 🚀 Project Objectives

The main objectives of this project are to:

* Provision AWS infrastructure automatically.
* Manage infrastructure using Terraform.
* Automate Terraform execution using GitHub Actions.
* Configure the EC2 server automatically using Ansible.
* Install required server dependencies automatically.
* Containerize the website using Docker.
* Automate website deployment.
* Reduce manual configuration.
* Create a repeatable and scalable deployment process.
* Demonstrate real-world DevOps practices.

---

# 🛠️ Technologies Used

| Technology          | Purpose                      |
| ------------------- | ---------------------------- |
| **Git & GitHub**    | Source code management       |
| **GitHub Actions**  | CI/CD automation             |
| **Terraform**       | Infrastructure as Code       |
| **AWS**             | Cloud infrastructure         |
| **EC2**             | Application server           |
| **VPC**             | Network infrastructure       |
| **Security Groups** | Network security             |
| **Ansible**         | Server configuration         |
| **Docker**          | Application containerization |
| **Nginx**           | Web server                   |
| **Ubuntu**          | EC2 operating system         |

---

# ☁️ AWS Infrastructure

Terraform is responsible for creating and managing the AWS infrastructure.

The infrastructure includes:

* VPC
* Public subnet
* Internet Gateway
* Route table
* Route table association
* Security group
* EC2 instance
* Elastic IP

### Network Configuration

```text
VPC
10.0.0.0/16
│
└── Public Subnet
    10.0.1.0/24
    │
    └── Ubuntu EC2
        │
        ├── Port 22 → SSH
        └── Port 80 → HTTP
```

---

# 📁 Project Structure

```text
.
├── terraform/
│   ├── providers.tf
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tfvars.example
│   └── .gitignore
│
├── ansible/
│   ├── inventory
│   ├── playbook.yml
│   └── roles/
│       └── docker/
│
├── website/
│   ├── index.html
│   ├── Dockerfile
│   └── ...
│
├── .github/
│   └── workflows/
│       └── terraform.yml
│
├── .gitignore
└── README.md
```

---

# 🏗️ Terraform

Terraform is used to define the infrastructure as code.

Instead of manually creating AWS resources through the AWS Console, Terraform describes the desired infrastructure in `.tf` files.

### Terraform Files

#### `providers.tf`

Defines the Terraform provider and AWS configuration.

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
```

#### `main.tf`

Contains the AWS infrastructure resources such as:

* VPC
* Subnet
* Internet Gateway
* Route Table
* Security Group
* EC2
* Elastic IP

#### `variables.tf`

Contains reusable Terraform variables.

#### `outputs.tf`

Displays important information after deployment, such as:

```text
Instance ID
Public IP
Private IP
VPC ID
Subnet ID
```

#### `terraform.tfvars`

Contains environment-specific values.

This file is intentionally excluded from GitHub because it may contain sensitive configuration.

---

# ⚙️ Terraform Workflow

Terraform follows the standard workflow:

```text
terraform init
       ↓
terraform fmt
       ↓
terraform validate
       ↓
terraform plan
       ↓
terraform apply
       ↓
AWS Infrastructure
```

### Initialize Terraform

```bash
terraform init
```

Downloads the required Terraform providers and initializes the working directory.

### Format Configuration

```bash
terraform fmt
```

Formats Terraform files according to Terraform's standard formatting rules.

### Validate Configuration

```bash
terraform validate
```

Checks whether the Terraform configuration is syntactically valid.

### Preview Infrastructure

```bash
terraform plan
```

Shows what Terraform intends to create, modify, or destroy.

### Deploy Infrastructure

```bash
terraform apply
```

Creates the infrastructure in AWS.

### Destroy Infrastructure

```bash
terraform destroy
```

Removes the infrastructure managed by Terraform.

---

# 🔄 GitHub Actions CI/CD

GitHub Actions is used to automate Terraform and application deployment.

The workflow is triggered when changes are pushed to the `main` branch or when a pull request is created.

Example workflow:

```yaml
name: Terraform Infrastructure

on:
  push:
    branches:
      - main

  pull_request:
    branches:
      - main

permissions:
  contents: read

jobs:
  terraform:
    name: Terraform
    runs-on: ubuntu-latest

    defaults:
      run:
        working-directory: terraform

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ secrets.AWS_REGION }}

      - name: Terraform Init
        run: terraform init

      - name: Terraform Format Check
        run: terraform fmt -check

      - name: Terraform Validate
        run: terraform validate

      - name: Terraform Plan
        run: terraform plan
```

---

# 🔐 GitHub Secrets

AWS credentials are stored securely inside GitHub repository secrets.

The following secrets are required:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_REGION
```

Example:

```text
AWS_REGION = eu-north-1
```

Credentials are **not stored directly inside the workflow file**.

This prevents AWS credentials from being exposed in the repository.

---

# 🖥️ Ansible Server Configuration

After Terraform creates the EC2 instance, Ansible can be used to configure the server automatically.

Instead of manually connecting to the server and installing dependencies, Ansible performs the configuration.

For example:

```text
Terraform
   ↓
Create EC2
   ↓
Ansible
   ↓
Update Ubuntu
   ↓
Install Docker
   ↓
Configure Docker
   ↓
Deploy Application
```

Ansible can automate:

* System updates
* Docker installation
* Docker configuration
* Required packages
* Application directories
* Docker containers
* Nginx configuration
* Application deployment

---

# 🐳 Docker

The website is containerized using Docker.

Example Dockerfile:

```dockerfile
FROM nginx:alpine

COPY . /usr/share/nginx/html

EXPOSE 80
```

The Docker image contains the website and Nginx web server.

A Docker container is then created from the image.

```text
Website Files
      ↓
 Dockerfile
      ↓
 Docker Image
      ↓
 Docker Container
      ↓
    Nginx
      ↓
 HTTP Port 80
```

---

# 🌐 Website Deployment

The final application is deployed to the AWS EC2 instance as a Docker container.

Once deployment is completed:

```text
Internet
    │
    ▼
AWS EC2 Public IP
    │
    ▼
Port 80
    │
    ▼
Docker Container
    │
    ▼
Nginx
    │
    ▼
Website
```

The website can then be accessed through:

```text
http://<EC2-PUBLIC-IP>
```

---

# 🔁 Complete CI/CD Pipeline

The complete automation flow is:

```text
Developer pushes code
          │
          ▼
       GitHub
          │
          ▼
   GitHub Actions
          │
          ├───────────────┐
          │               │
          ▼               ▼
      Terraform       Application
          │             Pipeline
          ▼               │
     AWS EC2              │
          │               │
          └───────┬───────┘
                  ▼
               Ansible
                  │
                  ▼
          Configure Server
                  │
                  ▼
              Docker
                  │
                  ▼
          Deploy Website
                  │
                  ▼
             Live Website
```

---

# 🧪 Local Terraform Testing

Before pushing changes to GitHub, Terraform can be tested locally:

```bash
terraform init
terraform fmt
terraform validate
terraform plan
```

If everything is correct:

```bash
terraform apply
```

---

# 🔒 Security Considerations

The project follows several basic security practices:

* AWS credentials are stored as GitHub Secrets.
* Terraform state files are excluded from Git.
* `.terraform/` is excluded from Git.
* Private SSH keys are excluded from Git.
* Sensitive `.tfvars` files are excluded from Git.
* Only required AWS ports are exposed.
* SSH access should ideally be restricted to trusted IP addresses.

For production environments, additional security should be implemented, including:

* IAM least-privilege policies
* OIDC authentication for GitHub Actions
* Private subnets
* AWS Systems Manager
* HTTPS/TLS
* Secrets Manager
* Remote Terraform state
* State locking
* Monitoring and logging

---

# 📦 Terraform State

Terraform uses a state file to track infrastructure.

```text
terraform.tfstate
```

The state allows Terraform to understand the relationship between the configuration and the infrastructure running in AWS.

For a production CI/CD environment, Terraform state should be stored remotely rather than on the GitHub Actions runner.

A future improvement for this project is:

```text
Terraform
     ↓
Amazon S3
     ↓
Remote Terraform State
```

---

# 🎯 CI/CD Pipeline Goals

The final version of this project aims to achieve:

```text
git push
   ↓
GitHub Actions
   ↓
Terraform
   ↓
Create/Update AWS Infrastructure
   ↓
Ansible
   ↓
Configure EC2
   ↓
Docker
   ↓
Build/Deploy Website
   ↓
Live Application
```

This means that infrastructure and application deployment can be performed with minimal manual intervention.

---

# 📚 DevOps Concepts Demonstrated

This project demonstrates practical knowledge of:

* Infrastructure as Code
* Cloud Computing
* AWS EC2
* AWS VPC Networking
* Terraform
* Terraform State
* Terraform Variables
* Terraform Outputs
* Terraform Modules
* Git
* GitHub
* GitHub Actions
* CI/CD
* Ansible
* Configuration Management
* Docker
* Containerization
* Nginx
* Linux
* SSH
* Cloud Infrastructure Automation

---

# 🚀 Future Improvements

Planned improvements include:

* [ ] Configure Terraform remote state using Amazon S3
* [ ] Add automated Terraform `apply`
* [ ] Add Terraform approval workflow
* [ ] Integrate Ansible with Terraform outputs
* [ ] Automate Docker installation with Ansible
* [ ] Build Docker images automatically
* [ ] Push images to Docker Hub
* [ ] Automatically deploy the latest image to EC2
* [ ] Add application health checks
* [ ] Add HTTPS using SSL/TLS
* [ ] Add monitoring with Prometheus and Grafana
* [ ] Add centralized logging
* [ ] Use GitHub OIDC instead of long-lived AWS access keys
* [ ] Implement Terraform modules
* [ ] Add separate development and production environments

---

# 💡 What This Project Shows

This project demonstrates how modern DevOps practices can be combined to automate both **infrastructure and application delivery**.

Instead of manually:

```text
Create EC2
Install Docker
Configure server
Copy website
Start container
Update application
```

the process becomes:

```text
git push
   ↓
Automated CI/CD
   ↓
Terraform
   ↓
Ansible
   ↓
Docker
   ↓
AWS
   ↓
Live Website
```

The project therefore provides practical experience with **Infrastructure as Code, Configuration Management, Containerization, Cloud Computing, and Continuous Integration/Continuous Deployment**.

---

# 👨‍💻 Author

**Olayinka Olayiwola**

Cloud & DevOps Engineering

### Technologies

```text
AWS | Terraform | Ansible | Docker | GitHub Actions
Linux | Git | CI/CD | Nginx | Cloud Engineering
```
