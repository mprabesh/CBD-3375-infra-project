#!/bin/bash

################################################################################
#                          Hybrid Deployment Script                            #
#                                                                              #
# Description: This script deploys a 3-tier application architecture using    #
#              Docker for frontend and Git repository for backend.            #
#                                                                              #
# Usage: ./deploy-git-repos.sh [options]                                      #
#                                                                              #
# Options:                                                                     #
#   --frontend-image <image>    Docker image for frontend application         #
#   --backend-repo <url>        Git repository for backend API                #
#   --database-image <image>   MongoDB database image (still uses Docker) #
#   --help                      Display this help message                     #
#                                                                              #
# Prerequisites:                                                               #
#   - Azure CLI logged in                                                     #
#   - Terraform infrastructure deployed                                       #
#   - SSH key stored in Azure Key Vault                                      #
#                                                                              #
# Example:                                                                     #
#   ./deploy-git-repos.sh --frontend-image nginx:latest                      #
#                                                                              #
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Default configuration settings
FRONTEND_IMAGE="magarp0723/blogapp-frontend:v6"                 # Your custom frontend Docker image
BACKEND_REPO="https://github.com/mprabesh/blog-service.git"     # Node.js backend repo
DATABASE_IMAGE="mongo:7.0"                                     # MongoDB database

# Application directories
BACKEND_DIR="/opt/backend"

VM_USER="sevastopol"  # Default VM user for SSH access

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

print_error() {
    echo -e "${RED}[❌ ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠️  WARNING]${NC} $1"
}

# Function to display help
show_help() {
    cat << EOF
Hybrid Deployment Script for 3-Tier Architecture

This script deploys applications using Docker for frontend and Git repository for backend.

USAGE:
    $0 [OPTIONS]

OPTIONS:
    --frontend-image <image>     Docker image for frontend application
    --backend-repo <url>         Git repository URL for backend API  
    --database-image <img>       MongoDB Docker image (default: mongo:7.0)
    --help                       Show this help message

EXAMPLES:
    $0 --frontend-image nginx:latest
    $0 --backend-repo https://github.com/user/api-backend --database-image mongo:6.0
    $0 --help

PREREQUISITES:
    - Azure CLI logged in with valid credentials
    - Terraform infrastructure deployed and running
    - SSH private key available in Azure Key Vault
    - Docker installed on Web VM for frontend
    - Backend Git repository should contain package.json for Node.js app

For more information, see the deployment guide.
EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --frontend-image)
            FRONTEND_IMAGE="$2"
            shift 2
            ;;
        --backend-repo)
            BACKEND_REPO="$2"
            shift 2
            ;;
        --database-image)
            DATABASE_IMAGE="$2"
            shift 2
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Function to check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check if Azure CLI is installed and logged in
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed. Please install it first."
        exit 1
    fi
    
    if ! az account show &> /dev/null; then
        print_error "Not logged in to Azure. Please run 'az login' first."
        exit 1
    fi
    
    print_success "Azure CLI is installed and logged in"
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install it first."
        exit 1
    fi
    
    print_success "Terraform is installed"
    
    print_success "All prerequisites met"
}

