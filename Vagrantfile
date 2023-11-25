Vagrant.configure("2") do |config|

  base_ip = "10.0.0."

  config.vm.box = "ubuntu/jammy64"

  config.vm.provision "shell", inline: <<-SHELL
    apt-get update -y
    echo "#{base_ip}10  kubemaster" >> /etc/hosts
    #{(0..2).map { |i| "echo \"#{base_ip}1#{i}  kubenode0#{i}\" >> /etc/hosts" }.join("\n")}
  SHELL

  config.vm.define "kubemaster" do |node|
    node.vm.provider "virtualbox" do |vb|
      vb.name = "kubemaster"
      vb.memory = 2048
      vb.cpus = 2
    end
    node.vm.hostname = "kubemaster"
    node.vm.network "private_network", ip: "#{base_ip}10"
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
      node.vm.network "private_network", ip: "#{base_ip}1#{i}"
      node.vm.network "public_network", bridge: "Intel(R) Wi-Fi 6 AX201 160MHz"
    end
  end
end
