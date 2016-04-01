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
  check "if does not exist then restart \n if does not exist then exec #{node[:monit][:alert][:slack][:script_file]}"
  start_program '/etc/init.d/uchiwa start'
  stop_program '/etc/init.d/uchiwa stop'
end

monit_check 'sensu-api' do
  check "if does not exist then restart \n if does not exist then exec #{node[:monit][:alert][:slack][:script_file]}"
  start_program '/etc/init.d/sensu-api start'
  stop_program '/etc/init.d/sensu-api stop'
  with 'PIDFILE /var/run/sensu/sensu-api.pid'
end

monit_check 'sensu-client' do
  check "if does not exist then restart \n if does not exist then exec #{node[:monit][:alert][:slack][:script_file]}"
  start_program '/etc/init.d/sensu-client start'
  stop_program '/etc/init.d/sensu-client stop'
  with 'PIDFILE /var/run/sensu/sensu-client.pid'
end

monit_check 'sensu-server' do
  check "if does not exist then restart \n if does not exist then exec #{node[:monit][:alert][:slack][:script_file]}"
  start_program '/etc/init.d/sensu-server start'
  stop_program '/etc/init.d/sensu-server stop'
  with 'PIDFILE /var/run/sensu/sensu-server.pid'
end

monit_check 'redis' do
  check "if does not exist then restart \n if does not exist then exec #{node[:monit][:alert][:slack][:script_file]}"
  start_program '/etc/init.d/redis6379 start'
  stop_program '/etc/init.d/redis6379 stop'
  with 'PIDFILE /var/run/redis/6379/redis_6379.pid'
end

monit_check 'rabbitmq' do
  check "if does not exist then restart \n if does not exist then exec #{node[:monit][:alert][:slack][:script_file]}"
  start_program '/etc/init.d/rabbitmq-server start'
  stop_program '/etc/init.d/rabbitmq-server stop'
  with 'PIDFILE /var/run/rabbitmq/pid'
end

monit_check 'nginx' do
  check "if does not exist then restart \n if does not exist then exec #{node[:monit][:alert][:slack][:script_file]}"
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

monit_check 'rabbitmq_queue_monitor' do
  check_type 'program'
  with "path \"#{node[:monit][:plugin][:rabbitmq][:queue_monitor]} 500\" "
  check "if status != 0 for 5 cycles then exec #{node[:monit][:alert][:slack][:script_file]}"
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

# Copy rabbitmq queue monitor
template "#{node[:monit][:plugin][:rabbitmq][:queue_monitor]}" do
  source 'rabbitmq_queue_monitor.py.erb'
  mode '0555'
  owner 'root'
  group 'root'
end
