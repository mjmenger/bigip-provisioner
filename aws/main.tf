resource "aws_security_group" "bigip-sg" {
  name   = "tfve_sg-${random_pet.securitygroup.id}"
  vpc_id = "${var.bigip_vpc}"
  subnet_id = "${var.bigip_subnet}"
  description = "used as part of terraform build and configuration"

  # enable SSH access in order to perform post build provisioning
  # TODO: fix the anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # enable access for bigip console in single NIC
  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # enable access for bigip console
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# TODO: set the sensitive flag for greater security or use the random_password resource type
# SUPERTODO: replace this with reference to Vault instance
resource "random_string" "bigippassword" {
  length = 16
  special = true
  override_special = "/@"
}

resource "random_pet" "securitygroup" {

}

data "template_file" "vm_onboard" {
  template = "${file("${path.module}/onboard.tpl")}"

  vars = {
    uname        	              = "admin"
    upassword        	          = "${random_string.bigippassword.result}"
    DO_onboard_URL              = "${var.DO_onboard_URL}"
    AS3_URL		                  = "${var.AS3_URL}"
    libs_dir		                = "${var.libs_dir}"
    onboard_log		              = "${var.onboard_log}"
    management_interface_delay  = "${var.waitformgmtintf}"
  }
}

data "aws_ami" "latestbigip" {
  most_recent      = true
  owners           = ["679593333241"]

  filter {
    name   = "name"
    values = ["F5 BIGIP-14*PAYG-Good 5Gbps*"]
  }
}

resource "aws_instance" "f5bigip" {
  ami                     = "${data.aws_ami.latestbigip.id}"
  instance_type           = "c5.large"
  key_name                = "${var.sshkeyname}"
  vpc_security_group_ids  = ["${aws_security_group.bigip-sg.id}"]
  count                   = "${var.bigipcount}"

  tags = {
    Name = "disposablebigip${count.index}"
  }

  connection {
    type        = "ssh"
    user        = "admin"
    private_key = "${file(var.sshkeypath)}"
    host        = "${self.public_ip}"
  }

  #
  # because of how the remote-exec provisioner works and the capabilities of the
  # default tmsh it is necessary to use local-exec to wrap the requisite ssh command
  # -v is for troubleshooting and should eventually be removed
  # StrictHostKeyChecking=no is a brute force approach to addressing the fingerprinting of the key
  # ConnectTimeout and ConnectionAttempts are used to repeatedly connect to the bigip until it is ready
  # the timeout and attempts values probably need to be a function of the instance type since
  # larger instances take longer to come online
  #
  # ideally it would be great to authenticate against the REST API using private keys in place of passwords
  #
  provisioner "local-exec" {
    command = "ssh -i ${var.sshkeypath} -o StrictHostKeyChecking=no -o ConnectTimeout=10 -o ConnectionAttempts=20 -v admin@${self.public_dns} 'modify auth user admin password \"${random_string.bigippassword.result}\"'"
  }
  
  # enable bash in order to use Terraform primitives
  provisioner "local-exec" {
    command = "ssh -i ${var.sshkeypath} -o StrictHostKeyChecking=no -o ConnectTimeout=10 -o ConnectionAttempts=10 -v admin@${self.public_dns} 'modify auth user admin shell bash'"
  }

  #
  # download and install AS3 and Declarative Onboarding
  #
  provisioner "file" {
    content       = "${data.template_file.vm_onboard.rendered}"
    destination   = "/var/tmp/onboard.sh"
  }
  provisioner "file" {
    source      = "${path.module}/as3.json"
    destination = "/var/tmp/as3.json"
  }
  provisioner "file" {
    source      = "${path.module}/cluster.json"
    destination = "/var/tmp/vm_do.json"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /var/tmp/onboard.sh",
      "/var/tmp/onboard.sh"
    ]
  }

  

  # install the license
  # provisioner "local-exec" {
  #   command = "curl -k -X POST https://${self.public_dns}:8443/mgmt/shared/declarative-onboarding -H 'Content-Type: application/json' -H 'X-F5-Auth-Token: ${jsondecode(file("./${self.public_dns}token.txt"))["token"]["token"]}' -d '${templatefile("./licensetemplatejson.tmpl",{bigiplicense = "FQRTG-WFBOT-NWQHO-HKLCR-AARLLDG"})}'"
  # }

}
