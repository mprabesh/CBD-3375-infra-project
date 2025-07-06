#!/bin/bash

# Docker Deployment Verification Script
# This script helps you verify that the deploy-docker.sh script ran successfully

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${PURPLE}================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}================================${NC}"
}

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✅ SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠️  WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[❌ ERROR]${NC} $1"
}

show_usage() {
    echo "🔍 Docker Deployment Verification Script"
    echo "======================================="
    echo ""
    echo "This script verifies that your Docker containers are running correctly"
    echo "after running the deploy-docker.sh script."
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -w, --web-ip WEB_IP           Web VM public IP address"
    echo "  -k, --key-vault VAULT_NAME    Azure Key Vault name"
    echo "  --from-terraform              Extract IPs from terraform output"
    echo "  -h, --help                    Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -w 20.1.2.3 -k my-keyvault"
    echo "  $0 --from-terraform"
    echo ""
}

# Default values
SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=30 -o UserKnownHostsFile=/dev/null"
SSH_USER="sevastopol"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -w|--web-ip)
            WEB_IP="$2"
            shift 2
            ;;
        -k|--key-vault)
            KEY_VAULT="$2"
            shift 2
            ;;
        --from-terraform)
            FROM_TERRAFORM=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Function to extract from Terraform outputs
extract_from_terraform() {
    print_status "Extracting values from Terraform outputs..."
    
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform not found. Please install Terraform or provide IPs manually."
        exit 1
    fi
    
    if ! terraform output &> /dev/null; then
        print_error "No Terraform outputs found. Please run 'terraform apply' first."
        exit 1
    fi
    
    WEB_IP=$(terraform output -raw web_vm_public_ip 2>/dev/null || echo "")
    BACKEND_IP=$(terraform output -raw backend_vm_private_ip 2>/dev/null || echo "")
    DATABASE_IP=$(terraform output -raw database_vm_private_ip 2>/dev/null || echo "")
    KEY_VAULT=$(terraform output -raw key_vault_name 2>/dev/null || echo "")
    
    print_success "Extracted values from Terraform outputs"
}

# Extract from terraform if requested
if [[ "$FROM_TERRAFORM" == true ]]; then
    extract_from_terraform
fi

# Validate required parameters
if [[ -z "$WEB_IP" || -z "$KEY_VAULT" ]]; then
    print_error "Missing required parameters!"
    echo ""
    echo "Required:"
    echo "  Web IP: ${WEB_IP:-'NOT SET'}"
    echo "  Key Vault: ${KEY_VAULT:-'NOT SET'}"
    echo ""
    show_usage
    exit 1
fi

# Download SSH key
print_status "Downloading SSH key from Azure Key Vault..."
if az keyvault secret download \
    --vault-name "$KEY_VAULT" \
    --name "cbd-3375-ssh-key-private" \
    --file "temp-ssh-key.pem" &> /dev/null; then
    chmod 600 temp-ssh-key.pem
    print_success "SSH key downloaded successfully"
else
    print_error "Failed to download SSH key from Key Vault: $KEY_VAULT"
    exit 1
fi

print_header "🔍 DEPLOYMENT VERIFICATION"

# Function to check script execution logs
check_deployment_logs() {
    print_status "Checking deployment logs on Web VM..."
    
    ssh -i temp-ssh-key.pem $SSH_OPTS $SSH_USER@$WEB_IP << 'EOF'
        echo "📋 Last deployment activities:"
        echo "=============================="
        
        # Check docker command history
        if [ -f ~/.bash_history ]; then
            echo "🐳 Recent Docker commands:"
            grep -E "(docker|pull|run)" ~/.bash_history | tail -10 2>/dev/null || echo "No Docker commands in history"
        fi
        
        # Check system logs for docker activities
        echo ""
        echo "📊 Docker system events (last 20):"
        sudo docker system events --since 1h --until now 2>/dev/null | tail -20 || echo "No recent Docker events"
        
        # Check running containers
        echo ""
        echo "🔍 Currently running containers:"
        sudo docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Image}}"
