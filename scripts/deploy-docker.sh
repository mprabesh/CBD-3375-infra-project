#!/bin/bash

# Docker Deployment Script for 3-Tier Architecture
# VM1: React App (Frontend) - Port 80
# VM2: Node.js API (Backend) - Port 3000  
# VM3: PostgreSQL Database - Port 5432

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Function to show usage
show_usage() {
    echo "🚀 Docker Deployment Script for 3-Tier Architecture"
    echo "=================================================="
    echo ""
    echo "Architecture:"
    echo "  VM1: React App (Frontend) → Port 80"
    echo "  VM2: Node.js API (Backend) → Port 3000"
    echo "  VM3: PostgreSQL Database → Port 5432"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Required Options:"
    echo "  -w, --web-ip WEB_IP           Web VM public IP address"
    echo "  -b, --backend-ip BACKEND_IP   Backend VM private IP address"
    echo "  -d, --database-ip DB_IP       Database VM private IP address"
    echo "  -k, --key-vault VAULT_NAME    Azure Key Vault name"
    echo ""
    echo "Optional Docker Images:"
    echo "  --web-image IMAGE             Frontend image (default: nginx:latest)"
    echo "                                Examples: nginx:alpine, httpd:latest, my-react-app:v1.0"
    echo "  --backend-image IMAGE         Backend image (default: node:18-alpine)"
    echo "                                Examples: node:16, node:20-slim, my-node-api:v2.0"
    echo "  --database-image IMAGE        Database image (default: postgres:15)"
    echo "                                Examples: postgres:14, mysql:8.0, my-postgres:v1.0"
    echo ""
    echo "Other Options:"
    echo "  --from-terraform              Extract IPs from terraform output"
    echo "  --ssh-web                     SSH to Web VM only"
    echo "  --ssh-backend                 SSH to Backend VM via Web VM (jump)"
    echo "  --ssh-database                SSH to Database VM via Web VM (jump)"
    echo "  --deploy                      Deploy Docker containers (default action)"
    echo "  -h, --help                    Show this help message"
    echo ""
    echo "Examples:"
    echo "  # Basic deployment with default images:"
    echo "  $0 -w 20.1.2.3 -b 10.0.2.4 -d 10.0.2.5 -k my-keyvault"
    echo ""
    echo "  # SSH to Web VM:"
    echo "  $0 -w 20.1.2.3 -k my-keyvault --ssh-web"
    echo ""
    echo "  # SSH to Backend VM via Web VM:"
    echo "  $0 -w 20.1.2.3 -b 10.0.2.4 -k my-keyvault --ssh-backend"
    echo ""
    echo "  # SSH to Database VM via Web VM:"
    echo "  $0 -w 20.1.2.3 -d 10.0.2.5 -k my-keyvault --ssh-database"
    echo ""
    echo "  # Deploy with Terraform-extracted IPs:"
    echo "  $0 --from-terraform --deploy"
    echo ""
    echo "  # Custom Docker images:"
    echo "  $0 -w 20.1.2.3 -b 10.0.2.4 -d 10.0.2.5 -k my-keyvault \\"
    echo "     --web-image nginx:alpine \\"
    echo "     --backend-image node:16-slim \\"
    echo "     --database-image postgres:14"
    echo ""
}

# Default Docker images
WEB_IMAGE="nginx:latest"              # Frontend web server
BACKEND_IMAGE="node:18-alpine"        # Node.js API backend  
DATABASE_IMAGE="postgres:15"          # PostgreSQL database

# You can override these with command line arguments:
# --web-image, --backend-image, --database-image

# SSH options
SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=30 -o UserKnownHostsFile=/dev/null"
SSH_USER="sevastopol"

# Action to perform
ACTION="deploy"  # default action

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -w|--web-ip)
            WEB_IP="$2"
            shift 2
            ;;
        -b|--backend-ip)
            BACKEND_IP="$2"
            shift 2
            ;;
        -d|--database-ip)
            DATABASE_IP="$2"
            shift 2
            ;;
        -k|--key-vault)
            KEY_VAULT="$2"
            shift 2
            ;;
        --web-image)
            WEB_IMAGE="$2"
            shift 2
            ;;
        --backend-image)
            BACKEND_IMAGE="$2"
            shift 2
            ;;
        --database-image)
            DATABASE_IMAGE="$2"
            shift 2
            ;;
        --from-terraform)
            FROM_TERRAFORM=true
            shift
            ;;
        --ssh-web)
            ACTION="ssh-web"
            shift
            ;;
        --ssh-backend)
            ACTION="ssh-backend"
            shift
            ;;
        --ssh-database)
            ACTION="ssh-database"
            shift
            ;;
        --deploy)
            ACTION="deploy"
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

