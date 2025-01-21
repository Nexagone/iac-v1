#!/bin/bash

# Afficher les étapes d'exécution
set -x

# Installation de K3s (vérifier si déjà installé)
if ! command -v k3s &> /dev/null; then
    echo "Installation de K3s..."
    curl -sfL https://get.k3s.io | sh -
else
    echo "K3s déjà installé, vérification du service..."
fi

# Attendre que le service soit prêt (avec timeout)
echo "Attente du démarrage du service..."
timeout 60 bash -c 'until sudo kubectl get node &>/dev/null; do sleep 2; done'

# Si le timeout est atteint, afficher l'état du service
if [ $? -eq 124 ]; then
    echo "Timeout atteint. Vérification du statut..."
    sudo systemctl status k3s
    exit 1
fi

# Obtenir l'IP externe IPv4 spécifiquement
echo "Récupération de l'IP externe..."
EXTERNAL_IP=$(curl -s -4 ifconfig.me)
echo "IP externe : ${EXTERNAL_IP}"

# Créer le dossier si nécessaire
mkdir -p /home/ubuntu/.kube

# Créer une copie du kubeconfig (seulement si nécessaire)
if [ ! -f /home/ubuntu/.kube/config ] || ! grep -q "${EXTERNAL_IP}" /home/ubuntu/.kube/config; then
    echo "Configuration du kubeconfig..."
    sudo cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
    sudo chown ubuntu:ubuntu /home/ubuntu/.kube/config
    sudo chmod 644 /home/ubuntu/.kube/config

    # Remplacer localhost et 127.0.0.1 par l'IP externe IPv4
    sudo sed -i "s/127.0.0.1/${EXTERNAL_IP}/g" /home/ubuntu/.kube/config
    sudo sed -i "s/localhost/${EXTERNAL_IP}/g" /home/ubuntu/.kube/config
    sudo sed -i "s/\[\:\:1\]/${EXTERNAL_IP}/g" /home/ubuntu/.kube/config
else
    echo "Kubeconfig déjà configuré avec la bonne IP"
fi

# Test rapide de connexion au cluster
echo "Test de connexion au cluster..."
kubectl get nodes -o wide --timeout=30s

echo "Installation et configuration terminées avec succès"

# Vérifier les ports ouverts
echo "Ports en écoute :"
sudo netstat -tlpn | grep kube

# Vérifier le statut du pare-feu
echo "Statut du pare-feu :"
sudo ufw status

# Récupérer le token pour les autres nœuds
echo "Token du cluster :"
sudo cat /var/lib/rancher/k3s/server/node-token 