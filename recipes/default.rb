# install sensu
include_recipe "sensu::default"
include_recipe "sensu::rabbitmq"
include_recipe "sensu::redis"
include_recipe "sensu::server_service"
include_recipe "sensu::api_service"
include_recipe "uchiwa"
include_recipe 'poise-monit'

# TODO: drop off SSL certs to be used for dashboard
if node[:sensu][:nginx][:ssl][:enabled]
  ssl_config = node[:sensu][:nginx][:ssl]
  secret = Chef::EncryptedDataBagItem.load_secret
  dashboard_ssl = Chef::EncryptedDataBagItem.load("sensu", "dashboard_ssl", secret)
  directory ssl_config[:directory] do
    recursive true
    action :create
  end
  file "#{ssl_config[:directory]}/#{ssl_config[:certificate]}" do
    content dashboard_ssl["ssl"]["cert"]
    action :create
  end
  file "#{ssl_config[:directory]}/#{ssl_config[:certificate_key]}" do
    content dashboard_ssl["ssl"]["key"]
    mode 0600
    action :create
  end
end

if node[:sensu][:nginx][:enabled]
  include_recipe "nginx"
  node.set[:nginx][:default_site_enabled] = false
  template "/etc/nginx/sites-available/sensu" do
    source "nginx_conf.erb"
    notifies :reload, "service[nginx]"
    variables ({
      listen_address:       node[:ipaddress],
      listen_port:          if node[:sensu][:nginx][:ssl][:enabled] then 443 else 80 end,
      uchiwa_address:       node[:uchiwa][:settings][:host],
      uchiwa_port:          node[:uchiwa][:settings][:port],
      log_dir:              node[:nginx][:log_dir],
      server_name:          node[:uchiwa][:server_name],
      sensu_api_address:    node[:sensu][:api][:host],
      sensu_api_post:       node[:sensu][:api][:port],
      ssl:                  node[:sensu][:nginx][:ssl][:enabled],
      ssl_directory:        node[:sensu][:nginx][:ssl][:directory],
      ssl_certificate:      node[:sensu][:nginx][:ssl][:certificate],
      ssl_certificate_key:  node[:sensu][:nginx][:ssl][:certificate_key],
    })
  end
  nginx_site "sensu"
end

# Add Sensu Filters
node[:sensu][:filters].each do |name, attributes|
  sensu_filter name do
    attributes attributes[:attributes]
    negate attributes[:negate]
  end
end

# Add Sensu Extensions
extension_directory = node[:sensu][:extensions_directory]
node[:sensu][:extensions].each do |name, attributes|
  next unless attributes[:enabled]
  file_name = attributes[:file_name]

  if file_name
    cookbook_file "#{name} handler" do
      path "#{extension_directory}/#{file_name}"
      source "extensions/#{file_name}"
      mode 0644
    end
  end

  if attributes[:gems]
    attributes[:gems].each do |gem_name, config|
      sensu_gem gem_name do
        version config[:version] if config[:version]
        action :install
      end
    end
  end

  sensu_snippet name do
    content attributes[:config]
  end if attributes[:config]
end

# Add Sensu Handlers
handler_directory = node[:sensu][:handlers_directory]
node[:sensu][:handlers].each do |name, attributes|
  next unless attributes[:enabled]
  file_name = attributes[:file_name]

  if file_name
    cookbook_file "#{name} handler" do
      path "#{handler_directory}/#{file_name}"
      source "handlers/#{file_name}"
      mode 0555
    end
  end

  if attributes[:gems]
    attributes[:gems].each do |gem_name, config|
      sensu_gem gem_name do
        version config[:version] if config[:version]
        action :install
      end
    end
  end

  sensu_handler name do
    type      attributes[:type] || "pipe"
    command   "#{handler_directory}/#{file_name}" if file_name
    filters   attributes[:filters]                if attributes[:filters]
    handlers  attributes[:handlers]               if attributes[:type] == "set"
  end

  sensu_snippet name do
    content attributes[:config]
  end if attributes[:config]
end

# Add checks to test alerting pipeline
# -- TODO: right now this is pretty specific to LMC. In the future we should really
#          look at making this more generalized. (mostly wrt the check handler used)
["ok", "warning", "critical"].each do |severity|
  sensu_check "test-check-#{severity}" do
    command             "/etc/sensu/plugins/test-check.rb -l #{severity}"
    handlers            ["lmc_alerting"]
    interval            90
    subscribers         ["nothing"]
  end
