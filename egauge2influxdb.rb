#!/usr/bin/env ruby

require 'rubygems'
require 'httparty'
require 'nokogiri'


def normalize_metric (str, prefix = nil)
  str = str.downcase.gsub('+','_plus').gsub(/\W/,'_')
  prefix ? "#{prefix}.#{str}" : str
end

metric_prefix = "solar"

response = HTTParty.get("https://sol.borg.lan/cgi-bin/egauge?inst&tot")

xml_slop = Nokogiri::Slop(response.body)
ts = xml_slop.data.ts.text

graphite_output = xml_slop.data.r.map do |r|
  metric_name = sprintf("%s.total_watts", normalize_metric(r['n'], metric_prefix))
  sprintf("%s %d %s", metric_name, r.v.text.to_i, ts )
end

graphite_output += xml_slop.data.r.map do |r|
  metric_name = sprintf("%s.interval_watts", normalize_metric(r['n'], metric_prefix))
  sprintf("%s %d %s", metric_name, r.i.text.to_i, ts )
end

puts graphite_output.join("\n")
