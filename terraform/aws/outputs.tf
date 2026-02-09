output "public_ip" {
  description = "Public IP address of the dev instance"
  value       = aws_instance.dev.public_ip
}
