#!/bin/bash

# GKE Deployment Script for Development Environment
set -e

echo "🚀 Starting GKE deployment process..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
print_status "Checking prerequisites..."

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    print_error "Terraform is not installed. Please install terraform first."
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    print_error "Helm is not installed. Please install helm first."
    exit 1
fi

# Check if gcloud is installed and authenticated
if ! command -v gcloud &> /dev/null; then
    print_error "gcloud CLI is not installed. Please install gcloud first."
    exit 1
fi

# Verify gcloud authentication
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n 1 &> /dev/null; then
    print_error "gcloud is not authenticated. Please run 'gcloud auth login' first."
    exit 1
fi

print_status "All prerequisites satisfied!"

# Navigate to terraform directory
cd terraform/

print_status "Initializing Terraform..."
terraform init

print_status "Planning Terraform deployment..."
terraform plan -out=tfplan

# Prompt for approval
echo ""
print_warning "Please review the above plan carefully."
read -p "Do you want to proceed with the deployment? (yes/no): " answer

if [[ "$answer" != "yes" ]]; then
    print_error "Deployment cancelled."
    rm -f tfplan
    exit 0
fi

print_status "Applying Terraform configuration..."
terraform apply tfplan

print_status "Cleaning up plan file..."
rm -f tfplan

print_status "Getting cluster credentials..."
PROJECT_ID=$(terraform output -raw project_id 2>/dev/null || echo "saral-458210")
REGION=$(terraform output -raw region 2>/dev/null || echo "asia-south1")
CLUSTER_NAME=$(terraform output -raw cluster_info 2>/dev/null | grep cluster_name | cut -d'"' -f4 || echo "dev-gke-cluster")

gcloud container clusters get-credentials "$CLUSTER_NAME" --region="$REGION" --project="$PROJECT_ID"

print_status "Verifying deployment..."
echo ""
echo "📊 Deployment Status:"
echo "===================="

# Check namespaces
echo "Namespaces:"
kubectl get namespaces | grep -E "(dev-apps|ingress-nginx|cert-manager|default)"

echo ""
echo "Services:"
kubectl get services -A | grep -E "(nginx-ingress|LoadBalancer|ClusterIP)"

echo ""
echo "Ingresses:"
kubectl get ingresses -A

echo ""
echo "Pods:"
kubectl get pods -A | grep -v -E "(kube-system|gke-system)"

# Get external IP
echo ""
print_status "Getting external IP address..."
EXTERNAL_IP=""
while [[ -z "$EXTERNAL_IP" ]]; do
    print_warning "Waiting for LoadBalancer IP..."
    sleep 10
    EXTERNAL_IP=$(kubectl get svc -n ingress-nginx -o jsonpath='{.items[?(@.spec.type=="LoadBalancer")].status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
done

echo ""
echo "🎉 Deployment completed successfully!"
echo "===================="
echo "External IP: $EXTERNAL_IP"
echo ""
echo "Next steps:"
echo "1. Update your DNS records to point to $EXTERNAL_IP"
echo "2. Wait for SSL certificates to be issued (may take a few minutes)"
echo "3. Access your applications using the configured hostnames"
echo ""
echo "Useful commands:"
echo "  kubectl get pods -A                    # Check all pods"
echo "  kubectl logs -f deployment/<name> -n <namespace>  # View logs"
echo "  kubectl describe ingress <name> -n <namespace>    # Check ingress"
echo "  kubectl get certificate -A             # Check SSL certificates"
echo ""
echo "Happy deploying! 🚀"


