variable "token" {
  description = "packet token"
}

variable "projectid" {
  description = "packet project id"
}

variable "hostname" {
  default     = "firecracker-playground"
  description = "hostname"
}

# Configure the Packet Provider
provider "packet" {
  auth_token = "${var.token}"
}

resource "packet_device" "vmonpacket" {
  hostname         = "${var.hostname}"
  plan             = "baremetal_0"
  facility         = "ams1"
  operating_system = "ubuntu_16_04"
  billing_cycle    = "hourly"
  project_id       = "${var.projectid}"

  connection {
    type        = "ssh"
    user        = "root"
    private_key = "${file("~/.ssh/id_rsa")}"
  }

  provisioner "remote-exec" {
    inline = <<EOF
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get dist-upgrade -y
apt-get install -y language-pack-en sysstat vim htop git
sleep 2 && systemctl kexec &
EOF
  }

  provisioner "remote-exec" {
    inline = <<EOF
pushd /usr/local/bin
curl -o firecracker -L https://github.com/firecracker-microvm/firecracker/releases/download/v0.11.0/firecracker-v0.11.0
chmod +x firecracker
popd
git clone https://github.com/kikitux/firecracker-playground /root/firecracker-playground
cd /root/firecracker-playground
cp conf/firecracker.service /etc/systemd/system/
systemctl enable firecracker.service
systemctl start firecracker.service
EOF
  }
}