EOF
}

# Function to verify container status
verify_containers() {
    print_header "🐳 CONTAINER STATUS VERIFICATION"
    
    print_status "Checking containers on Web VM (VM1)..."
    ssh -i temp-ssh-key.pem $SSH_OPTS $SSH_USER@$WEB_IP << 'EOF'
        echo "📊 Web VM (VM1) Container Status:"
        echo "================================="
        
        if sudo docker ps | grep -q react-frontend; then
            echo "✅ React Frontend container is running"
            sudo docker ps | grep react-frontend
            
            # Check container logs
            echo ""
            echo "📋 Last 5 log entries:"
            sudo docker logs react-frontend --tail 5 2>/dev/null || echo "No logs available"
        else
            echo "❌ React Frontend container is NOT running"
            
            # Check if container exists but stopped
            if sudo docker ps -a | grep -q react-frontend; then
                echo "⚠️ Container exists but is stopped:"
                sudo docker ps -a | grep react-frontend
                echo ""
                echo "📋 Last log entries:"
                sudo docker logs react-frontend --tail 10 2>/dev/null || echo "No logs available"
            else
                echo "❌ No react-frontend container found"
            fi
        fi
EOF

    # Check backend via jump host
    print_status "Checking containers on Backend VM (VM2) via jump host..."
    ssh -i temp-ssh-key.pem $SSH_OPTS $SSH_USER@$WEB_IP << EOF
        if [ -f ~/backend-key.pem ]; then
            echo "📊 Backend VM (VM2) Container Status:"
            echo "===================================="
            
            ssh -i ~/backend-key.pem $SSH_OPTS $SSH_USER@$BACKEND_IP << 'BACKEND_EOF'
                if sudo docker ps | grep -q nodejs-api; then
                    echo "✅ Node.js API container is running"
                    sudo docker ps | grep nodejs-api
                    
                    echo ""
                    echo "📋 Last 5 log entries:"
                    sudo docker logs nodejs-api --tail 5 2>/dev/null || echo "No logs available"
                else
                    echo "❌ Node.js API container is NOT running"
                    
                    if sudo docker ps -a | grep -q nodejs-api; then
                        echo "⚠️ Container exists but is stopped:"
                        sudo docker ps -a | grep nodejs-api
                        echo ""
                        echo "📋 Last log entries:"
                        sudo docker logs nodejs-api --tail 10 2>/dev/null || echo "No logs available"
                    else
                        echo "❌ No nodejs-api container found"
                    fi
                fi
BACKEND_EOF
        else
            echo "⚠️ Backend SSH key not found - cannot check Backend VM"
        fi
EOF

    # Check database via jump host
    print_status "Checking containers on Database VM (VM3) via jump host..."
    ssh -i temp-ssh-key.pem $SSH_OPTS $SSH_USER@$WEB_IP << EOF
        if [ -f ~/database-key.pem ]; then
            echo "📊 Database VM (VM3) Container Status:"
            echo "====================================="
            
            ssh -i ~/database-key.pem $SSH_OPTS $SSH_USER@$DATABASE_IP << 'DATABASE_EOF'
                if sudo docker ps | grep -q postgresql-db; then
                    echo "✅ PostgreSQL Database container is running"
                    sudo docker ps | grep postgresql-db
                    
                    echo ""
                    echo "📋 Last 5 log entries:"
                    sudo docker logs postgresql-db --tail 5 2>/dev/null || echo "No logs available"
                    
                    echo ""
                    echo "🔍 Database connection test:"
                    sudo docker exec postgresql-db pg_isready -U appuser -d appdb 2>/dev/null && echo "✅ Database is ready" || echo "❌ Database not ready"
                else
                    echo "❌ PostgreSQL Database container is NOT running"
                    
                    if sudo docker ps -a | grep -q postgresql-db; then
                        echo "⚠️ Container exists but is stopped:"
                        sudo docker ps -a | grep postgresql-db
                        echo ""
                        echo "📋 Last log entries:"
                        sudo docker logs postgresql-db --tail 10 2>/dev/null || echo "No logs available"
                    else
                        echo "❌ No postgresql-db container found"
                    fi
                fi
DATABASE_EOF
        else
            echo "⚠️ Database SSH key not found - cannot check Database VM"
        fi
EOF
}

