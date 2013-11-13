#!/usr/bin/env ruby

require 'rubygems'
require 'httparty'
require 'nokogiri'
require 'influxdb'
require 'pp'
require 'logger'

def normalize_metric (str, prefix = nil)
  str = str.downcase.gsub('+','_plus').gsub(/\W/,'_')
  prefix ? "#{prefix}.#{str}" : str
end

interval = 5

logger = Logger.new($stderr)
logger.level = Logger::DEBUG

database = 'solar'
influxdb = InfluxDB::Client.new(nil, :username => 'root', :password => 'root', :host => 'tigh.borg.lan')

unless influxdb.get_database_list.map{ |x| x['name'] }.include?(database)
  influxdb.create_database(database) 
  influxdb.create_database_user(database, "solar", "solar")
end
influxdb = InfluxDB::Client.new(database, :username => 'solar', :password => 'solar', :host => 'tigh.borg.lan')

loop do
  response = HTTParty.get("https://sol.borg.lan/cgi-bin/egauge?inst&tot")

  xml_slop = Nokogiri::Slop(response.body)
  ts = xml_slop.data.ts.text

  output_data = xml_slop.data.r.map do |r|
    metric_name = sprintf("%s_total_watts", normalize_metric(r['n']))
    [metric_name, { :value => r.v.text.to_i } ]
#  sprintf("%s %d %s", metric_name, r.v.text.to_i, ts )
  end

  output_data += xml_slop.data.r.map do |r|
    metric_name = sprintf("%s_interval_watts", normalize_metric(r['n']))
    [metric_name,  { :value => r.i.text.to_i }]
  end

  Hash[output_data].each do |metric_name,data|
    logger.debug "Sending #{metric_name} => #{data}"
    response = influxdb.write_point(metric_name, data)
    pp response 
    logger.debug response
  end

  logger.info "Sleeping for #{interval} seconds"
  sleep interval
end
