# Infrastructure as Code - K3s sur OVH

Ce projet permet de déployer et configurer automatiquement un cluster K3s sur un serveur OVH existant en utilisant Terraform et Vault pour la gestion des secrets.

## Architecture

### Composants principaux
- **K3s** : Distribution légère de Kubernetes
- **Terraform** : Outil d'Infrastructure as Code
- **HashiCorp Vault** : Gestionnaire de secrets
- **OVH API** : API pour interagir avec l'infrastructure OVH

### Structure des fichiers
- **providers.tf** : Configuration des providers Terraform
- **variables.tf** : Déclaration des variables
- **main.tf** : Définition des ressources et des dépendances
- **outputs.tf** : Déclaration des outputs
- **terraform.tfvars** : Variables d'environnement
- **README.md** : Documentation du projet

## Fonctionnalités

### 1. Gestion des secrets avec Vault
- Stockage sécurisé des credentials OVH
- Séparation des secrets de l'infrastructure
- Intégration native avec Terraform

### 2. Installation automatisée de K3s
- Déploiement via SSH
- Configuration automatique du kubeconfig
- Adaptation de la configuration pour l'accès externe

### 3. Configuration réseau
- Configuration automatique des endpoints
- Gestion des accès IPv4
- Vérification des ports et du pare-feu

## Prérequis

### Infrastructure
- Un serveur existant chez OVH
- Accès SSH configuré
- Python et curl installés sur le serveur

### Outils locaux
- Terraform >= 1.0
- Vault CLI
- kubectl
- k9s (optionnel)

## Configuration initiale

### 1. Vault

Démarrer Vault
```
vault server -dev
```
Dans un autre terminal
```
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='votre_token'
```
Stocker les secrets OVH
```
vault kv put secret/ovh \
application_key="votre_app_key" \
application_secret="votre_app_secret" \
consumer_key="votre_consumer_key"
```

### 2. Variables Terraform
Créer/modifier terraform.tfvars :

```hcl
existing_server_ip     = "votre.ip.serveur"
ssh_user              = "votre_user"
ssh_private_key_path  = "chemin/vers/votre/cle_ssh"
```

## Déploiement

### 1. Initialisation
```bash
terraform init
```

### 2. Vérification
```bash
terraform plan
```

### 3. Application
```bash
terraform apply
```

## Vérification du déploiement

### 1. Vérifier le cluster
```bash
kubectl get nodes
kubectl get pods --all-namespaces
```

### 2. Accéder au dashboard (optionnel)
```bash
k9s
```

## Maintenance

### Forcer la réinstallation
```bash
terraform taint null_resource.k3s_installation
terraform taint null_resource.get_kubeconfig
terraform apply
```

### Logs et debugging
```bash
# Sur le serveur
sudo systemctl status k3s
sudo journalctl -u k3s -f
```

## Sécurité

### Bonnes pratiques
- Ne jamais commiter de secrets dans Git
- Utiliser Vault en production (non-dev)
- Restreindre les accès réseau au minimum nécessaire
- Mettre à jour régulièrement K3s et les composants

### Points d'attention
- Sauvegarder les tokens Vault
- Sécuriser l'accès SSH
- Monitorer les accès au cluster

## Limitations connues
- Configuration single-node uniquement
- Mode dev de Vault (pour la démo)
- Pas de haute disponibilité

## Prochaines étapes possibles
- Ajout de nodes workers
- Configuration de la haute disponibilité
- Mise en place du monitoring
- Intégration d'un système de backup
