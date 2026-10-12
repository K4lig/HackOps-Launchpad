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

variable "aks_vm_size" {
  type    = string
  default = "Standard_B2s"
}

variable "github_repo" {
  type    = string
  default = "K4lig@119822340/HackOps-Launchpad@1408025958"
}

variable "ado_issuer" {
  type        = string
  description = "Issuer OIDC de la conexion de servicio de Azure DevOps"
}

variable "ado_subject" {
  type        = string
  description = "Subject de la conexion de servicio de Azure DevOps"
}

variable "tfstate_storage_account" {
  type        = string
  description = "Storage account que guarda el state de Terraform"
}
