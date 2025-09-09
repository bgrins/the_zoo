# The Zoo - Automated Multi-Host Deployment

This directory contains automated deployment scripts for The Zoo on GCP, allowing you to deploy multiple instances without manual SSH access.

## Prerequisites

1. **Local tools required:**
   - `terraform` (>= 1.0)
   - `gcloud` CLI configured with your GCP account
   - Git

2. **GCP requirements:**
   - GCP project with billing enabled
   - Compute Engine API enabled
   - Appropriate IAM permissions (Compute Admin, Service Account User)

3. **Package Registry:**
   - This deployment uses pre-built Docker images from GitHub Container Registry (ghcr.io/bgrins/the_zoo)
   - No local builds required - faster deployment!

## Quick Start

### 1. Deploy a single instance

```bash
# Deploy with minimal configuration
./deploy.sh deploy \
  -n my-zoo \
  -p my-gcp-project \
  -g https://github.com/yourusername/the_zoo

# Check status
./deploy.sh status -n my-zoo -p my-gcp-project

# Get proxy details
gcloud compute instances describe my-zoo \
  --project my-gcp-project \
  --zone us-central1-a \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)'
```

### 2. Deploy multiple instances

```bash
# Deploy development environment
./deploy.sh deploy \
  -n zoo-dev \
  -p my-project \
  -g https://github.com/yourusername/the_zoo \
  -b develop

# Deploy staging environment
./deploy.sh deploy \
  -n zoo-staging \
  -p my-project \
  -g https://github.com/yourusername/the_zoo \
  -b staging \
  -m e2-standard-4  # Larger instance for staging

# Deploy testing environment with IP restrictions
./deploy.sh deploy \
  -n zoo-test \
  -p my-project \
  -g https://github.com/yourusername/the_zoo \
  -i "203.0.113.0/32,198.51.100.0/24"  # Only specific IPs
```

## Using Terraform Directly

For more control, you can use Terraform directly:

```bash
cd terraform

# Initialize Terraform
terraform init

# Create workspace for each instance
terraform workspace new dev
terraform workspace select dev

# Copy and edit variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your settings

# Deploy
terraform plan
terraform apply

# Get outputs
terraform output instance_ip
terraform output proxy_url
```

## Using Pre-built Packages

The deployment automatically uses pre-built Docker images from GitHub Container Registry, which means:

- **No build time** - Containers start immediately with pulled images
- **Consistent versions** - All deployments use the same tested images
- **No Node.js required** - The VM doesn't need build dependencies

The `deploy/docker-compose.override.yaml` file configures Docker Compose to use these packages.

## Deployment Methods

### Method 1: Shell Script (Recommended)

The `deploy.sh` script provides a simple interface for managing instances:

```bash
# Commands available
./deploy.sh deploy   # Create new instance (uses packages)
./deploy.sh destroy  # Remove instance
./deploy.sh status   # Check instance status
./deploy.sh list     # List all Zoo instances
./deploy.sh ssh      # SSH into instance (for debugging)
```

### Method 2: CI/CD Pipeline

Example GitHub Actions workflow:

```yaml
name: Deploy Zoo Instance
on:
  push:
    branches: [main, develop]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - uses: hashicorp/setup-terraform@v2

      - uses: google-github-actions/auth@v1
        with:
          credentials_json: ${{ secrets.GCP_SA_KEY }}

      - name: Deploy Zoo
        run: |
          ./deploy/deploy.sh deploy \
            -n zoo-${{ github.ref_name }} \
            -p ${{ secrets.GCP_PROJECT }} \
            -g ${{ github.server_url }}/${{ github.repository }} \
            -b ${{ github.ref_name }}
```

### Method 3: Ansible Playbook

Create an Ansible playbook for managing multiple hosts:

```yaml
---
- name: Deploy The Zoo instances
  hosts: localhost
  vars:
    project_id: my-gcp-project
    github_repo: https://github.com/user/the_zoo
    instances:
      - name: zoo-dev
        branch: develop
        machine_type: e2-standard-2
      - name: zoo-staging
        branch: staging
        machine_type: e2-standard-4

  tasks:
    - name: Deploy instance
      shell: |
        ./deploy.sh deploy \
          -n {{ item.name }} \
          -p {{ project_id }} \
          -g {{ github_repo }} \
          -b {{ item.branch }} \
          -m {{ item.machine_type }}
      loop: "{{ instances }}"
```

