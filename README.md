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
# Mettre à jour le serveur et K3s
terraform apply -var="force_update=true"
```

Cette commande exécutera le script update_server.sh qui :
1. Met à jour tous les packages du système
2. Met à jour K3s vers la dernière version
3. Redémarre le service si nécessaire
4. Vérifie l'état du cluster après la mise à jour

Vous pouvez exécuter cette commande plusieurs fois pour forcer une mise à jour, même sans changements dans Terraform. Le mécanisme de déclenchement basé sur un timestamp garantit qu'une nouvelle exécution sera lancée à chaque fois que vous spécifiez `-var="force_update=true"`.

Alternativement, vous pouvez utiliser la commande suivante pour forcer la réexécution :
```bash
terraform taint null_resource.update_server
terraform apply -var="force_update=true"
```

### Forcer la réinstallation
```bash
terraform taint null_resource.secure_server
terraform taint null_resource.k3s_installation
terraform apply
```

### Logs et debugging
```bash
# Logs fail2ban
sudo tail -f /var/log/fail2ban.log

# Logs SSH
sudo tail -f /var/log/auth.log

# Logs K3s
sudo journalctl -u k3s -f
```

## Sécurité

### Bonnes pratiques
- Ne jamais commiter de secrets dans Git
- Utiliser Vault en production (non-dev)
- Restreindre les accès réseau au minimum nécessaire
- Mettre à jour régulièrement les composants
- Surveiller les logs de sécurité

### Points d'attention
- Sauvegarder les tokens Vault
- Sécuriser l'accès SSH
- Monitorer les tentatives d'intrusion
- Vérifier régulièrement les règles du pare-feu

## Limitations connues
- Configuration single-node uniquement
- Mode dev de Vault (pour la démo)
- Pas de haute disponibilité

## Prochaines étapes possibles
- Ajout de nodes workers
- Configuration de la haute disponibilité
- Mise en place du monitoring
- Intégration d'un système de backup
- Amélioration de la sécurité réseau
- Mise en place d'une rotation automatique des clés

## TODO
- Add security check on machine and block port and firewall
- Implémenter des tests de sécurité automatisés
- Ajouter une surveillance des vulnérabilités