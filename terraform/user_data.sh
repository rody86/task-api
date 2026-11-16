#!/bin/bash
# Quitamos el 'set -e' para que si un comando falla, el script no muera, sino que lo intentemos más tarde.
#set -e

#!/bin/bash
# Quitamos el 'set -e' para que si un comando falla, el script no muera, sino que lo intentemos más tarde.

# 1. Instalar Docker
dnf update -y
dnf install -y docker git curl
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

# 2. Instalar K3s
curl -sfL https://get.k3s.io | sh -

# 3. Esperar a que K3s esté realmente listo (bucle de 30 intentos)
echo "Esperando a que K3s arranque..."
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
for i in {1..30}; do
    if kubectl get nodes &> /dev/null; then
        echo "K3s está listo."
        break
    fi
    echo "K3s aún no está listo. Esperando 5 segundos..."
    sleep 5
done

# 4. Crear el Secreto de la Base de Datos
echo "Creando secretos..."
kubectl create secret generic postgres-secret \
  --from-literal=POSTGRES_USER=taskuser \
  --from-literal=POSTGRES_PASSWORD=taskpass \
  --from-literal=POSTGRES_DB=taskdb \
  --from-literal=DATABASE_URL=postgresql://taskuser:taskpass@db:5432/taskdb

# 5. Configurar permisos para ec2-user
mkdir -p /home/ec2-user/.kube
cp /etc/rancher/k3s/k3s.yaml /home/ec2-user/.kube/config
chown -R ec2-user:ec2-user /home/ec2-user/.kube
echo 'export KUBECONFIG=/home/ec2-user/.kube/config' >> /home/ec2-user/.bashrc

# 6. Instalar ArgoCD (opcional, para que esté listo)
echo "Instalando ArgoCD..."
kubectl create namespace argocd
kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 7. Marcar como terminado
echo "Script de inicialización terminado con éxito." > /var/log/user-data-done.log
