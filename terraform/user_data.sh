#!/bin/bash
set -e

# Actualizar sistema e instalar Docker
dnf update -y
dnf install -y docker git

# Arrancar Docker y habilitarlo en el boot
systemctl start docker
systemctl enable docker

# Añadir el usuario ec2-user al grupo docker (para no usar sudo)
usermod -aG docker ec2-user

# Instalar Docker Compose plugin
mkdir -p /usr/local/lib/docker/cli-plugins
curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

echo "Docker installation complete" > /var/log/user-data-done.log
