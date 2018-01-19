class ConfigVagrant
  def ConfigVagrant.configure(config, settings)
    ENV['VAGRANT_DEFAULT_PROVIDER'] = settings["provider"] ||= "virtualbox"
    config.vm.box_check_update = false #不检查升级
    scriptDir = File.dirname(__FILE__)
    config.vm.define settings["name"] ||= "vagrantName"
    config.vm.box = settings["box"] ||= "vagrant/ubuntu1604"
    config.vm.box_version = settings["version"] ||= ">= 1.0.0"
    config.vm.hostname = settings["hostname"] ||= "vagrant"
    config.vm.provider "virtualbox" do |vb|
      vb.name = settings["name"] ||= "vagrant"
      vb.customize ["modifyvm", :id, "--memory", settings["memory"] ||= "2048"]
      vb.customize ["modifyvm", :id, "--cpus", settings["cpus"] ||= "2"]
      vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
      vb.customize ["modifyvm", :id, "--natdnshostresolver1", settings["natdnshostresolver"] ||= "on"]
      vb.customize ["modifyvm", :id, "--ostype", "Ubuntu_64"]
      if settings.has_key?("gui") && settings["gui"]
        vb.gui = true
      end
    end

    networks(config, settings)
    authorize(config, settings)
    folders(config, settings)
  end

  #网络配置
  def ConfigVagrant.networks(config, settings)
    if settings["ip"] != "autonetwork"
      config.vm.network :private_network, ip: settings["ip"] ||= "192.168.10.10"
    else
      config.vm.network :private_network, :ip => "0.0.0.0", :auto_network => true
    end

    # Configure Additional Networks
    if settings.has_key?("networks")
      settings["networks"].each do |network|
        config.vm.network network["type"], ip: network["ip"], bridge: network["bridge"] ||= nil, netmask: network["netmask"] ||= "255.255.255.0"
      end
    end
    config.ssh.forward_agent = true
    config.ssh.username = settings["username"] ||= "ubuntu"
    if (settings.has_key?("default_ssh_port"))
      config.vm.network :forwarded_port, guest: 22, host: settings["default_ssh_port"], auto_correct: false, id: "ssh"
    end
    if (settings.has_key?("ports"))
      settings["ports"].each do |port|
        port["guest"] ||= port["to"]
        port["host"] ||= port["send"]
        port["protocol"] ||= "tcp"
      end
    else
      settings["ports"] = []
    end
    # Default Port Forwarding
    default_ports = {
        80 => 8000,
        443 => 44300,
        3306 => 33060,
        4040 => 4040,
        5432 => 54320,
        8025 => 8025,
        27017 => 27017
    }
    # Use Default Port Forwarding Unless Overridden
    unless settings.has_key?("default_ports") && settings["default_ports"] == false
      default_ports.each do |guest, host|
        unless settings["ports"].any? {|mapping| mapping["guest"] == guest}
          config.vm.network "forwarded_port", guest: guest, host: host, auto_correct: true
        end
      end
    end
    # Add Custom Ports From Configuration
    if settings.has_key?("ports")
      settings["ports"].each do |port|
        config.vm.network "forwarded_port", guest: port["guest"], host: port["host"], protocol: port["protocol"], auto_correct: true
      end
    end
  end

  def ConfigVagrant.authorize(config, settings)
    # Configure The Public Key For SSH Access
    if settings.include? 'authorize'
      if File.exists? File.expand_path(settings["authorize"])
        config.vm.provision "shell" do |s|
          s.name = 'authorized_keys'
          s.inline = "echo $1 | grep -xq \"$1\" /home/ubuntu/.ssh/authorized_keys || echo \"\n$1\" | tee -a /home/ubuntu/.ssh/authorized_keys"
          s.args = [File.read(File.expand_path(settings["authorize"]))]
        end
      end
    end

    # Copy The SSH Private Keys To The Box
    if settings.include? 'keys'
      if settings["keys"].to_s.length == 0
        puts "Check your config.yaml file, you have no private key(s) specified."
        exit
      end
      settings["keys"].each do |key|
        if File.exists? File.expand_path(key)
          config.vm.provision "shell" do |s|
            s.privileged = false
            s.name = "keys"
            s.inline = "echo \"$1\" > /home/ubuntu/.ssh/$2 && chmod 600 /home/ubuntu/.ssh/$2"
            s.args = [File.read(File.expand_path(key)), key.split('/').last]
          end
        else
          puts "Check your config.yaml file, the path to your private key does not exist."
          exit
        end
      end
    end
  end

  def ConfigVagrant.folders(config, settings)
    # 文件同步
    if settings.include? 'folders'
      settings["folders"].each do |folder|
        if  settings.include? 'dataDir'
          map=folder["map"].sub('{{dataDir}}',settings['dataDir'])
        else
          map=folder["map"]
        end
        if File.exists? File.expand_path(map)
          mount_opts = []
          if (folder["type"] == "nfs")
            mount_opts = folder["mount_options"] ? folder["mount_options"] : ['actimeo=1', 'nolock']
          elsif (folder["type"] == "smb")
            mount_opts = folder["mount_options"] ? folder["mount_options"] : ['vers=3.02', 'mfsymlinks']
          end
          # For b/w compatibility keep separate 'mount_opts', but merge with options
          options = (folder["options"] || {}).merge({mount_options: mount_opts})
          # Double-splat (**) operator only works with symbol keys, so convert
          options.keys.each {|k| options[k.to_sym] = options.delete(k)}
          config.vm.synced_folder map, folder["to"], type: folder["type"] ||= nil, **options
          # Bindfs support to fix shared folder (NFS) permission issue on Mac
          if (folder["type"] == "nfs")
            if Vagrant.has_plugin?("vagrant-bindfs")
              config.bindfs.bind_folder folder["to"], folder["to"]
            end
          end
        else
          puts map + "不存在 无法挂载 请检查配置"
        end
      end
    end

  end
end
