output "public_ip" {
  description = "Public IP address of the dev VM"
  value       = azurerm_public_ip.dev.ip_address
}
