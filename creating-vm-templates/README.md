

## Building an Ubuntu 22.04 template on Proxmox VE with cloud-init mechanisms


On Proxmox server (OS host shell)
> curl -s https://raw.githubusercontent.com/libertycoverage/proxmox-scriptutils/main/creating-vm-templates/create-Ubuntu22-VM-template.sh | sudo bash


Verify that the template ubuntu-2204 has been created
> qm list | grep ubuntu


configurations

#### (Optional) ID of the VM template to be created. Default: 9000
export TMPL_ID=YOUR_PROXMOX_VM_TEMPLATE_ID

#### (Optional) Name of the VM template to be created. Default: ubuntu-2204
export TMPL_NAME=YOUR_PROXMOX_VM_TEMPLATE_NAME

#### (Optional) The Proxmox storage ID where the VM is stored. Default: auto selected
export PM_STORAGE=YOUR_PROXMOX_STORAGE_ID
