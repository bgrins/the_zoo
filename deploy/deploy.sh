#!/bin/bash
# The Zoo Multi-Host Deployment Script

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/terraform"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

function print_usage() {
    cat <<EOF
Usage: $0 [COMMAND] [OPTIONS]

Commands:
  deploy    Deploy a new Zoo instance
  destroy   Destroy a Zoo instance
  status    Check status of Zoo instance
  list      List all Zoo instances
  ssh       SSH into a Zoo instance

Options:
  -n, --name NAME           Instance name (default: the-zoo)
  -p, --project PROJECT     GCP project ID
  -r, --region REGION       GCP region (default: us-central1)
  -z, --zone ZONE          GCP zone (default: us-central1-a)
  -m, --machine TYPE       Machine type (default: e2-standard-2)
  -g, --github-repo REPO   GitHub repository URL
  -b, --branch BRANCH      Git branch (default: main)
  -i, --allowed-ips IPS    Comma-separated IPs for proxy access (default: 0.0.0.0/0)
  -h, --help               Show this help message

Examples:
  # Deploy a new instance
  $0 deploy -n my-zoo -p my-project -g https://github.com/user/the_zoo

  # Deploy multiple instances with different names
  $0 deploy -n zoo-dev -p my-project -g https://github.com/user/the_zoo
  $0 deploy -n zoo-test -p my-project -g https://github.com/user/the_zoo

  # Check status
  $0 status -n my-zoo -p my-project

  # Destroy an instance
  $0 destroy -n my-zoo -p my-project
EOF
}

function check_requirements() {
    local missing=()
    
    command -v terraform >/dev/null 2>&1 || missing+=("terraform")
    command -v gcloud >/dev/null 2>&1 || missing+=("gcloud")
    
    if [ ${#missing[@]} -ne 0 ]; then
        echo -e "${RED}Error: Missing required tools: ${missing[*]}${NC}"
        echo "Please install the missing tools and try again."
        exit 1
    fi
}

function deploy() {
    echo -e "${GREEN}Deploying Zoo instance: $INSTANCE_NAME${NC}"
    
    cd "$TERRAFORM_DIR"
    
    # Create terraform workspace for this instance
    terraform workspace select "$INSTANCE_NAME" 2>/dev/null || terraform workspace new "$INSTANCE_NAME"
    
    # Initialize Terraform
    terraform init
    
    # Create tfvars file
    cat > "$INSTANCE_NAME.tfvars" <<EOF
project_id    = "$PROJECT_ID"
region        = "$REGION"
zone          = "$ZONE"
instance_name = "$INSTANCE_NAME"
machine_type  = "$MACHINE_TYPE"
github_repo   = "$GITHUB_REPO"
github_branch = "$BRANCH"
allowed_ips   = [$(echo "$ALLOWED_IPS" | sed 's/,/", "/g' | sed 's/^/"/;s/$/"/')]
EOF
    
    # Apply Terraform
    terraform apply -var-file="$INSTANCE_NAME.tfvars" -auto-approve
    
    # Get instance IP
    INSTANCE_IP=$(terraform output -raw instance_ip)
    PROXY_URL=$(terraform output -raw proxy_url)
    
    echo -e "${GREEN}✓ Deployment complete!${NC}"
    echo -e "Instance IP: ${YELLOW}$INSTANCE_IP${NC}"
    echo -e "Proxy URL: ${YELLOW}$PROXY_URL${NC}"
    echo ""
    echo "To access Zoo domains, configure your browser to use proxy:"
    echo "  HTTP Proxy: $INSTANCE_IP"
    echo "  Port: 3128"
    echo ""
    echo "Test with: curl -k --proxy $PROXY_URL http://status.zoo"
}

function destroy() {
    echo -e "${YELLOW}Destroying Zoo instance: $INSTANCE_NAME${NC}"
    
    cd "$TERRAFORM_DIR"
    
    # Select workspace
    if ! terraform workspace select "$INSTANCE_NAME" 2>/dev/null; then
        echo -e "${RED}Instance $INSTANCE_NAME not found${NC}"
        exit 1
    fi
    
    # Destroy resources
    if [ -f "$INSTANCE_NAME.tfvars" ]; then
        terraform destroy -var-file="$INSTANCE_NAME.tfvars" -auto-approve
    else
        echo -e "${RED}Configuration file not found for $INSTANCE_NAME${NC}"
        exit 1
    fi
    
    # Delete workspace
    terraform workspace select default
    terraform workspace delete "$INSTANCE_NAME"
    
    # Clean up tfvars file
    rm -f "$INSTANCE_NAME.tfvars"
    
    echo -e "${GREEN}✓ Instance destroyed${NC}"
}

function status() {
    echo -e "${GREEN}Checking status of: $INSTANCE_NAME${NC}"
    
    gcloud compute instances describe "$INSTANCE_NAME" \
        --project="$PROJECT_ID" \
        --zone="$ZONE" \
        --format="table(name,status,networkInterfaces[0].accessConfigs[0].natIP)"
}

function list_instances() {
    echo -e "${GREEN}Listing all Zoo instances in project: $PROJECT_ID${NC}"
    
    gcloud compute instances list \
        --project="$PROJECT_ID" \
        --filter="tags.items=zoo-proxy" \
        --format="table(name,status,zone.basename(),networkInterfaces[0].accessConfigs[0].natIP)"
}

function ssh_instance() {
    echo -e "${GREEN}Connecting to: $INSTANCE_NAME${NC}"
    
    gcloud compute ssh "$INSTANCE_NAME" \
        --project="$PROJECT_ID" \
        --zone="$ZONE"
}

# Parse arguments
COMMAND=""
INSTANCE_NAME="the-zoo"
PROJECT_ID=""
REGION="us-central1"
ZONE="us-central1-a"
MACHINE_TYPE="e2-standard-2"
GITHUB_REPO=""
BRANCH="main"
ALLOWED_IPS="0.0.0.0/0"

if [ $# -eq 0 ]; then
    print_usage
    exit 0
fi

COMMAND=$1
shift

while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--name)
            INSTANCE_NAME="$2"
            shift 2
            ;;
        -p|--project)
            PROJECT_ID="$2"
            shift 2
            ;;
        -r|--region)
            REGION="$2"
            shift 2
            ;;
        -z|--zone)
            ZONE="$2"
            shift 2
            ;;
        -m|--machine)
            MACHINE_TYPE="$2"
            shift 2
            ;;
        -g|--github-repo)
            GITHUB_REPO="$2"
            shift 2
            ;;
        -b|--branch)
            BRANCH="$2"
            shift 2
            ;;
        -i|--allowed-ips)
            ALLOWED_IPS="$2"
            shift 2
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            print_usage
            exit 1
            ;;
    esac
done

# Check requirements
check_requirements

# Validate required parameters
if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}Error: Project ID is required${NC}"
    print_usage
    exit 1
fi

# Execute command
case $COMMAND in
    deploy)
        if [ -z "$GITHUB_REPO" ]; then
            echo -e "${RED}Error: GitHub repository URL is required for deployment${NC}"
            print_usage
            exit 1
        fi
        deploy
        ;;
    destroy)
        destroy
        ;;
    status)
        status
        ;;
    list)
        list_instances
        ;;
    ssh)
        ssh_instance
        ;;
    *)
        echo -e "${RED}Unknown command: $COMMAND${NC}"
        print_usage
        exit 1
        ;;
esac