variable "location" {
  type    = string
  default = "eastus2"
}

variable "project" {
  type    = string
  default = "hackops"
}

variable "env" {
  type    = string
  default = "dev"
}

variable "budget_email" {
  type        = string
  description = "Correo que recibe las alertas de presupuesto"
}

variable "admin_ips" {
  type        = list(string)
  description = "IPs públicas con acceso administrativo al Key Vault"
}
