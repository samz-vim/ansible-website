# Ansible EC2 Configuration & Deployment with automated CICD infrastructure with terraform and github action

## 📌 Overview

This project uses **Ansible** to automatically configure and provision an existing AWS EC2 instance for application deployment.

The Ansible configuration is designed to work as part of a larger DevOps workflow where:

**Terraform** creates the AWS infrastructure → **Ansible** configures the EC2 instance → **Docker** runs the application → **GitHub Actions** automates the entire process.

The goal is to eliminate manual server configuration and create a repeatable deployment process.

---

## 🏗️ Architecture

```text
                    GitHub Actions
                          │
                          ▼
                     Terraform
                          │
                    Creates EC2
                          │
                          ▼
                     AWS EC2
                          │
                          ▼
                       Ansible
                          │
              ┌───────────┴───────────┐
              │                       │
        Configure Server         Install Docker
              │                       │
              └───────────┬───────────┘
                          ▼
                    Docker Ready
                          │
                          ▼
                    Pull Image
                          │
                          ▼
                 Run Application
                          │
                          ▼
                      Website
```

---

## 🛠️ Technologies Used

* Ansible
* AWS EC2
* Ubuntu
* SSH
* Docker
* GitHub Actions
* Terraform
* Docker Hub

---

## 📁 Project Structure

```text
ans/
│
├── ansible.cfg
│
├── inventory/
│   └── hosts.ini
│
├── playbooks/
│   ├── setup.yml
│   ├── docker.yml
│   └── deploy.yml
│
└── README.md
```

---

# ⚙️ Prerequisites

Before using this project, make sure you have:

* An AWS account
* A running Ubuntu EC2 instance
* EC2 public IP address
* EC2 SSH private key (`.pem`)
* Ubuntu/WSL or another Linux environment
* Ansible installed
* SSH access to the EC2 instance
* Docker Hub account if deploying a private image

---

# 🔐 SSH Configuration

The EC2 private key should **not** be stored directly inside the project or committed to GitHub.

For local development, store the key inside your WSL/Linux environment:

```bash
mkdir -p ~/.ssh
```

Copy your key:

```bash
cp "/mnt/c/Users/Dell/Downloads/docker.pem" ~/.ssh/docker.pem
```

Set secure permissions:

```bash
chmod 400 ~/.ssh/docker.pem
```

Verify:

```bash
ls -l ~/.ssh/docker.pem
```

The key should have restricted permissions:

```text
-r--------
```

---

# 📝 Inventory Configuration

The inventory defines the servers that Ansible manages.

Example:

```ini
[webservers]
ec2 ansible_host=YOUR_EC2_PUBLIC_IP ansible_user=ubuntu ansible_ssh_private_key_file=/home/YOUR_USERNAME/.ssh/docker.pem
```

Replace:

```text
YOUR_EC2_PUBLIC_IP
```

with the public IP of your EC2 instance.

---

# 🔍 Test SSH Connection

Before running Ansible, verify that SSH works:

```bash
ssh -i ~/.ssh/docker.pem ubuntu@YOUR_EC2_PUBLIC_IP
```

If the connection is successful, exit the server:

```bash
exit
```

---

# 🧪 Test Ansible Connectivity

Run:

```bash
ansible webservers -m ping
```

A successful connection should return:

```text
ec2 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

This confirms that Ansible can communicate with the EC2 instance.

---

# ⚙️ Server Configuration

The `setup.yml` playbook performs basic server configuration.

Example:

```yaml
---
- name: Configure AWS EC2 server
  hosts: webservers
  become: true

  tasks:

    - name: Update apt package cache
      apt:
        update_cache: yes

    - name: Install required packages
      apt:
        name:
          - git
          - curl
          - unzip
          - ca-certificates
        state: present
```

Run:

```bash
ansible-playbook playbooks/setup.yml
```

---

# 🐳 Docker Configuration

The `docker.yml` playbook configures Docker on the EC2 instance.

It:

1. Updates the package repository
2. Installs Docker
3. Starts the Docker service
4. Enables Docker to start automatically
5. Adds the Ubuntu user to the Docker group

Example:

```yaml
---
- name: Configure Docker on AWS EC2
  hosts: webservers
  become: true

  tasks:

    - name: Update apt cache
      apt:
        update_cache: yes

    - name: Install Docker
      apt:
        name: docker.io
        state: present

    - name: Start Docker
      service:
        name: docker
        state: started
        enabled: true

    - name: Add ubuntu user to Docker group
      user:
        name: ubuntu
        groups: docker
        append: true