# Function to test connectivity
test_connectivity() {
    print_header "🌐 CONNECTIVITY TESTING"
    
    # Test web frontend
    print_status "Testing Web Frontend accessibility..."
    if curl -f -s -o /dev/null --connect-timeout 10 http://$WEB_IP; then
        print_success "✅ Web Frontend is accessible at http://$WEB_IP"
        
        # Get response headers
        echo "📊 Response details:"
        curl -I http://$WEB_IP 2>/dev/null | head -5 || echo "Could not get response headers"
    else
        print_error "❌ Web Frontend is not accessible at http://$WEB_IP"
    fi
    
    # Test backend API via web VM
    print_status "Testing Backend API accessibility via Web VM..."
    ssh -i temp-ssh-key.pem $SSH_OPTS $SSH_USER@$WEB_IP << EOF
        if curl -f -s -o /dev/null --connect-timeout 10 http://$BACKEND_IP:3000 2>/dev/null; then
            echo "✅ Backend API is accessible at http://$BACKEND_IP:3000"
            
            # Try to get API response
            echo "📊 API Response:"
            curl -s --connect-timeout 5 http://$BACKEND_IP:3000 2>/dev/null | head -3 || echo "No response body or timeout"
        else
            echo "❌ Backend API is not accessible at http://$BACKEND_IP:3000"
        fi
EOF
}

# Function to show deployment summary
show_summary() {
    print_header "📋 DEPLOYMENT SUMMARY"
    
    echo "Infrastructure Details:"
    echo "  Web VM: $WEB_IP"
    if [[ -n "$BACKEND_IP" ]]; then
        echo "  Backend VM: $BACKEND_IP"
    fi
    if [[ -n "$DATABASE_IP" ]]; then
        echo "  Database VM: $DATABASE_IP"
    fi
    echo "  Key Vault: $KEY_VAULT"
    echo ""
    
    echo "Access URLs:"
    echo "  🌐 Web Frontend: http://$WEB_IP"
    if [[ -n "$BACKEND_IP" ]]; then
        echo "  ⚙️ Backend API: http://$BACKEND_IP:3000 (internal)"
    fi
    if [[ -n "$DATABASE_IP" ]]; then
        echo "  🗄️ Database: $DATABASE_IP:5432 (internal)"
    fi
    echo ""
    
    echo "Manual verification commands:"
    echo "  # SSH to Web VM:"
    echo "  ssh -i temp-ssh-key.pem $SSH_USER@$WEB_IP"
    echo ""
    echo "  # Check all containers:"
    echo "  ssh -i temp-ssh-key.pem $SSH_USER@$WEB_IP 'sudo docker ps'"
    echo ""
    echo "  # View container logs:"
    echo "  ssh -i temp-ssh-key.pem $SSH_USER@$WEB_IP 'sudo docker logs react-frontend'"
}

# Main execution
main() {
    print_header "🚀 DOCKER DEPLOYMENT VERIFICATION"
    
    print_status "Starting verification process..."
    echo "Web VM: $WEB_IP"
    echo "Key Vault: $KEY_VAULT"
    echo ""
    
    # Run verification steps
    check_deployment_logs
    echo ""
    verify_containers
    echo ""
    test_connectivity
    echo ""
    show_summary
    
    print_success "🎉 Verification complete!"
}

# Cleanup function
cleanup() {
    rm -f temp-ssh-key.pem
    print_status "🧹 Cleanup completed"
}

# Set up cleanup trap
trap cleanup EXIT

# Run main function
main
