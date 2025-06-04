# Utilisation d'une ressource null_resource pour sécuriser la machine
resource "null_resource" "secure_server" {
  connection {
    type        = "ssh"
    user        = var.ssh_user
    host        = var.existing_server_ip
    private_key = file(var.ssh_private_key_path)
  }

  provisioner "file" {
    source      = "secure_server.sh"
    destination = "/tmp/secure_server.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/secure_server.sh",
      "/tmp/secure_server.sh"
    ]
  }
}

# Installation de K3s après la sécurisation
resource "null_resource" "k3s_installation" {
  depends_on = [null_resource.secure_server]
  
  connection {
    type        = "ssh"
    user        = var.ssh_user
    host        = var.existing_server_ip
    private_key = file(var.ssh_private_key_path)
  }

  provisioner "file" {
    source      = "install_k3s.sh"
    destination = "/tmp/install_k3s.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_k3s.sh",
      "/tmp/install_k3s.sh"
    ]
  }
}

resource "null_resource" "get_kubeconfig" {
  depends_on = [null_resource.k3s_installation]
  
  provisioner "local-exec" {
    command = "mkdir -p ~/.kube && scp -i ${var.ssh_private_key_path} ${var.ssh_user}@${var.existing_server_ip}:/home/ubuntu/.kube/config ~/.kube/config"
  }
}

# Ressource pour la mise à jour du serveur et de K3s
resource "null_resource" "update_server" {
  # Ce trigger permet de forcer l'exécution à chaque apply si le paramètre force_update est à true
  # Utilisation d'un timestamp pour forcer l'exécution chaque fois que force_update=true
  triggers = {
    force_update = var.force_update ? timestamp() : "false"
    update_k3s   = var.update_k3s ? "true" : "false"
  }

  connection {
    type        = "ssh"
    user        = var.ssh_user
    host        = var.existing_server_ip
    private_key = file(var.ssh_private_key_path)
  }

  provisioner "file" {
    source      = "update_server.sh"
    destination = "/tmp/update_server.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/update_server.sh",
      "/tmp/update_server.sh ${var.update_k3s}"
    ]
  }
} 