## Configuration Management

### Environment Variables

Use `.env` files for managing configurations:

```bash
cp .env.example .env
# Edit .env with your settings

# Source environment before deploying
source .env
./deploy.sh deploy -n $INSTANCE_NAME -p $GCP_PROJECT_ID -g $GITHUB_REPO
```

### Terraform Workspaces

Each instance gets its own Terraform workspace:

```bash
# List all deployed instances
cd terraform
terraform workspace list

# Switch between instances
terraform workspace select zoo-dev
terraform output proxy_url
```

## Accessing Deployed Instances

### Configure Browser Proxy

1. Get the instance IP:
   ```bash
   ./deploy.sh status -n my-zoo -p my-project
   ```

2. Configure browser proxy settings:
   - HTTP Proxy: `<INSTANCE_IP>`
   - Port: `3128`
   - Use for all protocols

3. Access Zoo domains:
   - http://status.zoo
   - http://snappymail.zoo
   - Any configured .zoo domain

### Using curl

```bash
# Get proxy URL
PROXY_URL=$(gcloud compute instances describe my-zoo \
  --project=my-project \
  --zone=us-central1-a \
  --format='value(networkInterfaces[0].accessConfigs[0].natIP)')

# Test connection
curl -k --proxy http://$PROXY_URL:3128 http://status.zoo
```

## Monitoring & Logs

### View startup logs

```bash
# SSH into instance (if needed for debugging)
./deploy.sh ssh -n my-zoo -p my-project

# Check startup log
sudo tail -f /var/log/zoo-startup.log

# Check Docker logs (with package override)
cd /opt/zoo/the_zoo
docker compose -f docker-compose.yaml -f deploy/docker-compose.override.yaml logs -f
```

### Remote log collection

Set up Stackdriver logging in Terraform:

```hcl
# Add to main.tf
resource "google_compute_instance" "zoo" {
  # ... existing config ...
  
  metadata = {
    google-logging-enabled = "true"
  }
}
```

## Cleanup

### Remove single instance

```bash
./deploy.sh destroy -n my-zoo -p my-project
```

### Remove all instances

```bash
# List all instances
./deploy.sh list -p my-project

# Remove each
for instance in zoo-dev zoo-staging zoo-test; do
  ./deploy.sh destroy -n $instance -p my-project
done
```

### Clean Terraform state

```bash
cd terraform
terraform workspace select default
terraform workspace delete zoo-dev
rm -f *.tfvars
```

## Security Considerations

1. **Proxy Access**: Always restrict `allowed_ips` in production
2. **SSH Access**: Use IAP or remove SSH access after deployment
3. **Secrets**: Never commit `.env` or `terraform.tfvars` files
4. **Service Accounts**: Use dedicated service accounts with minimal permissions

## Troubleshooting

### Instance won't start

```bash
# Check cloud-init logs
gcloud compute instances get-serial-port-output my-zoo \
  --project=my-project --zone=us-central1-a
```

### Can't connect to proxy

```bash
# Verify firewall rule
gcloud compute firewall-rules describe zoo-proxy \
  --project=my-project

# Check instance status
./deploy.sh status -n my-zoo -p my-project
```

### Services not running

```bash
# SSH and check Docker
./deploy.sh ssh -n my-zoo -p my-project
docker compose ps
docker compose logs
```

## Advanced Usage

### Custom machine images

Build a custom image with Zoo pre-installed:

```bash
# Create image from running instance
gcloud compute images create zoo-base-image \
  --source-disk=my-zoo \
  --source-disk-zone=us-central1-a \
  --project=my-project

# Update terraform to use custom image
# In main.tf, change boot_disk.initialize_params.image
```

### Auto-scaling

For production use, consider using Instance Groups:

```hcl
# instance-group.tf
resource "google_compute_instance_template" "zoo" {
  # ... configuration ...
}

resource "google_compute_instance_group_manager" "zoo" {
  name               = "zoo-igm"
  base_instance_name = "zoo"
  target_size        = 2
  version {
    instance_template = google_compute_instance_template.zoo.id
  }
}
```

## Cost Optimization

- Use preemptible instances for development
- Set up instance scheduling to shut down during off-hours
- Use committed use discounts for long-running instances
- Clean up unused instances regularly