# Function to get VM information from Terraform outputs
get_vm_info() {
    print_header "Getting VM Information from Terraform"
    
    if [ ! -f "terraform.tfstate" ]; then
        print_error "terraform.tfstate not found. Please run 'terraform apply' first."
        exit 1
    fi
    
    # Get VM public IPs and private IPs
    WEB_VM_PUBLIC_IP=$(terraform output -raw web_vm_public_ip 2>/dev/null || echo "")
    BACKEND_VM_PRIVATE_IP=$(terraform output -raw backend_vm_private_ip 2>/dev/null || echo "")
    DB_VM_PRIVATE_IP=$(terraform output -raw db_vm_private_ip 2>/dev/null || echo "")
    
    # Get resource group and key vault names
    RESOURCE_GROUP=$(terraform output -raw resource_group_name 2>/dev/null || echo "")
    KEY_VAULT_NAME=$(terraform output -raw key_vault_name 2>/dev/null || echo "")
    
    if [[ -z "$WEB_VM_PUBLIC_IP" || -z "$BACKEND_VM_PRIVATE_IP" || -z "$DB_VM_PRIVATE_IP" ]]; then
        print_error "Could not retrieve VM IP addresses from Terraform outputs"
        print_status "Available outputs:"
        terraform output
        exit 1
    fi
    
    print_success "VM Information Retrieved:"
    echo "  Web VM Public IP: $WEB_VM_PUBLIC_IP"
    echo "  Backend VM Private IP: $BACKEND_VM_PRIVATE_IP"
    echo "  Database VM Private IP: $DB_VM_PRIVATE_IP"
    echo "  Resource Group: $RESOURCE_GROUP"
    echo "  Key Vault: $KEY_VAULT_NAME"
}

# Function to get SSH private key from Azure Key Vault
get_ssh_key() {
    print_header "Retrieving SSH Private Key"

    SSH_KEY_FILE="./vm_ssh_key"

    if az keyvault secret show --name cbd-3375-ssh-key-private --vault-name "$KEY_VAULT_NAME" --query value -o tsv > "$SSH_KEY_FILE" 2>/dev/null; then
        chmod 600 "$SSH_KEY_FILE"
        print_success "SSH private key retrieved from Key Vault"
    else
        print_error "Failed to retrieve SSH private key from Key Vault"
        exit 1
    fi
}

# Function to test SSH connectivity
test_ssh_connectivity() {
    print_header "Testing SSH Connectivity"
    
    local vm_ip=$1
    local vm_name=$2
    
    if ssh -i "$SSH_KEY_FILE" -o StrictHostKeyChecking=no -o ConnectTimeout=10 $VM_USER@$vm_ip "echo 'SSH connection successful'" &>/dev/null; then
        print_success "SSH connection to $vm_name ($vm_ip) successful"
        return 0
    else
        print_error "SSH connection to $vm_name ($vm_ip) failed"
        return 1
    fi
}

# Function to install Node.js and npm on VM
install_nodejs() {
    local vm_ip=$1
    local vm_name=$2
    
    print_status "Installing Node.js and npm on $vm_name..."
    
    ssh -i "$SSH_KEY_FILE" -o StrictHostKeyChecking=no $VM_USER@$vm_ip << 'EOF'
        # Update package list
        sudo apt-get update
        
        # Install Node.js 18.x
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt-get install -y nodejs
        
        # Install build essentials for npm packages that need compilation
        sudo apt-get install -y build-essential
        
        # Install Git if not already installed
        sudo apt-get install -y git
        
        # Install PM2 for process management
        sudo npm install -g pm2
        
        echo "Node.js version: $(node --version)"
        echo "npm version: $(npm --version)"
EOF
    
    if [ $? -eq 0 ]; then
        print_success "Node.js and npm installed on $vm_name"
    else
        print_error "Failed to install Node.js on $vm_name"
        return 1
    fi
}

# Function to install Docker on web VM
install_docker_web() {
    local vm_ip=$1
    
    print_status "Installing Docker on Web VM..."
    
    ssh -i "$SSH_KEY_FILE" -o StrictHostKeyChecking=no $VM_USER@$vm_ip << 'EOF'
        # Update package list
        sudo apt-get update
        
        # Install required packages
        sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
        
        # Add Docker's official GPG key
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        
        # Set up Docker repository
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        # Update package list again
        sudo apt-get update
        
        # Install Docker
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io
        
        # Start and enable Docker
        sudo systemctl start docker
        sudo systemctl enable docker
        
        # Add user to docker group
        sudo usermod -aG docker $VM_USER
        
        echo "Docker version: $(sudo docker --version)"
EOF
    
    if [ $? -eq 0 ]; then
        print_success "Docker installed on Web VM"
    else
        print_error "Failed to install Docker on Web VM"
        return 1
    fi
}