# Extract from Terraform if requested
if [[ "$FROM_TERRAFORM" == "true" ]]; then
    extract_from_terraform
fi

# Validate required parameters based on action
case $ACTION in
    "ssh-web")
        if [[ -z "$WEB_IP" || -z "$KEY_VAULT" ]]; then
            print_error "Missing required parameters for SSH to Web VM!"
            echo ""
            echo "Required for --ssh-web:"
            echo "  Web IP: ${WEB_IP:-'NOT SET'}"
            echo "  Key Vault: ${KEY_VAULT:-'NOT SET'}"
            echo ""
            show_usage
            exit 1
        fi
        ;;
    "ssh-backend")
        if [[ -z "$WEB_IP" || -z "$BACKEND_IP" || -z "$KEY_VAULT" ]]; then
            print_error "Missing required parameters for SSH to Backend VM!"
            echo ""
            echo "Required for --ssh-backend:"
            echo "  Web IP: ${WEB_IP:-'NOT SET'} (jump host)"
            echo "  Backend IP: ${BACKEND_IP:-'NOT SET'}"
            echo "  Key Vault: ${KEY_VAULT:-'NOT SET'}"
            echo ""
            show_usage
            exit 1
        fi
        ;;
    "ssh-database")
        if [[ -z "$WEB_IP" || -z "$DATABASE_IP" || -z "$KEY_VAULT" ]]; then
            print_error "Missing required parameters for SSH to Database VM!"
            echo ""
            echo "Required for --ssh-database:"
            echo "  Web IP: ${WEB_IP:-'NOT SET'} (jump host)"
            echo "  Database IP: ${DATABASE_IP:-'NOT SET'}"
            echo "  Key Vault: ${KEY_VAULT:-'NOT SET'}"
            echo ""
            show_usage
            exit 1
        fi
        ;;
    "deploy")
        if [[ -z "$WEB_IP" || -z "$BACKEND_IP" || -z "$DATABASE_IP" || -z "$KEY_VAULT" ]]; then
            print_error "Missing required parameters for deployment!"
            echo ""
            echo "Required for --deploy:"
            echo "  Web IP: ${WEB_IP:-'NOT SET'}"
            echo "  Backend IP: ${BACKEND_IP:-'NOT SET'}"
            echo "  Database IP: ${DATABASE_IP:-'NOT SET'}"
            echo "  Key Vault: ${KEY_VAULT:-'NOT SET'}"
            echo ""
            show_usage
            exit 1
        fi
        ;;
esac

# Display configuration
case $ACTION in
    "ssh-web")
        print_status "SSH Connection Configuration (Web VM):"
        echo "  Web VM IP: $WEB_IP"
        echo "  Key Vault: $KEY_VAULT"
        ;;
    "ssh-backend")
        print_status "SSH Connection Configuration (Backend VM via Jump Host):"
        echo "  Web VM IP: $WEB_IP (jump host)"
        echo "  Backend VM IP: $BACKEND_IP"
        echo "  Key Vault: $KEY_VAULT"
        ;;
    "ssh-database")
        print_status "SSH Connection Configuration (Database VM via Jump Host):"
        echo "  Web VM IP: $WEB_IP (jump host)"
        echo "  Database VM IP: $DATABASE_IP"
        echo "  Key Vault: $KEY_VAULT"
        ;;
    "deploy")
        print_status "Docker Deployment Configuration:"
        echo "  Web VM IP: $WEB_IP"
        echo "  Backend VM IP: $BACKEND_IP"
        echo "  Database VM IP: $DATABASE_IP"
        echo "  Key Vault: $KEY_VAULT"
        echo "  Web Image: $WEB_IMAGE"
        echo "  Backend Image: $BACKEND_IMAGE"
        echo "  Database Image: $DATABASE_IMAGE"
        ;;
esac
echo ""

