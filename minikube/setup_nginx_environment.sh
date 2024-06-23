#!/bin/bash

# Check if Docker is installed
if ! command -v docker &> /dev/null
then
    echo "Docker not found, installing Docker..."
    sudo apt-get update
    sudo apt-get install -y docker.io
else
    echo "Docker is already installed"
fi

# Check if Kubernetes is installed
if ! command -v kubectl &> /dev/null
then
    echo "kubectl not found, installing Kubernetes..."
    sudo apt-get update
    sudo apt-get install -y kubectl
else
    echo "kubectl is already installed"
fi

# Check if Minikube is installed
if ! command -v minikube &> /dev/null
then
    echo "Minikube not found, installing Minikube..."
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    rm minikube-linux-amd64
else
    echo "Minikube is already installed"
fi

# Start Minikube if it's not running
if ! minikube status &> /dev/null
then
    echo "Starting Minikube..."
    minikube start
else
    echo "Minikube is already running"
fi

# Start Minikube ingress if not running
minikube addons enable ingress

# Apply Kubernetes configuration files
for file in *; do
    if  [[ $file == *"configmap"* ]] || [[ $file == *"deployment"* ]] || [[ $file == *"service"* ]] || [[ $file == *"ingress"* ]]; then
        echo "Applying configuration from $file..."
        kubectl apply -f "$file"
    fi
done

# Retrieve Minikube IP
MINIKUBE_IP=$(minikube ip)

# Check if Minikube IP is in /etc/hosts, and if not, add it
if ! grep -q "$MINIKUBE_IP my-nginx.local" /etc/hosts; then
    echo "Adding Minikube IP to /etc/hosts..."
    echo "$MINIKUBE_IP my-nginx.local" | sudo tee -a /etc/hosts
else
    echo "Minikube IP is already in /etc/hosts"
fi

# Run minikube service command for the service
for file in *service*.yaml; do
    SERVICE_NAME=$(basename "$file" .yaml)
    echo "Fetching URL for service $SERVICE_NAME..."
    minikube service "$SERVICE_NAME" --url
done

echo "Script execution completed."

