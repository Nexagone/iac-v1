#!/bin/bash

# Afficher les commandes exécutées
set -x

# Mise à jour du système
echo "Mise à jour du système..."
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

# Mise à jour de K3s
echo "Vérification de la version actuelle de K3s..."
K3S_CURRENT=$(k3s --version | awk '{print $3}')
echo "Version actuelle: ${K3S_CURRENT}"

echo "Mise à jour de K3s..."
curl -sfL https://get.k3s.io | sudo sh -

# Vérification de la nouvelle version
K3S_NEW=$(k3s --version | awk '{print $3}')
echo "Nouvelle version: ${K3S_NEW}"

if [ "$K3S_CURRENT" != "$K3S_NEW" ]; then
    echo "K3s a été mis à jour de ${K3S_CURRENT} vers ${K3S_NEW}"
    sudo systemctl restart k3s
    echo "Service K3s redémarré"
else
    echo "K3s est déjà à jour"
fi

# Vérification de l'état du système après mise à jour
echo "Vérification de l'état du système..."
sudo systemctl status k3s --no-pager
kubectl get nodes -o wide

# Nettoyage après mise à jour
echo "Nettoyage du système..."
sudo apt-get autoremove -y
sudo apt-get clean

echo "Mise à jour terminée avec succès" 