#!/bin/bash

# Exit on error, undefined variable, or error in any pipeline
set -euxo pipefail

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
fi

# Function to log messages with timestamp
log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1"
}

log "Starting script..."

# Variables
KUBERNETES_VERSION="1.28.2-00"
OS="xUbuntu_22.04"
VERSION="1.28"
PRIMARY_INTERFACE="eth0"

# Disable swap and prevent it from starting after reboot
sudo swapoff -a
sudo sed -i 's/^\/swap\.img/#\/swap.img/' /etc/fstab

# Update package list
sudo apt-get update -y

# Load kernel modules
sudo bash -c 'cat <<EOF > /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF'

# Load kernel modules immediately
sudo modprobe overlay
sudo modprobe br_netfilter

# Configure sysctl parameters for Kubernetes setup
sudo bash -c 'cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF'

# Apply sysctl parameters without reboot
sudo sysctl --system

# Print current sysctl parameters
sudo sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward

# Add CRI-O repository and install
sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list <<EOF
deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /
EOF

sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.list <<EOF
deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/ /
EOF

curl -L https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$VERSION/$OS/Release.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/libcontainers.gpg add -
curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/libcontainers.gpg add -

sudo apt-get update
sudo apt-get install -y cri-o cri-o-runc

# Enable and start CRI-O service
sudo systemctl daemon-reload
sudo systemctl enable crio --now

log "CRI runtime installed successfully"

# Install Kubernetes components
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://dl.k8s.io/apt/doc/apt-key.gpg

echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y kubelet="$KUBERNETES_VERSION" kubectl="$KUBERNETES_VERSION" kubeadm="$KUBERNETES_VERSION"

# Prevent Kubernetes packages from being automatically upgraded
sudo apt-mark hold kubelet kubeadm kubectl

# Install jq and set Kubelet node IP
sudo apt-get install -y jq

local_ip=$(ip --json addr show $PRIMARY_INTERFACE | jq -r '.[0].addr_info[] | select(.family == "inet") | .local')

echo "KUBELET_EXTRA_ARGS=--node-ip=$local_ip" | sudo tee /etc/default/kubelet > /dev/null

log "Kubeadm, Kubelet, Kubectl installed successfully!"