# Function to download SSH key
download_ssh_key() {
    print_status "Downloading SSH key from Azure Key Vault..."
    
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI not found. Please install Azure CLI."
        exit 1
    fi
    
    # Check if logged in
    if ! az account show &> /dev/null; then
        print_error "Not logged into Azure. Please run 'az login' first."
        exit 1
    fi
    
    # Download SSH key
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
}

# Function to test SSH connection
test_ssh_connection() {
    local vm_ip=$1
    local vm_name=$2
    
    print_status "Testing SSH connection to $vm_name ($vm_ip)..."
    
    if ssh -i temp-ssh-key.pem $SSH_OPTS $SSH_USER@$vm_ip "echo 'SSH connection successful'" &> /dev/null; then
        print_success "SSH connection to $vm_name successful"
        return 0
    else
        print_error "SSH connection to $vm_name failed"
        return 1
    fi
}

# Function to SSH into Web VM
ssh_to_web_vm() {
    print_header "🌐 SSH CONNECTION TO WEB VM"
    
    print_status "Connecting to Web VM ($WEB_IP)..."
    print_status "To exit the SSH session, type 'exit' or press Ctrl+D"
    echo ""
    
    # Connect to web VM
    ssh -i temp-ssh-key.pem $SSH_OPTS $SSH_USER@$WEB_IP
    
    print_success "SSH session to Web VM ended"
}

# Function to SSH into Backend VM via jump host
ssh_to_backend_vm() {
    print_header "⚙️ SSH CONNECTION TO BACKEND VM (VIA JUMP HOST)"
    
    print_status "Setting up jump host connection..."
    
    # First copy the SSH key to the web VM for jump host access
    print_status "Copying SSH key to jump host..."
    scp -i temp-ssh-key.pem $SSH_OPTS temp-ssh-key.pem $SSH_USER@$WEB_IP:~/jump-key.pem
    
    # Set proper permissions on the jump host
    ssh -i temp-ssh-key.pem $SSH_OPTS $SSH_USER@$WEB_IP "chmod 600 ~/jump-key.pem"
    
    print_status "Connecting to Backend VM ($BACKEND_IP) via Web VM ($WEB_IP)..."
    print_status "To exit the SSH session, type 'exit' or press Ctrl+D"
    echo ""
    
    # Connect via jump host
    ssh -i temp-ssh-key.pem $SSH_OPTS $SSH_USER@$WEB_IP \
        -t "ssh -i ~/jump-key.pem $SSH_OPTS $SSH_USER@$BACKEND_IP; rm ~/jump-key.pem"
    
    print_success "SSH session to Backend VM ended"
}

# Function to SSH into Database VM via jump host  
ssh_to_database_vm() {
    print_header "🗄️ SSH CONNECTION TO DATABASE VM (VIA JUMP HOST)"
    
    print_status "Setting up jump host connection..."
    
    # First copy the SSH key to the web VM for jump host access
    print_status "Copying SSH key to jump host..."
    scp -i temp-ssh-key.pem $SSH_OPTS temp-ssh-key.pem $SSH_USER@$WEB_IP:~/jump-key.pem
    
    # Set proper permissions on the jump host
    ssh -i temp-ssh-key.pem $SSH_OPTS $SSH_USER@$WEB_IP "chmod 600 ~/jump-key.pem"
    
    print_status "Connecting to Database VM ($DATABASE_IP) via Web VM ($WEB_IP)..."
    print_status "To exit the SSH session, type 'exit' or press Ctrl+D"
    echo ""
    
    # Connect via jump host
    ssh -i temp-ssh-key.pem $SSH_OPTS $SSH_USER@$WEB_IP \
        -t "ssh -i ~/jump-key.pem $SSH_OPTS $SSH_USER@$DATABASE_IP; rm ~/jump-key.pem"
    
    print_success "SSH session to Database VM ended"
}

