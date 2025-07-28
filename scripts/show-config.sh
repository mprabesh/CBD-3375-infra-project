#!/bin/bash

# Configuration Summary Script
# Shows current deployment configuration and script status

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
    echo -e "${GREEN}[✅]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠️]${NC} $1"
}

main() {
    print_header "🔧 CBD-3375 Infrastructure Project Scripts Summary"
    
    echo "Project: 3-Tier Azure Infrastructure with Hybrid Deployment"
    echo "Owner: mprabesh"
    echo "Date: $(date)"
    echo ""
    
    print_header "📁 Available Scripts"
    
    echo "🚀 Deployment Scripts:"
    if [ -f "deploy-git-repos.sh" ]; then
        print_success "deploy-git-repos.sh - Main hybrid deployment script"
        echo "     Frontend: Docker container (mprabesh/react-frontend:latest)"
        echo "     Backend: Git repository (https://github.com/mprabesh/node-backend.git)"
        echo "     Database: MongoDB Docker container"
    else
        print_warning "deploy-git-repos.sh not found"
    fi
    
    echo ""
    echo "🔧 VM Bootstrap Scripts:"
    if [ -f "install-docker-web.sh" ]; then
        print_success "install-docker-web.sh - Web VM Docker installation"
    else
        print_warning "install-docker-web.sh not found"
    fi
    
    if [ -f "install-nodejs-backend.sh" ]; then
        print_success "install-nodejs-backend.sh - Backend VM Node.js installation"
    else
        print_warning "install-nodejs-backend.sh not found"
    fi
    
    echo ""
    echo "🔍 Verification Scripts:"
    if [ -f "verify-deployment.sh" ]; then
        print_success "verify-deployment.sh - Hybrid deployment verification"
    else
        print_warning "verify-deployment.sh not found"
    fi
    
    print_header "🏗️ Architecture Overview"
    
    echo "┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐"
    echo "│   Web VM (VM1)  │    │Backend VM (VM2) │    │  DB VM (VM3)   │"
    echo "│                 │    │                 │    │                 │"
    echo "│ 🐳 Docker       │    │ 📁 Git Repo     │    │ 🐳 Docker      │"
    echo "│ Frontend        │◄──►│ Node.js + PM2   │◄──►│ MongoDB        │"
    echo "│ (Port 80)       │    │ (Port 3000)     │    │ (Port 27017)   │"
    echo "└─────────────────┘    └─────────────────┘    └─────────────────┘"
    echo ""
    
    print_header "🚀 Quick Start Commands"
    
    echo "1. Deploy Infrastructure:"
    echo "   terraform apply"
    echo ""
    echo "2. Deploy Applications:"
    echo "   ./scripts/deploy-git-repos.sh"
    echo ""
    echo "3. Verify Deployment:"
    echo "   ./scripts/verify-deployment.sh --from-terraform"
    echo ""
    echo "4. Custom Deployment:"
    echo "   ./scripts/deploy-git-repos.sh \\"
    echo "       --frontend-image your/custom:image \\"
    echo "       --backend-repo https://github.com/user/repo"
    echo ""
    
    print_header "📊 Current Configuration"
    
    # Check if terraform outputs are available
    if command -v terraform &> /dev/null && terraform output &> /dev/null 2>&1; then
        echo "Terraform Status: ✅ Infrastructure deployed"
        
        WEB_IP=$(terraform output -raw web_vm_public_ip 2>/dev/null || echo "Not available")
        BACKEND_IP=$(terraform output -raw backend_vm_private_ip 2>/dev/null || echo "Not available")
        DB_IP=$(terraform output -raw db_vm_private_ip 2>/dev/null || echo "Not available")
        KEY_VAULT=$(terraform output -raw key_vault_name 2>/dev/null || echo "Not available")
        
        echo "Web VM Public IP: $WEB_IP"
        echo "Backend VM Private IP: $BACKEND_IP"
        echo "Database VM Private IP: $DB_IP"
        echo "Key Vault Name: $KEY_VAULT"
    else
        echo "Terraform Status: ⚠️ No infrastructure found (run 'terraform apply' first)"
    fi
    
    echo ""
    print_header "📚 Documentation"
    
    echo "📖 README files:"
    if [ -f "README.md" ]; then
        print_success "scripts/README.md - Comprehensive documentation available"
    else
        print_warning "scripts/README.md not found"
    fi
    
    if [ -f "../README.md" ]; then
        print_success "../README.md - Project documentation available"
    fi
    
    if [ -f "../DEPLOYMENT_GUIDE.md" ]; then
        print_success "../DEPLOYMENT_GUIDE.md - Deployment guide available"
    fi
    
    echo ""
    print_success "🎉 Script summary complete!"
    echo ""
    echo "For detailed help on any script, run:"
    echo "  ./script-name.sh --help"
}

# Change to scripts directory if not already there
if [[ ! -f "deploy-git-repos.sh" && -d "scripts" ]]; then
    cd scripts
fi

main "$@"