```

Run:

```bash
ansible-playbook playbooks/docker.yml
```

---

# 🔎 Verify Docker

After the playbook completes:

```bash
ansible webservers -a "docker --version"
```

You can also verify that Docker is running:

```bash
ansible webservers -a "systemctl is-active docker"
```

Expected:

```text
active
```

---

# 🚀 Application Deployment

Once Docker is configured, Ansible can deploy the application from a Docker registry.

The deployment process is:

```text
Docker Registry
      │
      │ docker pull
      ▼
AWS EC2
      │
      ▼
Docker Container
      │
      ▼
Application
```

For example, the application image can be:

```text
samzcode/my-website:latest
```

Ansible can pull the image and run it on the EC2 instance.

Example deployment tasks:

```yaml
---
- name: Deploy website
  hosts: webservers
  become: true

  tasks:

    - name: Pull website image
      community.docker.docker_image:
        name: samzcode/my-website:latest
        source: pull

    - name: Remove old container
      community.docker.docker_container:
        name: my-website
        state: absent

    - name: Start website container
      community.docker.docker_container:
        name: my-website
        image: samzcode/my-website:latest
        state: started
        restart_policy: always
        ports:
          - "80:80"
```

Install the Docker collection if required:

```bash
ansible-galaxy collection install community.docker
```

---

# 🔄 Terraform + Ansible + Docker

This Ansible project is designed to integrate with Terraform.

Terraform is responsible for **infrastructure provisioning**:

```text
VPC
Subnet
Security Group
EC2
Elastic IP
```

Ansible is responsible for **server configuration**:

```text
Update server
Install packages
Install Docker
Configure Docker
Prepare application environment
Deploy application
```

Docker is responsible for **application execution**:

```text
Docker Image
      ↓
Docker Container
      ↓
Website
```

---

# 🤖 GitHub Actions Integration

The final automation will run from GitHub Actions.

The intended workflow is:

```text
Git Push
   │
   ▼
GitHub Actions
   │
   ▼
Terraform
   │
   ├── terraform init
   ├── terraform plan
   └── terraform apply
           │
           ▼
       AWS EC2
           │
           ▼
      Get EC2 IP
           │
           ▼
        Ansible
           │
           ├── Configure EC2
           ├── Install Docker
           └── Start Docker
                   │
                   ▼
              Pull Image
                   │
                   ▼
             Run Container
                   │
                   ▼
                Website
```

The EC2 IP should be obtained dynamically from Terraform rather than hard-coded.

For example:

```bash
terraform output -raw instance_public_ip
```

This IP can then be passed to Ansible to create a dynamic inventory.

---

# 🔐 GitHub Actions Secrets

When running Ansible from GitHub Actions, the EC2 private key should be stored as a GitHub Actions secret.

Example:

```text
EC2_SSH_KEY
```

The workflow can create the temporary key file:

```bash
echo "${{ secrets.EC2_SSH_KEY }}" > docker.pem
chmod 400 docker.pem
```

The private key should never be committed to GitHub.

---

# 🎯 Project Objective

The objective of this project is to demonstrate an automated infrastructure and application deployment workflow using:

```text
Terraform
    ↓
AWS Infrastructure
    ↓
Ansible
    ↓
Server Configuration
    ↓
Docker
    ↓
Container Deployment
    ↓
Website
```

This approach reduces manual configuration and provides a repeatable process for deploying applications to AWS EC2.

---

# 📚 What This Project Demonstrates

* Infrastructure as Code with Terraform
* Configuration management with Ansible
* AWS EC2 provisioning
* Linux server administration
* SSH-based remote management
* Docker installation and configuration
* Container deployment
* Docker image management
* GitHub Actions automation
* CI/CD concepts
* Infrastructure and application automation

---

## 🚧 Future Improvements

Future versions of the project can include:

* Dynamic Ansible inventory from Terraform
* Docker Compose deployment
* Ansible roles
* Environment variables and secrets management
* Docker Hub authentication
* Health checks
* Automatic rollback
* Prometheus and Grafana monitoring
* Separate development and production environments
* Full Terraform → Ansible → Docker GitHub Actions pipeline