# Function to deploy to web VM (React Frontend)
deploy_web_vm() {
    print_header "🌐 DEPLOYING REACT FRONTEND (VM1)"
    
    if ! test_ssh_connection "$WEB_IP" "Web VM"; then
        return 1
    fi
    
    print_status "Deploying React app container on VM1..."
    
    ssh -i temp-ssh-key.pem $SSH_OPTS $SSH_USER@$WEB_IP << EOF
        echo "🐳 Pulling Docker image: $WEB_IMAGE"
        sudo docker pull $WEB_IMAGE
        
        echo "🛑 Stopping existing frontend container..."
        sudo docker stop react-frontend 2>/dev/null || echo "No existing react-frontend container"
        sudo docker rm react-frontend 2>/dev/null || echo "No existing react-frontend container to remove"
        
        echo "🚀 Starting React frontend container..."
        sudo docker run -d \
            --name react-frontend \
            --restart unless-stopped \
            -p 80:80 \
            -p 443:443 \
            -e REACT_APP_API_URL="http://$BACKEND_IP:3000" \
            $WEB_IMAGE
        
        echo "✅ React frontend deployed successfully"
        echo "📊 Container status:"
        sudo docker ps | grep react-frontend || echo "Container not found"
        
        echo "🌐 Frontend accessible at: http://$WEB_IP"
EOF
    
    if [[ $? -eq 0 ]]; then
        print_success "React Frontend (VM1) deployed successfully"
    else
        print_error "Failed to deploy React Frontend (VM1)"
        return 1
    fi
}

# Function to deploy to backend VM (Node.js API)
deploy_backend_vm() {
    print_header "⚙️ DEPLOYING NODE.JS API (VM2)"
    
    print_status "Deploying Node.js API via Web VM as jump host..."
    
    # Copy SSH key to web VM for jump host access
    scp -i temp-ssh-key.pem $SSH_OPTS temp-ssh-key.pem $SSH_USER@$WEB_IP:~/backend-key.pem
    
    ssh -i temp-ssh-key.pem $SSH_OPTS $SSH_USER@$WEB_IP << EOF
        chmod 600 ~/backend-key.pem
        
        echo "🐳 Deploying Node.js API to VM2 via jump host..."
        ssh -i ~/backend-key.pem $SSH_OPTS $SSH_USER@$BACKEND_IP << 'BACKEND_EOF'
            echo "🐳 Pulling Docker image: $BACKEND_IMAGE"
            sudo docker pull $BACKEND_IMAGE
            
            echo "🛑 Stopping existing API container..."
            sudo docker stop nodejs-api 2>/dev/null || echo "No existing nodejs-api container"
            sudo docker rm nodejs-api 2>/dev/null || echo "No existing nodejs-api container to remove"
            
            echo "🚀 Starting Node.js API container..."
            sudo docker run -d \
                --name nodejs-api \
                --restart unless-stopped \
                -p 3000:3000 \
                -e NODE_ENV=production \
                -e DB_HOST=$DATABASE_IP \
                -e DB_PORT=5432 \
                -e DB_NAME=appdb \
                -e DB_USER=appuser \
                -e DB_PASSWORD=securepass123 \
                -e API_PORT=3000 \
                $BACKEND_IMAGE
            
            echo "✅ Node.js API deployed successfully"
            echo "📊 Container status:"
            sudo docker ps | grep nodejs-api || echo "Container not found"
            
            echo "⚙️ API accessible at: http://$BACKEND_IP:3000"
BACKEND_EOF
        
        # Clean up SSH key
        rm ~/backend-key.pem
EOF
    
    if [[ $? -eq 0 ]]; then
        print_success "Node.js API (VM2) deployed successfully"
    else
        print_error "Failed to deploy Node.js API (VM2)"
        return 1
    fi
}

