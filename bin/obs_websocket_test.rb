#!/usr/bin/env ruby

require 'bundler/setup'
require 'sinatra'

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'mb/obs_text_client'

client = MB::ObsTextClient.new('Overlay text')

get '/' do
  client.text
end

post '/' do
  request.body.rewind
  client.text = request.body.read
  "OK\n"
end
