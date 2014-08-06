# install sensu
include_recipe "sensu::default"
include_recipe "sensu::rabbitmq"
include_recipe "sensu::redis"
include_recipe "sensu::server_service"
include_recipe "sensu::api_service"
include_recipe "uchiwa"

# TODO: drop off SSL certs to be used for dashboard
include_recipe "nginx"
node.set[:nginx][:default_site_enabled] = false
template "/etc/nginx/sites-available/sensu" do
  source "nginx_conf.erb"
  notifies :reload, "service[nginx]"
  variables ({
    listen_address:       node[:ipaddress],
    listen_port:          if node[:uchiwa][:ssl][:enabled] then 443 else 80 end,
    uchiwa_address:       node[:uchiwa][:settings][:host],
    uchiwa_port:          node[:uchiwa][:settings][:port],
    log_dir:              node[:nginx][:log_dir],
    server_name:          node[:uchiwa][:server_name],
    ssl:                  node[:uchiwa][:ssl][:enabled],
    ssl_certificate:      node[:uchiwa][:ssl][:certificate],
    ssl_certificate_key:  node[:uchiwa][:ssl][:certificate_key],
  })
end
nginx_site "sensu"

# Add Sensu Filters
node[:sensu][:filters].each do |name, attributes|
  sensu_filter name do
    attributes attributes[:attributes]
    negate attributes[:negate]
  end
end

handler_directory = node[:sensu][:handlers_directory]
# add sensu handlers
node[:sensu][:handlers].each do |name, attributes|
  next unless attributes[:enabled]
  file_name = attributes[:file_name]

  cookbook_file "#{name} handler" do
    path "#{handler_directory}/#{file_name}"
    source "handlers/#{file_name}"
    mode 0555
  end

  sensu_handler name do
    type "pipe"
    command "#{handler_directory}/#{file_name}"
    filters attributes[:filters]
  end

  sensu_snippet name do
    content attributes[:config]
  end
end

# add sensu plugins
  # add files
  # make LWRP calls to generate config
# add sensu extensions
  # add files
  # make LWRP calls to generate config
# add sensu mutators
  # add files
  # make LWRP calls to generate config
# add sensu checks
  # this will be done by including an (hopefully) arbitrary recipe that will make LWRP calls
node[:sensu][:checks].each do |name, attributes|
  next unless attributes[:enabled]

  sensu_check name do
    command     attributes[:command]
    handlers    attributes[:handlers]
    subscribers attributes[:subscribers]
    interval    attributes[:interval]
    additional  attributes[:additional] if attributes[:additional]
  end
end
