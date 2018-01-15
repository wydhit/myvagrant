require 'yaml' #解析配置文件用的

VAGRANTFILE_API_VERSION ||= "2"

confDir = $confDir ||= File.expand_path(File.dirname(__FILE__))
configPath = confDir + "/config.yaml" #主要配置文件


require File.expand_path(File.dirname(__FILE__) + '/scripts/ConfigVagrant.rb')

Vagrant.require_version '>= 1.9.0'

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  if File.exist? configPath then
    settings = YAML::load(File.read(configPath))
  else
    abort " settings file not found in #{confDir}"
  end

  ConfigVagrant.configure(config, settings)


  if settings.include? "afterSh" then
    afterScriptPath = confDir +'/' + settings["afterSh"]
    if File.exist? afterScriptPath then
      config.vm.provision "shell", path: afterScriptPath, privileged: false, keep_color: true
    end
  end

=begin
    if Vagrant.has_plugin?('vagrant-hostsupdater')
        config.hostsupdater.aliases = settings['sites'].map { |site| site['map'] }
    elsif Vagrant.has_plugin?('vagrant-hostmanager')
        config.hostmanager.enabled = true
        config.hostmanager.manage_host = true
        config.hostmanager.aliases = settings['sites'].map { |site| site['map'] }
    end
=end
end
