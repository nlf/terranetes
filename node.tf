resource "null_resource" "discovery_token" {
  provisioner "local-exec" {
    command = "curl https://discovery.etcd.io/new?size=${var.node_count} > ${path.module}/.token"
  }
}

resource "template_file" "cloud_config" {
  depends_on = ["null_resource.discovery_token"]
  count = "${var.node_count}"
  template = "${file("${path.module}/templates/cloud-config.yaml")}"
  vars {
    name = "${format("kube-%02d", count.index + 1)}"
    discovery_token = "${file("${path.module}/.token")}"
    domain = "${var.domain}"
    node_count = "${var.node_count}"
    master_name = "${var.master_name}"
  }
}

resource "packet_device" "node" {
  count = "${var.node_count}"

  hostname = "${format("kube-%02d", count.index + 1)}"
  plan = "${var.node_plan}"
  facility = "${var.node_facility}"
  operating_system = "${var.node_os}"
  project_id = "${var.packet_project_id}"
  billing_cycle = "hourly"
  user_data = "${element(template_file.cloud_config.*.rendered, count.index)}"

  provisioner "file" {
    content = "${tls_self_signed_cert.ca.cert_pem}"
    destination = "/tmp/ca.pem"

    connection {
      type = "ssh"
      user = "core"
      port = "2042"
      private_key = "${file(var.private_key_path)}"
    }
  }

  provisioner "file" {
    content = "${tls_private_key.ca.private_key_pem}"
    destination = "/tmp/ca.key"

    connection {
      type = "ssh"
      user = "core"
      port = "2042"
      private_key = "${file(var.private_key_path)}"
    }
  }

  provisioner "file" {
    content = "${tls_private_key.node.private_key_pem}"
    destination = "/tmp/node.key"

    connection {
      type = "ssh"
      user = "core"
      port = "2042"
      private_key = "${file(var.private_key_path)}"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "openssl req -new -key /tmp/node.key -out /tmp/node.csr -subj /CN=${format("kube-%02d", count.index + 1)} -config /tmp/openssl.cnf",
      "openssl x509 -req -in /tmp/node.csr -CA /tmp/ca.pem -CAkey /tmp/ca.key -CAcreateserial -out /tmp/node.pem -days 1460 -extensions v3_req -extfile /tmp/openssl.cnf",
      "rm /tmp/node.csr /tmp/ca.key",
      "sudo mkdir -p /etc/kubernetes/ssl",
      "sudo mv /tmp/ca.pem /etc/kubernetes/ssl/",
      "sudo mv /tmp/node.pem /etc/kubernetes/ssl/",
      "sudo mv /tmp/node.key /etc/kubernetes/ssl/",
      "sudo chown root:root /etc/kubernetes/ssl/node.key",
      "sudo chmod 600 /etc/kubernetes/ssl/node.key"
    ]

    connection {
      type = "ssh"
      user = "core"
      port = "2042"
      private_key = "${file(var.private_key_path)}"
    }
  }
}

output "host_ips" {
  value = "create a dns entry for ${var.master_name}.${var.domain} with the IPs: ${join(", ", packet_device.node.*.network.0.address)}"
}
