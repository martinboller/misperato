Vagrant.configure("2") do |config|

# MISP Server misperato

  config.vm.define "misperato" do |cfg|
    cfg.vm.box = "generic/debian12" #was ubuntu/jammy64
    cfg.vm.hostname = "misperato"
    cfg.vm.network "public_network", type: "dhcp", bridge: 'enp1s0', mac: "0020911EFEDE"
    cfg.vm.provision :file, source: './installfiles', destination: "/tmp/installfiles"
    cfg.vm.provision :file, source: './installfiles/.env', destination: "/tmp/installfiles/.env"
    cfg.vm.provision :shell, path: "bootstrap.sh"
    cfg.vm.provision "reload"
    #cfg.vm.provision :shell, path: "installfiles/install-gse.sh"

    cfg.vm.provider "vmware_fusion" do |v, override|
      v.vmx["displayname"] = "misperato"
      v.memory = 5120
      v.cpus = 4
      v.gui = false
    end

    cfg.vm.provider "vmware_desktop" do |v, override|
      v.vmx["displayname"] = "misperato"
      v.memory = 5120
      v.cpus = 4
      v.gui = false
    end

    cfg.vm.provider "virtualbox" do |vb, override|
      vb.gui = false
      vb.name = "misperato"
      vb.customize ["modifyvm", :id, "--memory", 10240]
      vb.customize ["modifyvm", :id, "--cpus", 4]
      vb.customize ["modifyvm", :id, "--vram", "8"]
      vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
      vb.customize ["setextradata", "global", "GUI/SuppressMessages", "all" ]
    end
  end
end
