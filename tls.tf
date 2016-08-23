resource "tls_private_key" "ca" {
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "ca" {
  key_algorithm = "RSA"
  private_key_pem = "${tls_private_key.ca.private_key_pem}"
  validity_period_hours = 43800
  is_ca_certificate = true

  subject {
    common_name = "kube-ca"
  }

  allowed_uses = [
    "cert_signing"
  ]
}

resource "tls_private_key" "node" {
  count = "${var.node_count}"

  algorithm = "RSA"
}

resource "tls_private_key" "user" {
  algorithm = "RSA"
}

data "tls_cert_request" "user" {
  key_algorithm = "RSA"
  private_key_pem = "${tls_private_key.user.private_key_pem}"

  subject {
    common_name = "user"
  }
}

resource "tls_locally_signed_cert" "user" {
  cert_request_pem = "${data.tls_cert_request.user.cert_request_pem}"
  ca_key_algorithm = "RSA"
  ca_private_key_pem = "${tls_private_key.ca.private_key_pem}"
  ca_cert_pem = "${tls_self_signed_cert.ca.cert_pem}"
  validity_period_hours = 43800

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "content_commitment"
  ]
}

resource "null_resource" "user_auth" {
  provisioner "local-exec" {
    command = "mkdir -p $HOME/.kube/${var.domain}"
  }
  provisioner "local-exec" {
    command = "echo '${tls_self_signed_cert.ca.cert_pem}' > $HOME/.kube/${var.domain}/ca.pem"
  }
  provisioner "local-exec" {
    command = "echo '${tls_private_key.user.private_key_pem}' > $HOME/.kube/${var.domain}/user.key"
  }
  provisioner "local-exec" {
    command = "echo '${tls_locally_signed_cert.user.cert_pem}' > $HOME/.kube/${var.domain}/user.pem"
  }
  provisioner "local-exec" {
    command = "kubectl config set-cluster ${var.domain} --server=https://_kube.${var.domain} --certificate-authority=$HOME/.kube/${var.domain}/ca.pem"
  }
  provisioner "local-exec" {
    command = "kubectl config set-credentials user-${var.domain} --certificate-authority=$HOME/.kube/${var.domain}/ca.pem --client-key=$HOME/.kube/${var.domain}/user.key --client-certificate=$HOME/.kube/${var.domain}/user.pem"
  }
  provisioner "local-exec" {
    command = "kubectl config set-context ${var.domain} --cluster=${var.domain} --user=user-${var.domain}"
  }
}

output "user_help" {
  value = "run 'kubectl config use-context ${var.domain}' to start using your new cluster"
}
