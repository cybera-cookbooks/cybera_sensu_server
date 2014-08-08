#!/usr/bin/env ruby

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-handler'
require 'json'
require 'open-uri'

class Revere < Sensu::Handler

  def token
    get_setting('token')
  end

  def url
    get_setting('url')
  end

  def channel
    get_setting('channel')
  end

  def get_setting(name)
    settings["revere"][name]
  end

  def handle
    # only generate alert if the check status is critical
    return unless check_status == 2

    description = @event['notification'] || build_description
    post_data(description)
  end

  def build_description
    default = "Unknown"
    status = {
      0 => 'healthy',
      1 => 'warning',
      2 => 'critical'
    }
    return "#{@event['client']['name']} #{@event['check']['name']} is #{status.fetch(check_status, default)}. Check email or Sensu dashboard for more information"
  end

  def post_data(notice)
    uri = revere_uri(token)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    req = Net::HTTP::Post.new("#{uri.path}?#{uri.query}")
    req.body = "message=\"#{URI::encode notice}\""

    puts "sending revere alert to #{uri} with message #{req.body}"
    response = http.request(req)
    verify_response(response)
  end

  def verify_response(response)
    case response
      when Net::HTTPSuccess
        true
      else
        raise response.error!
    end
  end

  def check_status
    return @event['check']['status'].to_i
  end

  def revere_uri(token)
    url = "https://revere.cybera.ca/api/broadcast_message_by_channel_name/#{channel}?auth_token=#{token}"
    URI(url)
  end

end