# Function to deploy frontend application using Docker
deploy_frontend() {
    print_header "Deploying Frontend Application using Docker"
    
    print_status "Starting frontend container: $FRONTEND_IMAGE"
    
    ssh -i "$SSH_KEY_FILE" -o StrictHostKeyChecking=no $VM_USER@$WEB_VM_PUBLIC_IP << EOF
        # Stop and remove existing container if it exists
        sudo docker stop frontend-web 2>/dev/null || true
        sudo docker rm frontend-web 2>/dev/null || true

        # Pull the latest image
        sudo docker pull $FRONTEND_IMAGE

        # Run the frontend container with BACKEND_URL env
        sudo docker run -d \
            --name frontend-web \
            --restart unless-stopped \
            -p 80:80 \
            -e BACKEND_URL="http://$BACKEND_VM_PRIVATE_IP:3003" \
            $FRONTEND_IMAGE

        # Wait for container to start
        sleep 5

        # Check if container is running
        if sudo docker ps | grep -q frontend-web; then
            echo "Frontend container is running"
        else
            echo "Error: Frontend container failed to start"
            sudo docker logs frontend-web
            exit 1
        fi

        # Configure nginx proxy for API calls (add reverse proxy configuration)
        # Create a temporary nginx config for API proxying
        sudo docker exec frontend-web sh -c "
            # Check if nginx config directory exists
            if [ -d '/etc/nginx/conf.d' ]; then
                cat > /etc/nginx/conf.d/api-proxy.conf << 'NGINX_CONF'
# API proxy configuration
location /api {
    proxy_pass http://$BACKEND_VM_PRIVATE_IP:3000;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \\\$http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host \\\$host;
    proxy_cache_bypass \\\$http_upgrade;
    proxy_set_header X-Real-IP \\\$remote_addr;
    proxy_set_header X-Forwarded-For \\\$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \\\$scheme;
}
NGINX_CONF
                # Reload nginx if possible
                nginx -s reload 2>/dev/null || echo 'Note: Could not reload nginx config automatically'
            else
                echo 'Note: Nginx config directory not found, API proxy not configured'
            fi
        " || echo "Note: Could not configure API proxy automatically"

        echo "Frontend deployment completed"
EOF
    
    if [ $? -eq 0 ]; then
        print_success "Frontend Docker container deployed successfully"
        print_status "Frontend URL: http://$WEB_VM_PUBLIC_IP"
    else
        print_error "Failed to deploy frontend Docker container"
        return 1
    fi
}

# Function to deploy backend application from Git
deploy_backend() {
    print_header "Deploying Backend Application from Git Repository"
    
    print_status "Cloning backend repository: $BACKEND_REPO"
    
    ssh -i "$SSH_KEY_FILE" -o StrictHostKeyChecking=no $VM_USER@$WEB_VM_PUBLIC_IP << EOF
        # SSH to backend VM through bastion (web VM)
        ssh -i ~/.ssh/vm_key -o StrictHostKeyChecking=no $VM_USER@$BACKEND_VM_PRIVATE_IP << 'BACKEND_EOF'
            # Remove existing directory if it exists
            sudo rm -rf $BACKEND_DIR
            
            # Create application directory
            sudo mkdir -p $BACKEND_DIR
            sudo chown $VM_USER:$VM_USER $BACKEND_DIR
            
            # Clone the repository
            git clone $BACKEND_REPO $BACKEND_DIR
            
            # Navigate to backend directory
            cd $BACKEND_DIR
            
            # Install dependencies if package.json exists
            if [ -f "package.json" ]; then
                echo "Installing Node.js dependencies..."
                npm install
                
                # Create environment file
                cat > .env << 'ENV_EOF'
SECRET_KEY="appleisred"
PORT=3003
MONGO_URL="mongodb+srv://prabesh:prabesh@cluster0.e1nz5ox.mongodb.net/blog?retryWrites=true&w=majority&appName=Cluster0"
ENV_EOF
                
                # Seed the database if seedAll.js exists
                if [ -f "seedAll.js" ]; then
                    echo "Seeding the database with seedAll.js..."
                    node seedAll.js || echo "Warning: Database seeding failed or already seeded."
                fi

                # Stop any existing PM2 processes
                pm2 stop all || true
                pm2 delete all || true

                # Start the application with PM2
                if [ -f "index.js" ]; then
                    pm2 start index.js --name "backend-api"
                elif [ -f "server.js" ]; then
                    pm2 start server.js --name "backend-api"
                elif [ -f "app.js" ]; then
                    pm2 start app.js --name "backend-api"
                else
                    echo "No main file found, starting with npm start"
                    pm2 start npm --name "backend-api" -- start
                fi

                # Save PM2 configuration
                pm2 save
                pm2 startup

                echo "Backend deployment completed"
            else
                echo "Error: No package.json found in backend repository"
                exit 1
            fi
BACKEND_EOF
EOF
    
    if [ $? -eq 0 ]; then
        print_success "Backend application deployed successfully"
        print_status "Backend running on: http://$BACKEND_VM_PRIVATE_IP:3003"
    else
        print_error "Failed to deploy backend application"
        return 1
    fi
}

