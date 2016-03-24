default['rabbitmq']['use_distro_version'] = true

default[:sensu][:use_embedded_ruby] = true
default[:sensu][:handlers_directory] = "/etc/sensu/handlers"
default[:sensu][:extensions_directory] = "/etc/sensu/extensions"
default[:sensu][:nginx][:enabled] = true
default[:sensu][:nginx][:uchiwa] = true
default[:sensu][:nginx][:sensu_api] = true
default[:sensu][:nginx][:ssl][:enabled] = false
default[:sensu][:nginx][:ssl][:directory] = "/etc/nginx/ssl"
default[:sensu][:nginx][:ssl][:certificate] = "cert.pem"
default[:sensu][:nginx][:ssl][:certificate_key] = "key.pem"

default[:uchiwa][:server_name] = "sensu"
default[:uchiwa][:settings][:host] = "localhost"

# Define Filters
default[:sensu][:filters][:production][:attributes][:client][:environment] = "production"
default[:sensu][:filters][:production][:negate] = false

# Define Extensions
default[:sensu][:extensions][:influxdb][:enabled] = false
default[:sensu][:extensions][:influxdb][:file_name] = "influxdb.rb"
default[:sensu][:extensions][:influxdb][:gems][:influxdb][:version] = "~> 0.1.8"
default[:sensu][:extensions][:influxdb][:config][:host] = "localhost"
default[:sensu][:extensions][:influxdb][:config][:port] = "8086"
default[:sensu][:extensions][:influxdb][:config][:user] = "metrics"
default[:sensu][:extensions][:influxdb][:config][:password] = "supersecret!"
default[:sensu][:extensions][:influxdb][:config][:database] = "metrics"
default[:sensu][:extensions][:influxdb][:config][:strip_metric] = "host"

# Define Handlers
default[:sensu][:handlers][:lmc_alerting][:enabled] = false
default[:sensu][:handlers][:lmc_alerting][:type] = "set"
default[:sensu][:handlers][:lmc_alerting][:handlers] = ["mailer", "slack", "revere"]

#default[:sensu][:handlers][:mailer][:admin_gui] = "http://admin.example.com:8080/"
default[:sensu][:handlers][:mailer][:enabled] = false
default[:sensu][:handlers][:mailer][:file_name] = "mailer.rb"
default[:sensu][:handlers][:mailer][:gems][:mail][:version] = "~> 2.5.4"
default[:sensu][:handlers][:mailer][:config][:mail_from] = "someone@myorg.com"
default[:sensu][:handlers][:mailer][:config][:mail_to] = "someone@myorg.com"
default[:sensu][:handlers][:mailer][:config][:smtp_address] = "localhost"
default[:sensu][:handlers][:mailer][:config][:smtp_port] = "25"
default[:sensu][:handlers][:mailer][:config][:smtp_domain] = "myorg.com"

default[:sensu][:handlers][:revere][:enabled] = false
default[:sensu][:handlers][:revere][:file_name] = "revere.rb"
default[:sensu][:handlers][:revere][:filters] = ["production"]
default[:sensu][:handlers][:revere][:config][:token] = "mytoken"
default[:sensu][:handlers][:revere][:config][:url] = "revere.myorg.com"
default[:sensu][:handlers][:revere][:config][:channel] = "alert channel"

default[:sensu][:handlers][:slack][:enabled] = false
default[:sensu][:handlers][:slack][:file_name] = "slack.rb"
default[:sensu][:handlers][:slack][:filters] = ["production"]
default[:sensu][:handlers][:slack][:config][:token] = "TOKEN"
default[:sensu][:handlers][:slack][:config][:team_name] = "TEAM"
default[:sensu][:handlers][:slack][:config][:channel] = "CHANNEL"
default[:sensu][:handlers][:slack][:config][:message_prefix] = "Sensu: "
default[:sensu][:handlers][:slack][:config][:surround] = "```"
default[:sensu][:handlers][:slack][:config][:bot_name] = "Good news bot"

default['poise-monit']['recipe']['daemon_interval'] = 30
default['poise-monit']['recipe']['httpd_port'] = 2812
default['poise-monit']['recipe']['httpd_username'] = "admin"
default['poise-monit']['recipe']['httpd_password'] = "admin"


# Cybera Custom Monit attributes independent from poise-monit

# Mail alerts
default[:monit][:alert][:mail][:server] = "smtp.example.com"
default[:monit][:alert][:mail][:to] = "notify@example.com" 
default[:monit][:alert][:mail][:cycles] = 10

# Slack alerts
default[:monit][:alert][:slack][:script_file] = "/etc/monit/slack.rb"
default[:monit][:alert][:slack][:uri] = "https://hooks.slack.com/services/xxxxxxxxxxxxxx"
default[:monit][:alert][:slack][:channel] = "#chan"
default[:monit][:alert][:slack][:username] = "mmonit"