end


monit_config 'mailconfig' do
  content <<-EOH
SET MAILSERVER #{node[:monit][:alert][:mail][:server]}
SET ALERT #{node[:monit][:alert][:mail][:to]} with reminder on #{node[:monit][:alert][:mail][:cycles]} cycles 
EOH
end

# Uchiwa latest version 0.14.0-1 fails when specified in environment, but it exists in the apt repo.
package "uchiwa" do
  action :upgrade
end

monit_check 'uchiwa' do
  check "if changed pid then exec #{node[:monit][:alert][:slack][:script_file]}\n if does not exist then restart \n if does not exist then exec #{node[:monit][:alert][:slack][:script_file]}"
  start_program '/etc/init.d/uchiwa start'
  stop_program '/etc/init.d/uchiwa stop'
end

monit_check 'sensu-api' do
  check "if changed pid then exec #{node[:monit][:alert][:slack][:script_file]}\n if does not exist then restart \n if does not exist then exec #{node[:monit][:alert][:slack][:script_file]}"
  start_program '/etc/init.d/sensu-api start'
  stop_program '/etc/init.d/sensu-api stop'
  with 'PIDFILE /var/run/sensu/sensu-api.pid'
end

monit_check 'sensu-client' do
  check "if changed pid then exec #{node[:monit][:alert][:slack][:script_file]}\n if does not exist then restart \n if does not exist then exec #{node[:monit][:alert][:slack][:script_file]}"
  start_program '/etc/init.d/sensu-client start'
  stop_program '/etc/init.d/sensu-client stop'
  with 'PIDFILE /var/run/sensu/sensu-client.pid'
end

monit_check 'sensu-server' do
  check "if changed pid then exec #{node[:monit][:alert][:slack][:script_file]}\n if does not exist then restart \n if does not exist then exec #{node[:monit][:alert][:slack][:script_file]}"
  start_program '/etc/init.d/sensu-server start'
  stop_program '/etc/init.d/sensu-server stop'
  with 'PIDFILE /var/run/sensu/sensu-server.pid'
end

monit_check 'redis' do
  check "if changed pid then exec #{node[:monit][:alert][:slack][:script_file]}\n if does not exist then restart \n if does not exist then exec #{node[:monit][:alert][:slack][:script_file]}"
  start_program '/etc/init.d/redis6379 start'
  stop_program '/etc/init.d/redis6379 stop'
  with 'PIDFILE /var/run/redis/6379/redis_6379.pid'
end

monit_check 'rabbitmq' do
  check "if changed pid then exec #{node[:monit][:alert][:slack][:script_file]}\n if does not exist then restart \n if does not exist then exec #{node[:monit][:alert][:slack][:script_file]}"
  start_program '/etc/init.d/rabbitmq-server start'
  stop_program '/etc/init.d/rabbitmq-server stop'
  with 'PIDFILE /var/run/rabbitmq/pid'
end

monit_check 'nginx' do
  check "if changed pid then exec #{node[:monit][:alert][:slack][:script_file]}\n if does not exist then restart \n if does not exist then exec #{node[:monit][:alert][:slack][:script_file]}"
  start_program '/etc/init.d/nginx start'
  stop_program '/etc/init.d/nginx stop'
end

monit_check 'influxdb' do
  check_type 'host'
  check "if failed port 8086 for 5 cycles then exec #{node[:monit][:alert][:slack][:script_file]}"
  with "address #{node[:sensu][:extensions][:influxdb][:config][:host]}" 
  extra [ 'repeat every 5 cycles' ]
end

monit_check 'elasticsearch-health' do
  check_type 'host'
  check "if failed url http://elk-client.edu.cybera.ca:9200/_cluster/health and content =='green' with timeout 60 seconds then exec  #{node[:monit][:alert][:slack][:script_file]}" 
  with "address elk-client.edu.cybera.ca" 
  extra [ 'repeat every 30 cycles' ]
end

# Ruby required for slack notifications
package "ruby" do
  action :install
end

package "ruby-dev" do
  action :install
end

# Copy slack notification script
template "#{node[:monit][:alert][:slack][:script_file]}" do
  source 'slack.rb.erb'
  mode '0555'
  owner 'root'
  group 'root'
end

