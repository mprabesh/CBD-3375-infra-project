# Docker installation script for Web VM
locals {
  web_vm_docker_script = base64encode(templatefile("${path.module}/scripts/install-docker-web.sh", {
    admin_username = var.admin_username
  }))
  
  backend_vm_docker_script = base64encode(templatefile("${path.module}/scripts/install-docker-backend.sh", {
    admin_username = var.admin_username
  }))
}
