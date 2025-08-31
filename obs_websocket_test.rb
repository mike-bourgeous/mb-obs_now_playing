#!/usr/bin/env ruby

require 'sinatra'
require 'obsws'

get '/' do
  content_type :json

  OBSWS::Requests::Client.new(host: 'localhost', port: 4455, password: File.read('.password').strip).run do |sock|
    sock.get_input_settings('Overlay text').input_settings.to_json
  end
end

post '/' do
  request.body.rewind

  OBSWS::Requests::Client.new(host: 'localhost', port: 4455, password: File.read('.password').strip).run do |sock|
    sock.set_input_settings(
      'Overlay text', # input name
      { from_file: false, text: request.body.read }, # input settings
      true # merge rather than overwrite
    )
    "OK\n"
  end
end
