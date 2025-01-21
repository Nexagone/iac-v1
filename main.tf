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