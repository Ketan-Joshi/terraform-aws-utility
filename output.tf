output "private_ip" {
  value = aws_instance.utility.private_ip
}
output "utility_pem_file" {
  value = tls_private_key.ssh_private_key.private_key_pem
}