# Function to deploy database (MongoDB)
deploy_database() {
    print_header "Deploying MongoDB Database (Native Installation)"
    print_status "Installing MongoDB directly on the VM..."

    ssh -i "$SSH_KEY_FILE" -o StrictHostKeyChecking=no $VM_USER@$WEB_VM_PUBLIC_IP << EOF
        # SSH to database VM through bastion (web VM)
        ssh -i ~/.ssh/vm_key -o StrictHostKeyChecking=no $VM_USER@$DB_VM_PRIVATE_IP << 'DB_EOF'
            # Update package list
            sudo apt-get update

            # Import the public key used by the package management system
            wget -qO - https://www.mongodb.org/static/pgp/server-7.0.asc | sudo apt-key add -

            # Create the /etc/apt/sources.list.d/mongodb-org-7.0.list file for Ubuntu
            echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu \
                \\$(lsb_release -cs)/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list

            # Reload local package database
            sudo apt-get update

            # Install MongoDB packages
            sudo apt-get install -y mongodb-org


            # Bind MongoDB to both localhost and the VM's private IP
            DB_IP=$(hostname -I | awk '{print $1}')
            sudo sed -i "/^  bindIp:/c\  bindIp: 127.0.0.1,$DB_IP" /etc/mongod.conf

            # Restart MongoDB to apply changes
            sudo systemctl restart mongod
            sudo systemctl enable mongod

            # Wait for MongoDB to be ready
            echo "Waiting for MongoDB to be ready..."
            sleep 10

            # Create application user and database
            mongosh --eval "
                use appdb;
                db.createUser({
                    user: 'appuser',
                    pwd: 'securepassword123',
                    roles: [ { role: 'readWrite', db: 'appdb' } ]
                });
                db.test.insertOne({message: 'Database initialization complete'});
            "

            # Test database connection
            mongosh --eval "db.adminCommand('ping')" appdb && echo "✅ MongoDB is responding" || echo "⚠️ MongoDB connection test failed"

            echo "MongoDB deployment completed"
DB_EOF
EOF
    
    if [ $? -eq 0 ]; then
        print_success "MongoDB deployed successfully"
        print_status "Database running on: $DB_VM_PRIVATE_IP:27017"
    else
        print_error "Failed to deploy MongoDB"
        return 1
    fi
}

# Function to copy SSH key to bastion host
setup_ssh_bastion() {
    print_header "Setting up SSH Key for Bastion Access"
    
    # Copy the SSH key to the bastion host (web VM) for accessing other VMs
    scp -i "$SSH_KEY_FILE" -o StrictHostKeyChecking=no "$SSH_KEY_FILE" $VM_USER@$WEB_VM_PUBLIC_IP:~/.ssh/vm_key

    ssh -i "$SSH_KEY_FILE" -o StrictHostKeyChecking=no $VM_USER@$WEB_VM_PUBLIC_IP "chmod 600 ~/.ssh/vm_key"

    print_success "SSH key copied to bastion host"
}

