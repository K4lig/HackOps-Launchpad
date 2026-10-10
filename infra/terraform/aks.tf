resource "azurerm_kubernetes_cluster" "main" {
  #checkov:skip=CKV_AZURE_117:Discos cifrados con claves de plataforma por defecto; CMK requiere purge protection, no aplica a dev efimero
  #checkov:skip=CKV_AZURE_226:Standard_B2s no tiene cache suficiente para disco efimero; en prod usar VM compatible
  #checkov:skip=CKV_AZURE_4:Pendiente Dia 7, Container Insights junto con observabilidad
  #checkov:skip=CKV_AZURE_232:Un solo pool por costo; en prod separar pool de sistema y de usuario
  #checkov:skip=CKV_AZURE_115:Compensado con authorized_ip_ranges, Entra ID RBAC y cuentas locales desactivadas
  #checkov:skip=CKV_AZURE_116:Compensado con Pod Security Admission restricted por namespace
  #checkov:skip=CKV_AZURE_170:Control de disponibilidad (SLA), no de seguridad; no aplica a prototipo
  name                = "aks-${local.name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "aks-${local.name}"
  sku_tier            = "Free"

  automatic_upgrade_channel = "patch"
  node_os_upgrade_channel   = "NodeImage"

  local_account_disabled    = true
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  default_node_pool {
    name                        = "system"
    vm_size                     = var.aks_vm_size
    vnet_subnet_id              = azurerm_subnet.aks.id
    auto_scaling_enabled        = true
    min_count                   = 1
    max_count                   = 3
    max_pods                    = 50
    temporary_name_for_rotation = "tmpsystem"
    host_encryption_enabled     = true
  }

  node_provisioning_profile {
    mode = "Manual"
  }

  identity {
    type = "SystemAssigned"
  }

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled = true
    tenant_id          = data.azurerm_client_config.current.tenant_id
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_data_plane  = "cilium"
    network_policy      = "cilium"
    pod_cidr            = "192.168.0.0/16"
    service_cidr        = "10.0.0.0/16"
    dns_service_ip      = "10.0.0.10"
  }

  api_server_access_profile {
    authorized_ip_ranges = [for ip in var.admin_ips : "${ip}/32"]
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  tags = local.tags
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                            = azurerm_container_registry.main.id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "aks_admin_me" {
  scope                = azurerm_kubernetes_cluster.main.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = data.azurerm_client_config.current.object_id
}
