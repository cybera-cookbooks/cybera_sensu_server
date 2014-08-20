#!/opt/sensu/embedded/bin/ruby
#
# Sensu Handler: mailer
#
# This handler formats alerts as mails and sends them off to a pre-defined recipient.
#
# Copyright 2012 Pal-Kristian Hamre (https://github.com/pkhamre | http://twitter.com/pkhamre)
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-handler'
gem 'mail', '~> 2.5.4'
require 'mail'
require 'timeout'
require 'json'

class Mailer < Sensu::Handler
  def short_name
    @event['client']['name'] + '/' + @event['check']['name']
  end

  def action_to_string
   @event['action'].eql?('resolve') ? "RESOLVED" : "ALERT"
  end

  def handle
    # get client stashes for additional config
    stash_configs = []
    client_stashes = if @event['client']['stashes'].kind_of?(Array) then @event['client']['stashes'] else [] end
    client_stashes.each do |stash|
      stash_data = api_request(:GET, '/stash/' + stash)
      next if stash_data.code != '200'
      stash_json = JSON.parse(stash_data.body)
      stash_configs << stash_json unless stash_json.nil?
    end

    mail_to = []

    if settings['mailer']['mail_to'].kind_of? Array
      mail_to.concat settings['mailer']['mail_to']
    elsif settings['mailer']['mail_to'].kind_of? String
      mail_to << settings['mailer']['mail_to']
    end

    stash_configs.each do |stash|
      stash_handlers = stash['handlers']
      next unless stash_handlers
      stash_mailer = stash_handlers['mailer']
      next unless stash_mailer
      stash_mail_to = stash_mailer['mail_to']
      mail_to.concat stash_mail_to if stash_mail_to.kind_of? Array
    end
    mail_to.uniq!   # we only want to send to each address once
    mail_from =  settings['mailer']['mail_from']

    delivery_method = settings['mailer']['delivery_method'] || 'smtp'
    smtp_address = settings['mailer']['smtp_address'] || 'localhost'
    smtp_port = settings['mailer']['smtp_port'] || '25'
    smtp_domain = settings['mailer']['smtp_domain'] || 'localhost.localdomain'

    smtp_username = settings['mailer']['smtp_username'] || nil
    smtp_password = settings['mailer']['smtp_password'] || nil
    smtp_authentication = settings['mailer']['smtp_authentication'] || :plain
    smtp_enable_starttls_auto = settings['mailer']['smtp_enable_starttls_auto'] == "false" ? false : true

    other_command = "Other_Command: #{@event['check']['other_command']}" if @event['check']['other_command'] 
    playbook = "Playbook:  #{@event['check']['playbook']}" if @event['check']['playbook']
    body = <<-BODY.gsub(/^\s+/, '')
            #{@event['check']['output']}
            Host: #{@event['client']['name']}
            Timestamp: #{Time.at(@event['check']['issued'])}
            Address:  #{@event['client']['address']}
            Check Name:  #{@event['check']['name']}
            Command:  #{@event['check']['command']}
            Status:  #{@event['check']['status']}
            Occurrences:  #{@event['occurrences']}
            #{other_command}
            #{playbook}
          BODY
    subject = "#{action_to_string} - #{short_name}: #{@event['check']['notification']}"

    Mail.defaults do
      delivery_options = {
        :address    => smtp_address,
        :port       => smtp_port,
        :domain     => smtp_domain,
        :openssl_verify_mode => 'none',
        :enable_starttls_auto => smtp_enable_starttls_auto
      }

      unless smtp_username.nil?
        auth_options = {
          :user_name        => smtp_username,
          :password         => smtp_password,
          :authentication   => smtp_authentication
        }
        delivery_options.merge! auth_options
      end

      delivery_method delivery_method.intern, delivery_options
    end

    begin
      timeout 10 do
        Mail.deliver do
          to      mail_to
          from    mail_from
          subject subject
          body    body
        end

        puts 'mail -- sent alert for ' + short_name + ' to ' + mail_to.to_s
      end
    rescue Timeout::Error
      puts 'mail -- timed out while attempting to ' + @event['action'] + ' an incident -- ' + short_name
    end
  end
end
