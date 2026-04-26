# infra/terraform/proxmox-smoke-vm/variables.tf
#
# Input variables for the Phase 08 Proxmox Smoke VM configuration.
# Sensitive values must be passed via environment variables (TF_VAR_).

# -----------------------------------------------------------------------------
# Authentication & Connection
# -----------------------------------------------------------------------------

# Proxmox API endpoint, for example:
# https://<PROXMOX_HOST_OR_IP>:8006/
#
# Passed through TF_VAR_proxmox_endpoint at runtime.
variable "proxmox_endpoint" {
  type        = string
  description = "Proxmox VE API endpoint."
}

# Proxmox API token, for example:
# root@pam!<TOKEN_ID>=<TOKEN_VALUE>
#
# Passed through TF_VAR_proxmox_api_token at runtime.
# Marked sensitive so Terraform hides it in normal output.
variable "proxmox_api_token" {
  type        = string
  description = "Proxmox VE API token."
  sensitive   = true
}

# Temporary Cloud-Init password for the disposable smoke VM.
#
# Passed through TF_VAR_smoke_vm_ci_password at runtime.
# Marked sensitive so Terraform hides it in normal output.
variable "smoke_vm_ci_password" {
  type        = string
  description = "Temporary Cloud-Init password for the disposable smoke VM."
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Target Infrastructure
# -----------------------------------------------------------------------------

# Proxmox node name from the verified Proxmox host output.
variable "node_name" {
  type        = string
  description = "Proxmox node name."
  default     = "sd-178532"
}

# Target datastore for the cloned VM disk and Cloud-Init drive.
variable "datastore_id" {
  type        = string
  description = "Proxmox datastore used for the smoke VM."
  default     = "vmdata"
}

# -----------------------------------------------------------------------------
# Virtual Machine Definition
# -----------------------------------------------------------------------------

# Existing workload-ready template VMID from Phase 04/05.
variable "template_vm_id" {
  type        = number
  description = "Source Proxmox template VMID."
  default     = 9010
}

# Disposable Terraform smoke VMID.
variable "smoke_vm_id" {
  type        = number
  description = "Disposable Terraform smoke VMID."
  default     = 9300
}

# Disposable Terraform smoke VM name.
variable "smoke_vm_name" {
  type        = string
  description = "Disposable Terraform smoke VM name."
  default     = "ubuntu-2404-terraform-smoke-01"
}

# -----------------------------------------------------------------------------
# Network Configuration
# -----------------------------------------------------------------------------

# Static IPv4 configuration for the disposable smoke VM.
variable "smoke_vm_ip_cidr" {
  type        = string
  description = "Static IPv4 CIDR for the disposable smoke VM."
  default     = "10.10.10.30/24"
}

# Gateway for the private Proxmox VM network.
variable "smoke_vm_gateway" {
  type        = string
  description = "Default gateway for the disposable smoke VM."
  default     = "10.10.10.1"
}

# DNS resolver applied through Cloud-Init.
variable "smoke_vm_dns" {
  type        = string
  description = "DNS resolver for the disposable smoke VM."
  default     = "1.1.1.1"
}
