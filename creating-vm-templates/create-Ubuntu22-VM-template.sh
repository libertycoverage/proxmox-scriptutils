#!/bin/bash
ubuntuImgFromURL=https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img
ubuntuImgBaseURL=$(dirname $ubuntuImageFromURL)
ubuntuImgFilename=$(basename $ubuntuImageFromURL)
proxmoxTemplateID="${TMPL_ID:-9000}"
proxmoxTemplateName="${TMPL_NAME:-ubuntu-2204}"
scriptTemporaryPath=/tmp/proxmox-shellscript-execution


initialize () {
    [ $(id -u) == 0 ] && apt-get update && apt-get install sudo -y || exit 1
    clean
    installRequirements
    mkdir -p $scriptTemporaryPath
    vmDiskStorage="${PM_STORAGE:-$(sudo pvesm status | awk '$2 != "dir" {print $1}' | tail -n 1)}"
    cd $scriptTemporaryPath
}

installationOfRequirements () {
    sudo dpkg -l libguestfs-tools &> /dev/null || \
    sudo apt update -y && sudo apt install libguestfs-tools -y
}


getImage () {
    local _img=/tmp/$ubuntuImgFilename
    local imgSHA256SUM=$(curl -s $ubuntuImgBaseURL/SHA256SUMS | grep $ubuntuImgFilename | awk '{print $1}')
    if [ -f "$_img" ] && [[ $(sha256sum $_img | awk '{print $1}') == $imgSHA256SUM ]]
    then
        echo "The image file exists and the signature is OK"
    else
        wget $ubuntuImagFromURL -O $_img
    fi
    
    sudo cp $_img $ubuntuImgFilename
}



installQemuGA () {
    sudo virt-customize -a $ubuntuImgFilename \
    --run-command 'sudo apt update -y && sudo apt install qemu-guest-agent -y && sudo systemctl start qemu-guest-agent'
}

resetMachineID () {
    sudo virt-customize -x -a $ubuntuImgFilename \
    --run-command 'sudo echo -n >/etc/machine-id'
}

createProxmoxVMTemplate () {
##  sudo qm destroy $proxmoxTemplateID --purge || true
    sudo qm create $proxmoxTemplateID --name $proxmoxTemplateName --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0
    sudo qm importdisk $proxmoxTemplateID $ubuntuImgFilename $vmDiskStorage
    sudo qm set $proxmoxTemplateID --scsihw virtio-scsi-single --scsi0 $vmDiskStorage:vm-$proxmoxTemplateID-disk-0
    sudo qm set $proxmoxTemplateID --boot c --bootdisk scsi0
    sudo qm set $proxmoxTemplateID --ide2 $vmDiskStorage:cloudinit
    sudo qm set $proxmoxTemplateID --serial0 socket --vga serial0
    sudo qm set $proxmoxTemplateID --agent enabled=1,fstrim_cloned_disks=1
    sudo qm template $proxmoxTemplateID
}

clean () { 
    rm -rf $scriptTemporaryPath 
}


initialize
getImage
installQemuGA
resetMachineID
createProxmoxVMTemplate
clean



