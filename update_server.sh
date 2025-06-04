#!/bin/bash

# Afficher les commandes exécutées
set -x

# Récupération du paramètre de mise à jour de K3s
UPDATE_K3S=${1:-"false"}

# Mise à jour du système
echo "Mise à jour du système..."
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

# Vérification et installation de Docker si nécessaire
echo "Vérification de Docker..."
if ! command -v docker &> /dev/null; then
    echo "Docker n'est pas installé. Installation en cours..."
    # Installation des prérequis
    sudo apt-get install -y ca-certificates curl gnupg
    
    # Ajout de la clé GPG officielle de Docker
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    
    # Ajout du dépôt Docker
    echo \
      "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Mise à jour des paquets et installation de Docker
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Ajout de l'utilisateur au groupe docker
    sudo usermod -aG docker $USER
    
    echo "Docker a été installé avec succès"
else
    echo "Docker est déjà installé"
    docker --version
fi

# Mise à jour de K3s si demandé
if [ "$UPDATE_K3S" = "true" ]; then
    echo "Mise à jour de K3s demandée..."
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
else
    echo "Mise à jour de K3s non demandée, étape ignorée"
fi

# Nettoyage après mise à jour
echo "Nettoyage du système..."
sudo apt-get autoremove -y
sudo apt-get clean

echo "Mise à jour terminée avec succès" 