# Registro de excepciones de seguridad

Hallazgos de Checkov que no se corrigieron, con la decisión tomada y su justificación.
Cada excepción está marcada en el código con `#checkov:skip` y debe revisarse en la fecha indicada.

- **Entorno:** dev (prototipo HackIAthon)
- **Responsable:** K4lig
- **Última revisión:** 2026-10-08

## Container Registry (azurerm_container_registry.main)

| ID | Hallazgo | Decisión | Justificación | Control compensatorio | Revisar |
|---|---|---|---|---|---|
| CKV_AZURE_163 | Escaneo de vulnerabilidades en ACR | Aceptado | Requiere Defender for Containers (costo) | Trivy obligatorio en CI bloquea imágenes con CVEs críticos/altos antes del push | Antes de producción |
| CKV_AZURE_166 | Cuarentena y verificación de imágenes | Aceptado | Requiere SKU Premium | Trivy obligatorio en CI; solo el pipeline publica imágenes | Antes de producción |
| CKV_AZURE_164 | Imágenes firmadas (content trust) | Aceptado | Requiere SKU Premium | Firma con Cosign y verificación con Kyverno (fase extra) | Antes de producción |
| CKV_AZURE_139 | Acceso público deshabilitado | Aceptado | Private endpoint requiere SKU Premium | Usuario admin desactivado; acceso solo por identidades con RBAC (AKS y pipeline vía OIDC) | Antes de producción |
| CKV_AZURE_237 | Data endpoints dedicados | Aceptado | Requiere SKU Premium | Acceso solo por identidades con RBAC | Antes de producción |
| CKV_AZURE_167 | Retención de manifiestos sin tag | Aceptado | Requiere SKU Premium | Entorno efímero; el registro se destruye con el entorno | Antes de producción |
| CKV_AZURE_233 | Redundancia de zona | Aceptado | Control de disponibilidad, no de seguridad; requiere Premium | No aplica a prototipo | Antes de producción |
| CKV_AZURE_165 | Geo-replicación | Aceptado | Control de disponibilidad; despliegue en una sola región | No aplica a prototipo | Antes de producción |

## Key Vault (azurerm_key_vault.main)

| ID | Hallazgo | Decisión | Justificación | Control compensatorio | Revisar |
|---|---|---|---|---|---|
| CKV_AZURE_110 | Purge protection | Aceptado | Entorno dev que se destruye y recrea; la protección impide eliminarlo por completo | Soft delete de 7 días activo; sin secretos de producción | Antes de producción |
| CKV_AZURE_42 | Vault recuperable | Aceptado | Mismo motivo que CKV_AZURE_110 | Soft delete de 7 días activo | Antes de producción |
| CKV2_AZURE_32 | Private endpoint | Diferido | Se implementa junto con AKS | Firewall con `default_action = Deny` y solo IP administrativa permitida | Día 5 (2026-10-10) |
| CKV_AZURE_189 | Acceso de red público deshabilitado | Diferido | Se implementa junto con AKS y el private endpoint | Firewall por IP; autorización solo por RBAC | Día 5 (2026-10-10) |

## Hallazgos corregidos

| ID | Hallazgo | Corrección | Fecha |
|---|---|---|---|
| CKV2_AZURE_31 | Subred sin NSG | NSG asociado a la subred de private endpoints | 2026-10-08 |
| CKV_AZURE_109 | Key Vault sin firewall | `network_acls` con Deny por defecto e IP administrativa | 2026-10-08 |