# Function to deploy to database VM (PostgreSQL)
deploy_database_vm() {
    print_header "🗄️ DEPLOYING POSTGRESQL DATABASE (VM3)"
    
    print_status "Deploying PostgreSQL database via Web VM as jump host..."
    
    # Copy SSH key to web VM for jump host access
    scp -i temp-ssh-key.pem $SSH_OPTS temp-ssh-key.pem $SSH_USER@$WEB_IP:~/database-key.pem
    
    ssh -i temp-ssh-key.pem $SSH_OPTS $SSH_USER@$WEB_IP << EOF
        chmod 600 ~/database-key.pem
        
        echo "🗄️ Deploying PostgreSQL to VM3 via jump host..."
        ssh -i ~/database-key.pem $SSH_OPTS $SSH_USER@$DATABASE_IP << 'DATABASE_EOF'
            echo "🐳 Pulling Docker image: $DATABASE_IMAGE"
            sudo docker pull $DATABASE_IMAGE
            
            echo "🛑 Stopping existing database container..."
            sudo docker stop postgresql-db 2>/dev/null || echo "No existing postgresql-db container"
            sudo docker rm postgresql-db 2>/dev/null || echo "No existing postgresql-db container to remove"
            
            echo "📁 Creating database volume..."
            sudo docker volume create postgres_data 2>/dev/null || echo "Volume already exists"
            
            echo "🚀 Starting PostgreSQL database container..."
            sudo docker run -d \
                --name postgresql-db \
                --restart unless-stopped \
                -p 5432:5432 \
                -e POSTGRES_DB=appdb \
                -e POSTGRES_USER=appuser \
                -e POSTGRES_PASSWORD=securepass123 \
                -e PGDATA=/var/lib/postgresql/data/pgdata \
                -v postgres_data:/var/lib/postgresql/data \
                $DATABASE_IMAGE
            
            echo "⏳ Waiting for database to initialize..."
            sleep 10
            
            echo "✅ PostgreSQL database deployed successfully"
            echo "📊 Container status:"
            sudo docker ps | grep postgresql-db || echo "Container not found"
            
            echo "🗄️ Database accessible at: $DATABASE_IP:5432"
            echo "   Database: appdb"
            echo "   User: appuser"
DATABASE_EOF
        
        # Clean up SSH key
        rm ~/database-key.pem
EOF
    
    if [[ $? -eq 0 ]]; then
        print_success "PostgreSQL Database (VM3) deployed successfully"
    else
        print_error "Failed to deploy PostgreSQL Database (VM3)"
        return 1
    fi
}

# Function to verify all deployments
verify_deployments() {
    print_header "🔍 VERIFYING DEPLOYMENTS"
    
    local all_success=true
    
    # Verify Web VM
    print_status "Checking React Frontend (VM1)..."
    if ssh -i temp-ssh-key.pem $SSH_OPTS $SSH_USER@$WEB_IP "sudo docker ps | grep react-frontend" &> /dev/null; then
        print_success "✅ React Frontend is running"
        
        # Test HTTP response
        if curl -f -s -o /dev/null --connect-timeout 10 http://$WEB_IP; then
            print_success "✅ React Frontend is responding to HTTP requests"
        else
            print_warning "⚠️ React Frontend not responding to HTTP requests"
        fi
    else
        print_error "❌ React Frontend container not running"
        all_success=false
    fi
    
    # Verify Backend VM
    print_status "Checking Node.js API (VM2)..."
    if ssh -i temp-ssh-key.pem $SSH_OPTS $SSH_USER@$WEB_IP \
        "ssh -i ~/backend-key.pem $SSH_OPTS $SSH_USER@$BACKEND_IP 'sudo docker ps | grep nodejs-api'" &> /dev/null 2>&1; then
        print_success "✅ Node.js API is running"
        
        # Test API response
        if ssh -i temp-ssh-key.pem $SSH_OPTS $SSH_USER@$WEB_IP \
            "curl -f -s -o /dev/null --connect-timeout 10 http://$BACKEND_IP:3000" &> /dev/null; then
            print_success "✅ Node.js API is responding"
        else
            print_warning "⚠️ Node.js API not responding (this is normal if no health endpoint exists)"
        fi
    else
        print_error "❌ Node.js API container not running"
        all_success=false
    fi
    
    # Verify Database VM
    print_status "Checking PostgreSQL Database (VM3)..."
    if ssh -i temp-ssh-key.pem $SSH_OPTS $SSH_USER@$WEB_IP \
        "ssh -i ~/database-key.pem $SSH_OPTS $SSH_USER@$DATABASE_IP 'sudo docker ps | grep postgresql-db'" &> /dev/null 2>&1; then
        print_success "✅ PostgreSQL Database is running"
        
        # Test database connection
        if ssh -i temp-ssh-key.pem $SSH_OPTS $SSH_USER@$WEB_IP \
            "ssh -i ~/database-key.pem $SSH_OPTS $SSH_USER@$DATABASE_IP 'sudo docker exec postgresql-db pg_isready -U appuser'" &> /dev/null; then
            print_success "✅ PostgreSQL Database is accepting connections"
        else
            print_warning "⚠️ PostgreSQL Database not ready yet (may need more time to initialize)"
        fi
    else
        print_error "❌ PostgreSQL Database container not running"
        all_success=false
    fi
    
    if $all_success; then
        print_success "🎉 All deployments verified successfully!"
    else
        print_error "⚠️ Some deployments have issues. Check the logs above."
    fi
}

