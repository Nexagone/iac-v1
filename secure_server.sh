#!/bin/bash

# Afficher les commandes exécutées
set -x

# Mise à jour du système
echo "Mise à jour du système..."
sudo apt-get update
sudo apt-get upgrade -y

# Installation des outils de sécurité
echo "Installation des outils de sécurité..."
sudo apt-get install -y fail2ban ufw

# Configuration SSH
echo "Configuration SSH..."
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
sudo tee /etc/ssh/sshd_config << 'EOF'
Port 22
Protocol 2
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
PermitEmptyPasswords no
X11Forwarding no
AllowTcpForwarding yes
AllowAgentForwarding yes
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
EOF

# Configuration fail2ban
echo "Configuration fail2ban..."
sudo tee /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3

[k3s-api]
enabled = true
port = 6443
filter = k3s-api
logpath = /var/log/syslog
maxretry = 5
EOF

# Créer un filtre fail2ban pour l'API k3s
sudo tee /etc/fail2ban/filter.d/k3s-api.conf << 'EOF'
[Definition]
failregex = Failed .* for .* from <HOST>
ignoreregex =
EOF

# Configuration du pare-feu UFW
echo "Configuration du pare-feu..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp comment 'SSH'
sudo ufw allow 6443/tcp comment 'Kubernetes API'
sudo ufw allow 80/tcp comment 'HTTP'
sudo ufw allow 443/tcp comment 'HTTPS'

# Activer les services
echo "Activation des services..."
sudo systemctl restart ssh
sudo systemctl enable --now fail2ban
sudo ufw --force enable

# Vérification des configurations (sans blocage)
echo "Vérification des configurations..."
echo "Status fail2ban :"
sudo systemctl is-active fail2ban

echo "Règles UFW actives :"
sudo ufw status numbered | grep -E "^\\[[0-9]+\\]" || true

echo "Configuration SSH :"
grep -E "^(PermitRootLogin|PasswordAuthentication|PubkeyAuthentication)" /etc/ssh/sshd_config || true

# Afficher un résumé
echo "Installation terminée avec succès" 