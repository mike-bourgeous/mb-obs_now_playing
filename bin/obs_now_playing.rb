#!/usr/bin/env ruby

require 'bundler/setup'
require 'uri'

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'mb/playerctl_client'
require 'mb/obs_text_client'

obs = MB::ObsTextClient.new('Overlay text')

MB::PlayerctlClient.new do |d|
  app, info = d.detect { |app, h| h[:status] == 'Playing' }
  if info
    puts "\n\n\n"
    puts info
    data = info.slice(:album, :artist, :title, :url)

    # Use filename as title if title is missing
    # TODO: get artist from filename if artist is missing?
    # TODO: move this code into PlayerctlClient
    if data[:url] && !data[:title] && data[:url].start_with?('file')
      begin
        uri = URI.decode_uri_component(data[:url])
        data[:title] = uri.rpartition(%r{[/-]})[-1].rpartition('.')[0].strip
      rescue => e
        STDERR.puts "\e[31mError turning URL into title: #{e}\e[0m"
      end
    end

    data.delete(:url)

    puts "\e[33m#{app} playing \e[1m#{data.values.compact.join(' - ')}\e[0m"
    puts data

    lines = data.except(:url).compact.map { |k, v|
      "#{k.to_s.capitalize}: #{v}\n"
    }

    lines = ["\n"] * (9 - lines.length) + lines

    puts "\n\n\t#{lines.join("\t")}\n\n"

    # Calling twice deliberately -- sometimes OBS would only get part of the
    # text, maybe due to websocket shutdown?  TODO: would a persistent
    # websocket fix this?
    obs.text = lines.join
    obs.text = lines.join
  else
    puts "\e[34mpaused\e[0m"
    obs.text = ''

    # TODO: restore the original file source using from_file?
  end
end
