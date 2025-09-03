#!/usr/bin/env ruby

require 'sinatra'
require 'obsws'

OBS_CONFIG_PATHS = %w{
  ~/.var/app/com.obsproject.Studio/config/obs-studio/user.ini
  ~/.config/obs-studio/user.ini
}

def obs_password
  config_file = OBS_CONFIG_PATHS.detect { |p| File.readable?(p) }

  unless config_file
    puts "Unable to find OBS configuration file to read websocket password"

    puts "Reading password from .password"
    return File.read('.password').strip
  end

  puts "Reading password from OBS config file: #{config_file}"

  File
    .readlines(config_file)
    .detect { |l| l.strip.start_with?(ServerPassword) }
    .split('=', 2)[1]
    .rstrip
end

get '/' do
  content_type :json

  OBSWS::Requests::Client.new(host: 'localhost', port: 4455, password: obs_password).run do |sock|
    sock.get_input_settings('Overlay text').input_settings.to_json
  end
end

post '/' do
  request.body.rewind

  OBSWS::Requests::Client.new(host: 'localhost', port: 4455, password: obs_password).run do |sock|
    sock.set_input_settings(
      'Overlay text', # input name
      { from_file: false, text: request.body.read }, # input settings
      true # merge rather than overwrite
    )
    "OK\n"
  end
end
