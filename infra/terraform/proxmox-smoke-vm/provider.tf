# infra/terraform/proxmox-smoke-vm/provider.tf
#
# This configuration utilizes the `bpg/proxmox` provider for API-driven provisioning.
# `bpg/proxmox` is an actively maintained Terraform Provider that translates HCL 
# safely into native Proxmox REST API calls.

# -----------------------------------------------------------------------------
# Terraform Settings
# -----------------------------------------------------------------------------

# Pin the Terraform provider source used for Proxmox VE automation.
# The `bpg/proxmox` provider manages Proxmox resources through the Proxmox API.
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.70"
    }
  }
}

# -----------------------------------------------------------------------------
# Provider Configuration
# -----------------------------------------------------------------------------

# Configure the Proxmox provider.
# The endpoint and API token are injected through Terraform env variables (TF_VAR_*)
# to prevent secrets leaking into version control  
provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token

  # Disable TLS verification, so Proxmox defaults to self-signed certificates.
  # This prevents certificate-trust errors for this isolated private-network smoke test.
  insecure = true
}