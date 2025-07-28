# Scripts Directory

This directory contains all deployment and verification scripts for the 3-tier Azure infrastructure project.

## 📁 Script Overview

### Core Deployment Scripts

#### `deploy-git-repos.sh` - **Main Hybrid Deployment Script**
- **Purpose**: Deploys a hybrid 3-tier architecture (Docker frontend + Git backend)
- **Frontend**: Deploys your custom Docker image (`mprabesh/react-frontend:latest`)
- **Backend**: Clones Git repository and runs with Node.js + PM2
- **Database**: MongoDB Docker container
- **Usage**: `./deploy-git-repos.sh [--frontend-image IMAGE] [--backend-repo URL]`

### VM Bootstrap Scripts

#### `install-docker-web.sh` - **Web VM Docker Installation**
- **Purpose**: Installs Docker on Web VM during Terraform provisioning
- **Usage**: Called automatically by Terraform `custom_data`
- **Installs**: Docker CE, Docker Compose, user permissions

#### `install-nodejs-backend.sh` - **Backend VM Node.js Installation**
- **Purpose**: Installs Node.js on Backend VM for Git-based deployment
- **Usage**: Called automatically by Terraform `custom_data`
- **Installs**: Node.js 18.x, npm, PM2, Git, build tools

### Verification Scripts

#### `verify-deployment.sh` - **Deployment Verification**
- **Purpose**: Verifies hybrid deployment status
- **Features**: 
  - Checks frontend Docker container
  - Verifies backend PM2 processes
  - Tests database connectivity
  - API endpoint testing
- **Usage**: `./verify-deployment.sh --from-terraform`

## 🚀 Deployment Workflow

### Quick Start
```bash
# 1. Deploy infrastructure with Terraform
terraform apply

# 2. Run hybrid deployment
./scripts/deploy-git-repos.sh

# 3. Verify deployment
./scripts/verify-deployment.sh --from-terraform
```

### Custom Configuration
```bash
# Deploy with custom frontend image
./scripts/deploy-git-repos.sh \
    --frontend-image yourusername/custom-frontend:v1.0 \
    --backend-repo https://github.com/yourusername/api-backend

# Deploy with different database version
./scripts/deploy-git-repos.sh \
    --frontend-image mprabesh/react-frontend:latest \
    --backend-repo https://github.com/mprabesh/node-backend.git \
    --database-image mongo:6.0
```

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Web VM (VM1)  │    │Backend VM (VM2) │    │  DB VM (VM3)   │
│                 │    │                 │    │                 │
│ 🐳 Docker       │    │ 📁 Git Repo     │    │ 🐳 Docker      │
│ Frontend        │◄──►│ Node.js + PM2   │◄──►│ MongoDB        │
│ (Port 80)       │    │ (Port 3000)     │    │ (Port 27017)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Component Details

- **Frontend (Web VM)**:
  - Docker container with your custom React app
  - Nginx reverse proxy for `/api` routes
  - Public access via Azure Load Balancer

- **Backend (Backend VM)**:
  - Git repository cloned to `/opt/backend`
  - Node.js application managed by PM2
  - Environment variables auto-configured
  - Private network access only

- **Database (DB VM)**:
  - MongoDB 7.0 Docker container
  - Persistent volume for data
  - Private network access only

## 🔧 Configuration Files

### Environment Variables (Backend)
```bash
PORT=3000
NODE_ENV=production
DB_HOST=<DB_VM_PRIVATE_IP>
DB_PORT=27017
DB_NAME=appdb
DB_USER=appuser
DB_PASSWORD=securepassword123
DATABASE_URL=mongodb://appuser:securepassword123@<DB_VM_PRIVATE_IP>:27017/appdb
```

### Default Repository URLs
- Frontend Image: `mprabesh/react-frontend:latest`
- Backend Repo: `https://github.com/mprabesh/node-backend.git`
- Database Image: `mongo:7.0`

## 🔍 Troubleshooting

### Check Script Execution
```bash
# View deployment logs
ssh -i ssh_key.pem vmuser@<WEB_VM_IP>
sudo docker logs frontend-web

# Check backend status
ssh -i ssh_key.pem vmuser@<WEB_VM_IP>
ssh vmuser@<BACKEND_VM_IP>
pm2 status
pm2 logs
```

### Common Issues

1. **Frontend container not starting**
   - Check Docker image availability
   - Verify port 80 is not in use
   - Check container logs: `sudo docker logs frontend-web`

2. **Backend application not responding**
   - Verify Node.js installation: `node --version`
   - Check PM2 processes: `pm2 status`
   - Review application logs: `pm2 logs`

3. **Database connection issues**
   - Verify MongoDB container: `sudo docker ps | grep mongodb-db`
   - Test connection: `sudo docker exec mongodb-db mongosh --eval "db.adminCommand('ping')"`
   - Check network connectivity between VMs

## 📝 Script Maintenance

### Adding New Features
1. Update `deploy-git-repos.sh` for new deployment logic
2. Update `verify-deployment.sh` for new verification checks
3. Update this README with new configuration options

### Version Updates
- Node.js version: Modify `install-nodejs-backend.sh`
- MongoDB version: Update `DATABASE_IMAGE` variable
- Docker version: Update `install-docker-web.sh`

## 🔐 Security Notes

- SSH keys are managed via Azure Key Vault
- All inter-VM communication uses private networks
- Database access is restricted to backend VM only
- Frontend serves static content with API proxy

## 📚 Additional Resources

- [Azure Virtual Machine Documentation](https://docs.microsoft.com/en-us/azure/virtual-machines/)
- [Docker Documentation](https://docs.docker.com/)
- [MongoDB Documentation](https://docs.mongodb.com/)
- [PM2 Documentation](https://pm2.keymetrics.io/docs/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
