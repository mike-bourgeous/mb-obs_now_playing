#!/usr/bin/env ruby

require 'pry'

d = {}

metadata_thread = Thread.new do
  player = IO.popen('playerctl -F metadata')
  until player.eof? do
    l = player.readline.strip

    matches = l.match(/(?<app>\w+)\s+xesam:(?<tag>title|artist|album)\s+(?<value>.*)/)
    next unless matches

    d[:app] = matches['app']
    d[matches['tag'].to_sym] = matches['value']
  end
end

playback_thread = Thread.new do
  player = IO.popen('playerctl -F status')
  until player.eof? do
    l = player.readline.strip
    
    case l
    when 'Paused'
      puts "\n\n\nPAUSED\n\n\n"

    when 'Playing'
      # TODO: wait a bit for metadata thread to push some updates?
      # TODO: 0.5 isn't enough because of 2s interval in browser extension
      sleep 0.5
      puts "\n\n\nPlaying: #{d}"
    end
  end
end

sleep
