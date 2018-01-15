class ConfigVagrant
  def ConfigVagrant.configure(config, settings)
    # Set The VM Provider
    config.vm.box_check_update = false #不检查升级
    ENV['VAGRANT_DEFAULT_PROVIDER'] = settings["provider"] ||= "virtualbox"

    # Configure Local Variable To Access Scripts From Remote Location
    scriptDir = File.dirname(__FILE__)

    # Allow SSH Agent Forward from The Box
    config.ssh.forward_agent = true
    config.ssh.username = settings["username"] ||= "ubuntu"

    # Configure The Box
    config.vm.define settings["name"] ||= "vagrantName"
    config.vm.box = settings["box"] ||= "vagrant/ubuntu1604"
    config.vm.box_version = settings["version"] ||= ">= 1.0.0"
    config.vm.hostname = settings["hostname"] ||= "vagrant"

    # Configure A Private Network IP
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

    # Configure A Few VirtualBox Settings
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

    # Override Default SSH port on the host
    if (settings.has_key?("default_ssh_port"))
      config.vm.network :forwarded_port, guest: 22, host: settings["default_ssh_port"], auto_correct: false, id: "ssh"
    end

    # Standardize Ports Naming Schema
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
    # Configure The Public Key For SSH Access
    if settings.include? 'authorize'
      if File.exists? File.expand_path(settings["authorize"])
        config.vm.provision "shell" do |s|
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
            s.inline = "echo \"$1\" > /home/ubuntu/.ssh/$2 && chmod 600 /home/ubuntu/.ssh/$2"
            s.args = [File.read(File.expand_path(key)), key.split('/').last]
          end
        else
          puts "Check your config.yaml file, the path to your private key does not exist."
          exit
        end
      end
    end

    #更改php版本
    defaultPhpVersion = settings["defaultPhpVersion"] ||= "php5.6"
    config.vm.provision "shell" do |s|
      s.name = "更改php版本" + defaultPhpVersion
      s.path = scriptDir + "/changePhpDefaultVersion.sh"
      s.args = [defaultPhpVersion]
    end

    # Copy User Files Over to VM
    if settings.include? 'copy'
      settings["copy"].each do |file|
        config.vm.provision "file" do |f|
          f.source = File.expand_path(file["from"])
          f.destination = file["to"].chomp('/') + "/" + file["from"].split('/').last
        end
      end
    end

    # Register All Of The Configured Shared Folders
    if settings.include? 'folders'
      settings["folders"].each do |folder|
        if File.exists? File.expand_path(folder["map"])
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
          config.vm.synced_folder folder["map"], folder["to"], type: folder["type"] ||= nil, **options
          # Bindfs support to fix shared folder (NFS) permission issue on Mac
          if (folder["type"] == "nfs")
            if Vagrant.has_plugin?("vagrant-bindfs")
              config.bindfs.bind_folder folder["to"], folder["to"]
            end
          end
        else
          config.vm.provision "shell" do |s|
            s.inline = ">&2 echo \"Unable to mount one of your folders. Please check your folders in config.yaml\""
          end
        end
      end
    end

    if settings.include? 'sites'
      config.vm.provision "shell" do |s|
        s.inline = "echo '清理nginx站点配置' && sudo rm -rf /usr/local/nginx/conf/vhost/*"
      end
      settings["sites"].each do |site|
        if site.include? 'domain' then
          if site["domain"].to_s.length > 0 then #必须配置domain 不然就忽略这条配置
            domain = site["domain"]
            webpath = site["webpath"] ||= "/data/wwwroot/" + domain
            logpath = site["logpath"] ||= "/data/wwwlogs/" + domain + ".log"
            phpversion = site["phpversion"] ||= "5.6"
            type = site["type"] ||= "common"
            config.vm.provision "shell" do |s|
              s.name = "创建站点" + site["domain"]
              s.path = scriptDir + "/sites-" + type + ".sh"
              s.args = [domain, webpath, logpath, phpversion]
            end
          end
        end
      end
    end


=begin
        # Configure All Of The Server Environment Variables
        #config.vm.provision "shell" do |s|
        #    s.name = "Clear Variables"
        #    s.path = scriptDir + "/clear-variables.sh"
        #end
=end

