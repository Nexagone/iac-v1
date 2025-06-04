# Infrastructure as Code - K3s sur OVH

Ce projet permet de déployer et configurer automatiquement un cluster K3s sur un serveur OVH existant en utilisant Terraform et Vault pour la gestion des secrets.

## Architecture

### Composants principaux
- **K3s** : Distribution légère de Kubernetes
- **Terraform** : Outil d'Infrastructure as Code
- **HashiCorp Vault** : Gestionnaire de secrets
- **OVH API** : API pour interagir avec l'infrastructure OVH
- **Fail2ban** : Protection contre les tentatives d'intrusion
- **UFW** : Pare-feu simplifié pour Linux

### Structure des fichiers
- **providers.tf** : Configuration des providers Terraform
- **variables.tf** : Déclaration des variables
- **main.tf** : Définition des ressources et des dépendances
- **secure_server.sh** : Script de sécurisation du serveur
- **install_k3s.sh** : Script d'installation de K3s
- **update_server.sh** : Script de mise à jour du serveur et de K3s
- **terraform.tfvars** : Variables d'environnement
- **README.md** : Documentation du projet

## Fonctionnalités

### 1. Sécurisation du serveur
- Configuration SSH sécurisée
  - Désactivation de l'accès root
  - Authentification par clé uniquement
  - Limitation des tentatives de connexion
- Protection contre les attaques
  - Fail2ban pour SSH et API Kubernetes
  - Pare-feu UFW configuré
  - Monitoring des tentatives d'intrusion
- Gestion des ports
  - SSH (22)
  - Kubernetes API (6443)
  - HTTP/HTTPS (80/443)

### 2. Gestion des secrets avec Vault
- Stockage sécurisé des credentials OVH
- Séparation des secrets de l'infrastructure
- Intégration native avec Terraform

### 3. Installation automatisée de K3s
- Déploiement via SSH
- Configuration automatique du kubeconfig
- Adaptation de la configuration pour l'accès externe

### 4. Configuration réseau
- Configuration automatique des endpoints
- Gestion des accès IPv4
- Vérification des ports et du pare-feu

## Prérequis

### Infrastructure
- Un serveur existant chez OVH
- Accès SSH configuré avec une clé
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

### 1. Initialisation et déploiement
```bash
terraform init
terraform plan
terraform apply
```

### 2. Vérification de la sécurité
```bash
# Vérifier le statut de fail2ban
sudo fail2ban-client status

# Vérifier les règles du pare-feu
sudo ufw status numbered

# Vérifier la configuration SSH
grep -E "^(PermitRootLogin|PasswordAuthentication)" /etc/ssh/sshd_config
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

### Mise à jour du serveur et de K3s
Pour mettre à jour le système et K3s vers les dernières versions stables :

```bash
# Mettre à jour uniquement le système (sans K3s)
terraform apply -var="force_update=true" -var="update_k3s=false"

# Mettre à jour le système et K3s
terraform apply -var="force_update=true" -var="update_k3s=true"
```

Cette commande exécutera le script update_server.sh qui :
1. Met à jour tous les packages du système
2. Vérifie et installe Docker si nécessaire
3. Met à jour K3s vers la dernière version (uniquement si update_k3s=true)
4. Redémarre le service K3s si nécessaire
5. Vérifie l'état du cluster après la mise à jour

Vous pouvez exécuter cette commande plusieurs fois pour forcer une mise à jour, même sans changements dans Terraform. Le mécanisme de déclenchement basé sur un timestamp garantit qu'une nouvelle exécution sera lancée à chaque fois que vous spécifiez `-var="force_update=true"`.

Alternativement, vous pouvez utiliser la commande suivante pour forcer la réexécution :
```bash
terraform taint null_resource.update_server
terraform apply -var="force_update=true" -var="update_k3s=false"  # ou true selon votre besoin
```

### Forcer la réinstallation
```