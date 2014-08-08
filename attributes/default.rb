default[:sensu][:use_embedded_ruby] = true
default[:sensu][:handlers_directory] = "/etc/sensu/handlers"

default[:uchiwa][:server_name] = "sensu"
default[:uchiwa][:ssl][:enabled] = false
default[:uchiwa][:ssl][:certificate] = ""
default[:uchiwa][:ssl][:certificate_key] = ""
default[:uchiwa][:settings][:host] = node[:ipaddress]

# Define Filters
default[:sensu][:filters][:production][:attributes][:client][:environment] = "production"
default[:sensu][:filters][:production][:negate] = false

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


