# infra/terraform/proxmox-smoke-vm/main.tf
#
# Provisions one disposable Proxmox VM 
# Clones the already existing workload-ready template from Phase 04/05 
# while keeping the live K3s target VM 9200 untouched 

# -----------------------------------------------------------------------------
# Proxmox VM Resource
# -----------------------------------------------------------------------------

# Instantiates the isolated IaC Smoke VM
resource "proxmox_virtual_environment_vm" "smoke_vm" {
  name      = var.smoke_vm_name
  node_name = var.node_name
  vm_id     = var.smoke_vm_id

  # Resource Allocation:
  # Kept small to prove IaC provisioning without competing for host resources 
  # with the live target VM 9200
  cpu {
    cores = 2
  }

  memory {
    dedicated = 2048
  }

  # Clone configuration:
  # VM 9010 was already verified prior to this phase as the workload-ready template.
  clone {
    vm_id = var.template_vm_id
    full  = true
  }

  # Keep QEMU guest agent enabled to allow Proxmox to report guest-side data.
  agent {
    enabled = true
  }

  # ---------------------------------------------------------------------------
  # Cloud-Init Initialization
  # ---------------------------------------------------------------------------

  # Configure Cloud-Init values for the smoke VM.
  initialization {
    datastore_id = var.datastore_id

    # Cloud-Init drive interface used by the cloned VM.
    # Must match the template layout established in Phase 04 (`qm config 9010`)
    interface = "ide2"

    # Configure the smoke VM user and temporary password through Cloud-Init.
    user_account {
      username = "ubuntu"
      password = var.smoke_vm_ci_password
    }

    # Apply the static private IP address and gateway for the smoke VM.
    ip_config {
      ipv4 {
        address = var.smoke_vm_ip_cidr
        gateway = var.smoke_vm_gateway
      }
    }

    # Apply deterministic DNS to avoid first-boot name-resolution ambiguity.
    dns {
      servers = [var.smoke_vm_dns]
    }
  }

  # ---------------------------------------------------------------------------
  # Lifecycle & Tagging
  # ---------------------------------------------------------------------------

    # Start the smoke VM automatically after provisioning so boot and connectivity can be verified.
  started = true

  # Add tags so the VM is (visibly) marked as "disposable project artifact".
  tags = [
    "phase-08",
    "terraform",
    "smoke-vm"
  ]
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

# Expose the smoke VM ID after apply.
output "smoke_vm_id" {
  description = "Disposable Terraform smoke VMID."
  value       = proxmox_virtual_environment_vm.smoke_vm.vm_id
}

# Expose the smoke VM name after apply.
output "smoke_vm_name" {
  description = "Disposable Terraform smoke VM name."
  value       = proxmox_virtual_environment_vm.smoke_vm.name
}

# Expose the configured smoke VM IP after apply.
output "smoke_vm_ip_cidr" {
  description = "Configured static IPv4 CIDR for the disposable smoke VM."
  value       = var.smoke_vm_ip_cidr
}