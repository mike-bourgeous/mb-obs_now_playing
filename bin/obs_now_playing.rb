#!/usr/bin/env ruby

require 'bundler/setup'

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'mb/playerctl_client'
require 'mb/obs_text_client'

obs = MB::ObsTextClient.new('Overlay text')

MB::PlayerctlClient.new do |d|
  app, v = d.detect { |app, h| h[:status] == 'Playing' }
  if v
    puts "\e[33m#{app} playing \e[1m#{[v[:album], v[:artist], v[:title]].compact.join(' - ')}\e[0m"

    lines = v.slice(:album, :artist, :title).compact.map { |k, v|
      "#{k.to_s.capitalize}: #{v}\n"
    }

    lines = ["\n"] * (9 - lines.length) + lines

    obs.text = lines.join
  else
    puts "\e[34mpaused\e[0m"
    obs.text = ''
  end
end