# Function to show deployment summary
show_summary() {
    print_header "📋 DEPLOYMENT SUMMARY"
    
    echo "🏗️ 3-Tier Architecture Deployed:"
    echo "   ┌─────────────────────────────────┐"
    echo "   │         Internet                │"
    echo "   └─────────────┬───────────────────┘"
    echo "                 │"
    echo "       ┌─────────▼─────────┐"
    echo "       │ VM1: React App    │ → http://$WEB_IP"
    echo "       │ Port 80/443       │"
    echo "       └─────────┬─────────┘"
    echo "                 │"
    echo "       ┌─────────▼─────────┐"
    echo "       │ VM2: Node.js API  │ → http://$BACKEND_IP:3000"
    echo "       │ Port 3000         │"
    echo "       └─────────┬─────────┘"
    echo "                 │"
    echo "       ┌─────────▼─────────┐"
    echo "       │ VM3: PostgreSQL   │ → $DATABASE_IP:5432"
    echo "       │ Port 5432         │"
    echo "       └───────────────────┘"
    echo ""
    echo "🌐 Access Points:"
    echo "   • Frontend: http://$WEB_IP"
    echo "   • API: http://$BACKEND_IP:3000 (internal)"
    echo "   • Database: $DATABASE_IP:5432 (internal)"
    echo ""
    echo "🐳 Docker Images Deployed:"
    echo "   • Frontend: $WEB_IMAGE"
    echo "   • Backend: $BACKEND_IMAGE"  
    echo "   • Database: $DATABASE_IMAGE"
    echo ""
    echo "🔧 Container Names:"
    echo "   • react-frontend (VM1)"
    echo "   • nodejs-api (VM2)"
    echo "   • postgresql-db (VM3)"
    echo ""
    echo "📊 Check container status:"
    echo "   ssh -i temp-ssh-key.pem $SSH_USER@$WEB_IP 'sudo docker ps'"
    echo ""
}

# Function to cleanup
cleanup() {
    print_status "🧹 Cleaning up temporary files..."
    rm -f temp-ssh-key.pem
    print_success "Cleanup completed"
}

# Main execution
main() {
    case $ACTION in
        "ssh-web")
            print_header "🚀 SSH CONNECTION TO WEB VM"
            echo "Connecting to Web VM for direct SSH access..."
            echo ""
            
            # Download SSH key
            download_ssh_key
            
            # SSH to web VM
            ssh_to_web_vm
            ;;
            
        "ssh-backend")
            print_header "🚀 SSH CONNECTION TO BACKEND VM"
            echo "Connecting to Backend VM via Web VM as jump host..."
            echo ""
            
            # Download SSH key
            download_ssh_key
            
            # SSH to backend VM via jump host
            ssh_to_backend_vm
            ;;
            
        "ssh-database")
            print_header "🚀 SSH CONNECTION TO DATABASE VM"
            echo "Connecting to Database VM via Web VM as jump host..."
            echo ""
            
            # Download SSH key
            download_ssh_key
            
            # SSH to database VM via jump host
            ssh_to_database_vm
            ;;
            
        "deploy")
            print_header "🚀 3-TIER DOCKER DEPLOYMENT SCRIPT"
            
            echo "Architecture: Internet → VM1(React) → VM2(Node.js) → VM3(PostgreSQL)"
            echo ""
            
            # Download SSH key
            download_ssh_key
            
            # Deploy in order: Database → Backend → Frontend
            print_status "🎯 Starting deployment in optimal order..."
            echo ""
            
            # Deploy database first (dependencies)
            if ! deploy_database_vm; then
                print_error "Database deployment failed. Aborting."
                cleanup
                exit 1
            fi
            
            echo ""
            
            # Deploy backend second (depends on database)
            if ! deploy_backend_vm; then
                print_error "Backend deployment failed. Aborting."
                cleanup
                exit 1
            fi
            
            echo ""
            
            # Deploy frontend last (depends on backend)
            if ! deploy_web_vm; then
                print_error "Frontend deployment failed. Aborting."
                cleanup
                exit 1
            fi
            
            echo ""
            
            # Verify all deployments
            verify_deployments
            
            echo ""
            
            # Show summary
            show_summary
            
            print_success "🎉 3-Tier Architecture Deployment Complete!"
            ;;
            
        *)
            print_error "Unknown action: $ACTION"
            show_usage
            exit 1
            ;;
    esac
}