=begin
        if settings.has_key?("variables")
            settings["variables"].each do |var|
                config.vm.provision "shell" do |s|
                    s.inline = "echo \"\nenv[$1] = '$2'\" >> /etc/php/5.6/fpm/pool.d/www.conf"
                    s.args = [var["key"], var["value"]]
                end

                config.vm.provision "shell" do |s|
                    s.inline = "echo \"\nenv[$1] = '$2'\" >> /etc/php/7.0/fpm/pool.d/www.conf"
                    s.args = [var["key"], var["value"]]
                end

                config.vm.provision "shell" do |s|
                    s.inline = "echo \"\nenv[$1] = '$2'\" >> /etc/php/7.1/fpm/pool.d/www.conf"
                    s.args = [var["key"], var["value"]]
                end

                config.vm.provision "shell" do |s|
                    s.inline = "echo \"\nenv[$1] = '$2'\" >> /etc/php/7.2/fpm/pool.d/www.conf"
                    s.args = [var["key"], var["value"]]
                end

                config.vm.provision "shell" do |s|
                    s.inline = "echo \"\n# Set Homestead Environment Variable\nexport $1=$2\" >> /home/vagrant/.profile"
                    s.args = [var["key"], var["value"]]
                end
            end

            config.vm.provision "shell" do |s|
                s.inline = "service php5.6-fpm restart; service php7.0-fpm restart; service php7.1-fpm restart; service php7.2-fpm restart;"
            end
        end
=end

=begin
        config.vm.provision "shell" do |s|
            s.name = "Restarting Cron"
            s.inline = "sudo service cron restart"
        end
=end

=begin
        config.vm.provision "shell" do |s|
            s.name = "Restarting Nginx"
            s.inline = "sudo service nginx restart; sudo service php5.6-fpm restart; sudo service php7.0-fpm restart; sudo service php7.1-fpm restart; sudo service php7.2-fpm restart"
        end
=end

=begin
        # Install MariaDB If Necessary
        if settings.has_key?("mariadb") && settings["mariadb"]
            config.vm.provision "shell" do |s|
                s.path = scriptDir + "/install-maria.sh"
            end
        end
=end

=begin
        # Install MongoDB If Necessary
        if settings.has_key?("mongodb") && settings["mongodb"]
            config.vm.provision "shell" do |s|
                s.path = scriptDir + "/install-mongo.sh"
            end
        end
=end

=begin
        # Install CouchDB If Necessary
        if settings.has_key?("couchdb") && settings["couchdb"]
            config.vm.provision "shell" do |s|
                s.path = scriptDir + "/install-couch.sh"
            end
        end
=end

=begin
        # Install Elasticsearch If Necessary
        if settings.has_key?("elasticsearch") && settings["elasticsearch"]
            config.vm.provision "shell" do |s|
                s.name = "Installing Elasticsearch"
                if settings["elasticsearch"] == 6
                    s.path = scriptDir + "/install-elasticsearch6.sh"
                else
                    s.path = scriptDir + "/install-elasticsearch5.sh"
                end
            end
        end
=end

=begin
        # Configure All Of The Configured Databases
        if settings.has_key?("databases")
            settings["databases"].each do |db|
                config.vm.provision "shell" do |s|
                    s.name = "Creating MySQL Database: " + db
                    s.path = scriptDir + "/create-mysql.sh"
                    s.args = [db]
                end

                config.vm.provision "shell" do |s|
                    s.name = "Creating Postgres Database: " + db
                    s.path = scriptDir + "/create-postgres.sh"
                    s.args = [db]
                end

                if settings.has_key?("mongodb") && settings["mongodb"]
                    config.vm.provision "shell" do |s|
                        s.name = "Creating Mongo Database: " + db
                        s.path = scriptDir + "/create-mongo.sh"
                        s.args = [db]
                    end
                end

                if settings.has_key?("couchdb") && settings["couchdb"]
                    config.vm.provision "shell" do |s|
                        s.name = "Creating Couch Database: " + db
                        s.path = scriptDir + "/create-couch.sh"
                        s.args = [db]
                    end
                end
            end
        end
=end

=begin
        # Update Composer On Every Provision
        config.vm.provision "shell" do |s|
            s.name = "Update Composer"
            s.inline = "sudo /usr/local/bin/composer self-update --no-progress && sudo chown -R vagrant:vagrant /home/vagrant/.composer/"
            s.privileged = false
        end
=end

=begin
        # Configure Blackfire.io
        if settings.has_key?("blackfire")
            config.vm.provision "shell" do |s|
                s.path = scriptDir + "/blackfire.sh"
                s.args = [
                    settings["blackfire"][0]["id"],
                    settings["blackfire"][0]["token"],
                    settings["blackfire"][0]["client-id"],
                    settings["blackfire"][0]["client-token"]
                ]
            end
        end
=end

=begin
        # Add config file for ngrok
        config.vm.provision "shell" do |s|
            s.path = scriptDir + "/create-ngrok.sh"
            s.args = [settings["ip"]]
            s.privileged = false
        end
=end
  end
end