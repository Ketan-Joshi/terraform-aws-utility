resource "tls_private_key" "ssh_private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "aws_key_pair" "ssh_key" {
  key_name   = var.pem_key_name
  public_key = tls_private_key.ssh_private_key.public_key_openssh
  provisioner "local-exec" { # This will create the pem where the terraform will run!!
    command = "rm -f ./${var.pem_key_name}.pem && echo '${tls_private_key.ssh_private_key.private_key_pem}' > ./${var.pem_key_name}.pem && chmod 400 ${var.pem_key_name}.pem"
  }
}
data "template_file" "userdata" {
  template = file("${path.module}/utility.sh")
  vars = {
    postgresql_endpoint = var.postgresql_endpoint
    sonarqube_password=var.sonarqube_password
    sonarqube_user=var.sonarqube_user
    sonarqube_database=var.sonarqube_database
  }
}
resource "aws_instance" "utility" {
  ami = var.utility_ami
  instance_type = var.instance_type_utility
  user_data = data.template_file.userdata.rendered
  key_name = var.pem_key_name
  subnet_id = var.subnet_id
  disable_api_termination = true
  vpc_security_group_ids = [aws_security_group.utility_sg.id]
  # associate_public_ip_address = true
  ebs_block_device {
    device_name = "/dev/xvda"
    volume_size = var.volume_size_utility
  }
  depends_on = [
    aws_key_pair.ssh_key
  ]
  tags = {
    Name = "nw-social-utility"
  }
}
resource "aws_security_group" "utility_sg" {
  name = "nw-social-utility-sg"
  vpc_id =  var.vpc_id
  ingress {
    description = "ingress rules"
    cidr_blocks = [var.vpc_cidr_block]
    from_port = 22
    protocol = "tcp"
    to_port = 22
  }
  ingress {
    description = "ingress rules"
    cidr_blocks = [var.vpc_cidr_block,"182.71.160.184/29","61.12.91.216/29"]
    from_port = 9000
    protocol = "tcp"
    to_port = 9000
  }
  ingress {
    description = "ingress rules"
    cidr_blocks = [var.vpc_cidr_block,"182.71.160.184/29","61.12.91.216/29"]
    from_port = 80
    protocol = "tcp"
    to_port = 80
  }
  egress {
    description = "egress rules"
    cidr_blocks = [ "0.0.0.0/0" ]
    from_port = 0
    protocol = "-1"
    to_port = 0
  }
  tags = {
    Name = "nw-social-utility-sg"
  }
}