# Function to verify deployments
verify_deployments() {
    print_header "Verifying Deployments"
    
    # Test frontend
    print_status "Testing frontend..."
    if curl -s -o /dev/null -w "%{http_code}" http://$WEB_VM_PUBLIC_IP | grep -q "200"; then
        print_success "Frontend is responding (HTTP 200)"
    else
        print_warning "Frontend may not be responding correctly"
    fi
    
    # Test backend through frontend proxy
    print_status "Testing backend through proxy..."
    if curl -s -o /dev/null -w "%{http_code}" http://$WEB_VM_PUBLIC_IP/api/health | grep -q "200"; then
        print_success "Backend is responding through proxy (HTTP 200)"
    else
        print_warning "Backend may not be responding correctly through proxy"
    fi
    
    print_status "Deployment verification completed"
}

# Function to display deployment summary
show_deployment_summary() {
    print_header "Deployment Summary"
    
    echo -e "${GREEN}🎉 Hybrid Deployment Completed!${NC}"
    echo ""
    echo "Application URLs:"
    echo "  🌐 Frontend: http://$WEB_VM_PUBLIC_IP"
    echo "  🔌 Backend API: http://$WEB_VM_PUBLIC_IP/api (proxied)"
    echo "  🗄️  Database: $DB_VM_PRIVATE_IP:27017 (internal)"
    echo ""
    echo "Git Repositories/Images Deployed:"
    echo "  � Frontend: $FRONTEND_IMAGE (Docker)"
    echo "  📁 Backend: $BACKEND_REPO (Git)"
    echo ""
    echo "SSH Access:"
    echo "  🔑 Web VM: ssh -i $SSH_KEY_FILE $VM_USER@$WEB_VM_PUBLIC_IP"
    echo ""
    echo "To monitor backend processes:"
    echo "  ssh -i $SSH_KEY_FILE $VM_USER@$WEB_VM_PUBLIC_IP"
    echo "  ssh $VM_USER@$BACKEND_VM_PRIVATE_IP"
    echo "  pm2 status"
    echo "  pm2 logs"
    echo ""
    echo -e "${YELLOW}Note: Frontend uses your custom Docker image, Backend uses Git repository${NC}"
    echo -e "${YELLOW}Make sure your backend Git repository contains proper package.json file${NC}"
}

# Main execution function
main() {
    print_header "Hybrid Deployment for 3-Tier Architecture"
    
    echo "Configuration:"
    echo "  Frontend Image: $FRONTEND_IMAGE"
    echo "  Backend Repository: $BACKEND_REPO"
    echo "  Database Image: $DATABASE_IMAGE"
    echo ""
    
    # Execute deployment steps
    check_prerequisites
    get_vm_info
    get_ssh_key
    
    # Test SSH connectivity to web VM (bastion)
    if ! test_ssh_connectivity "$WEB_VM_PUBLIC_IP" "Web VM"; then
        exit 1
    fi
    
    # Setup SSH bastion access
    setup_ssh_bastion
    
    # Install software on VMs
    install_docker_web "$WEB_VM_PUBLIC_IP"
    
    # Install Node.js on backend VM through bastion
    ssh -i "$SSH_KEY_FILE" -o StrictHostKeyChecking=no $VM_USER@$WEB_VM_PUBLIC_IP \
        "ssh -i ~/.ssh/vm_key -o StrictHostKeyChecking=no $VM_USER@$BACKEND_VM_PRIVATE_IP 'curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - && sudo apt-get install -y nodejs build-essential git && sudo npm install -g pm2'"
    
    # Deploy applications
    deploy_database
    deploy_backend
    deploy_frontend
    
    # Verify deployments
    verify_deployments
    
    # Show summary
    show_deployment_summary
    
    # Cleanup
    rm -f "$SSH_KEY_FILE"
    
    print_success "Git repository deployment completed successfully!"
}

# Run main function
main "$@"