# Set trap for cleanup on script exit
trap cleanup EXIT

# Check if help is requested
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_usage
    exit 0
fi

# Run main function
main
    scp -i temp-ssh-key.pem $SSH_OPTS temp-ssh-key.pem $SSH_USER@$WEB_IP:~/database-key.pem
    
    ssh -i temp-ssh-key.pem $SSH_OPTS $SSH_USER@$WEB_IP << EOF
        chmod 600 ~/database-key.pem
        
        echo "🗄️ Deploying to database VM via jump host..."
        ssh -i ~/database-key.pem $SSH_OPTS $SSH_USER@$DATABASE_IP << 'DATABASE_EOF'
            echo "🐳 Pulling Docker image: $DATABASE_IMAGE"
            sudo docker pull $DATABASE_IMAGE
            
            echo "🛑 Stopping existing containers..."
            sudo docker stop database-app 2>/dev/null || echo "No existing database-app container"
            sudo docker rm database-app 2>/dev/null || echo "No existing database-app container to remove"
            
            echo "🚀 Starting new database container..."
            sudo docker run -d \
                --name database-app \
                --restart unless-stopped \
                -p 5432:5432 \
                -e POSTGRES_DB=appdb \
                -e POSTGRES_USER=appuser \
                -e POSTGRES_PASSWORD=securepass123 \
                -v postgres_data:/var/lib/postgresql/data \
                $DATABASE_IMAGE
            
            echo "✅ Database deployed successfully"
            echo "📊 Container status:"
            sudo docker ps | grep database-app || echo "Container not found"
DATABASE_EOF
        
        # Clean up SSH key
        rm ~/database-key.pem
EOF
    
    if [[ $? -eq 0 ]]; then
        print_success "Database VM deployment completed"
    else
        print_error "Database VM deployment failed"
        return 1
    fi
}

# Function to verify deployments
verify_deployments() {
    print_status "🔍 Verifying all deployments..."
    
    echo ""
    echo "📊 Web VM Status:"
    ssh -i temp-ssh-key.pem $SSH_OPTS $SSH_USER@$WEB_IP \
        "sudo docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
    
    echo ""
    echo "📊 Backend VM Status (via jump host):"
    ssh -i temp-ssh-key.pem $SSH_OPTS $SSH_USER@$WEB_IP \
        "ssh -i ~/backend-key.pem $SSH_OPTS $SSH_USER@$BACKEND_IP 'sudo docker ps --format \"table {{.Names}}\t{{.Status}}\t{{.Ports}}\"' 2>/dev/null || echo 'Backend check failed'"
    
    echo ""
    echo "📊 Database VM Status (via jump host):"
    ssh -i temp-ssh-key.pem $SSH_OPTS $SSH_USER@$WEB_IP \
        "ssh -i ~/database-key.pem $SSH_OPTS $SSH_USER@$DATABASE_IP 'sudo docker ps --format \"table {{.Names}}\t{{.Status}}\t{{.Ports}}\"' 2>/dev/null || echo 'Database check failed'"
}

# Function to test connectivity
test_connectivity() {
    print_status "🌐 Testing application connectivity..."
    
    echo "Testing Web Application..."
    if curl -f -s -o /dev/null --max-time 10 http://$WEB_IP; then
        print_success "Web app responding on http://$WEB_IP"
    else
        print_warning "Web app not responding (may take time to start)"
    fi
    
    echo "Testing Backend API (via web VM)..."
    ssh -i temp-ssh-key.pem $SSH_OPTS $SSH_USER@$WEB_IP \
        "curl -f -s -o /dev/null --max-time 10 http://$BACKEND_IP:3000/health && echo '✅ Backend API responding' || echo '❌ Backend API not responding (may take time to start)'"
}

# Function to cleanup
cleanup() {
    if [[ -f "temp-ssh-key.pem" ]]; then
        rm -f temp-ssh-key.pem
        print_status "🧹 SSH key cleaned up"
    fi
}

# Set trap for cleanup on script exit
trap cleanup EXIT

# Check if help is requested
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_usage
    exit 0
fi

# Run main function
main
