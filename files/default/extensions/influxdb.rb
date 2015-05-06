require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'influxdb'
require 'json'

# This handler assumes that metric data is coming in JSON that looks something like
# {
#   "timestamp": 1234567890,
#   "metric_a": 3,
#   "metric_b": 1.24,
#   "metric_c": "im a string"
# }
# If the integers or floats are strings in the incoming JSON object then we will convert them
# but if the conversion fails we'll just assume its a string (which you clearly cannot graph, but
# could be useful for a label perhaps)
#
# A metric check can also define multiple series, to do this the check must set
#     "multiple_series": true
# in the check definition. If this is set then the check output must have a key named 'series' which
# is defined like...
# "series": {
#   "my_series_name": {
#     "timestamp": 1234567890,
#     "metric_a": 3,
#     "metric_b": 1.24,
#     "metric_c": "Im a string"
#   }
# }
# If these conditions are not met then we will not successfully write to InfluxDB
module Sensu::Extension
  class Influx < Handler
    def post_init
      # if we fail here we want to fail loudly as nothing else will work.
      # So, we will just let exceptions be raised for required settings
      @influxdb = InfluxDB::Client.new(@settings["influxdb"]["database"],
        :host => @settings["influxdb"]["host"],
        :port => @settings["influxdb"]["port"],
        :username => @settings["influxdb"]["user"],
        :password => @settings["influxdb"]["password"]
      )
    end

    def definition
      {
        type: "extension",
        name: "influxdb"
      }
    end

    def name
      definition[:name]
    end

    def description
      "A handler that takes Sensu metric data as input and outputs it to InfluxDB"
    end

    def run(event_data)
      event_json = JSON.parse(event_data)
      client = event_json["client"]
      check = event_json["check"]

      metrics = JSON.parse(check["output"])
      puts "influx-----------------#{check["name"]}--------------"
      if metrics["series"]
        metrics["series"].each do |series_name, data|
puts "influx                  series: #{series_name}"
puts "#{data}"
          write_series series_name, data
        end
      else
        write_series "#{client["name"]}-#{check["name"]}", metrics
      end

      yield("metric successfully sent to InfluxDB", 0)
    end

    private
    def write_series(series_name, metrics)
      data_points = []
      timestamp = metrics["timestamp"]
      metrics.each do |key, value|
        next if key == "timestamp"
        if Float(value)
          value = Float(value)
        elsif Integer(value)
          value = Integer(value)
        end
        data_points << {
          :time => timestamp,
          :metric => key,
          :value => value
        }
      end
      @influxdb.write_point(series_name, data_points, true)
    end
  end
end
