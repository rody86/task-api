#!/bin/bash
set -e

# 1. Actualizar sistema e instalar Docker
dnf update -y
dnf install -y docker git
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

# 2. Instalar K3s
curl -sfL https://get.k3s.io | sh -

# 3. Configurar kubectl para el usuario ec2-user
mkdir -p /home/ec2-user/.kube
cp /etc/rancher/k3s/k3s.yaml /home/ec2-user/.kube/config
chown -R ec2-user:ec2-user /home/ec2-user/.kube
echo 'export KUBECONFIG=/home/ec2-user/.kube/config' >> /home/ec2-user/.bashrc

# 4. Instalar ArgoCD
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
kubectl create namespace argocd
kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 5. Esperar a que ArgoCD esté listo
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd || true

# 6. Crear el secreto de la base de datos
kubectl create secret generic postgres-secret \
  --from-literal=POSTGRES_USER=taskuser \
  --from-literal=POSTGRES_PASSWORD=taskpass \
  --from-literal=POSTGRES_DB=taskdb \
  --from-literal=DATABASE_URL=postgresql://taskuser:taskpass@db:5432/taskdb || true

echo "Instalación completada" > /var/log/user-data-done.log
