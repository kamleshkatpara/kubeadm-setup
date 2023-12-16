Vagrant.configure("2") do |config|

  private_network_base_ip = "10.0.0."

  config.vm.box = "ubuntu/jammy64"

  # SSH Configuration
  config.ssh.insert_key = false
  config.vm.provision "file", source: "~/.ssh/id_rsa", destination: ".ssh/id_rsa"
  config.vm.provision "file", source: "~/.ssh/id_rsa.pub", destination: ".ssh/id_rsa.pub"

  config.vm.provision "shell", inline: <<-SHELL
    USER_HOME=$(getent passwd vagrant | cut -d: -f6)
    cat $USER_HOME/.ssh/id_rsa.pub >> $USER_HOME/.ssh/authorized_keys
    echo "#{private_network_base_ip}10  kubemaster" >> /etc/hosts
    echo "#{private_network_base_ip}11  kubenode01" >> /etc/hosts
    echo "#{private_network_base_ip}12  kubenode02" >> /etc/hosts
  SHELL

  config.vm.define "kubemaster" do |node|
    node.vm.provider "virtualbox" do |vb|
      vb.name = "kubemaster"
      vb.memory = 2048
      vb.cpus = 2
    end
    node.vm.hostname = "kubemaster"
    node.vm.network "private_network", ip: "#{private_network_base_ip}10"
    node.vm.network "public_network", bridge: "Intel(R) Wi-Fi 6 AX201 160MHz"
  end

  (1..2).each do |i|
    config.vm.define "kubenode0#{i}" do |node|
      node.vm.provider "virtualbox" do |vm|
        vm.name = "kubenode0#{i}"
        vm.memory = 1024
        vm.cpus = 1
      end
      node.vm.hostname = "kubenode0#{i}"
      node.vm.network "private_network", ip: "#{private_network_base_ip}1#{i}"
      node.vm.network "public_network", bridge: "Intel(R) Wi-Fi 6 AX201 160MHz"
    end
  end
end
