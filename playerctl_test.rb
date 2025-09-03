#!/usr/bin/env ruby

require 'pry'

class Hash
  def deep_dup
    self.map { |k, v|
      k = k.respond_to?(:deep_dup) ? k.deep_dup : k.dup
      v = v.respond_to?(:deep_dup) ? v.deep_dup : v.dup
      [k, v]
    }.to_h
  end
end

# Waits for a moment of silence before taking an action.  Every time reset is
# called, the timer starts over.  When the timer expires, the block passed to
# the constructor is called.
#
# This would not be good in a situation where there's never a silent moment.
class RateLimitTimer
  def initialize(timeout, &block)
    calling_thread = Thread.current
    first = true

    @timeout = timeout.to_f
    @q = Queue.new

    @thread = Thread.new do
      Thread.current.name = 'timer thread'

      loop do
        if first
          calling_thread.wakeup
          calling_thread = nil
          first = false
        end

        sleep @timeout

        unless @q.empty?
          # If there's anything in the queue, it means we were woken up.
          @q.pop until @q.empty?
        else
          # If the queue was empty, it means the timeout expired.
          block.call
        end
      end
    end

    sleep

  end

  def reset
    @q.push(nil)
    @thread.wakeup
  end
end

d = {}
prior_d = nil

timeout = RateLimitTimer.new(0.5) do
  if d != prior_d
    puts "\e[1m#{d}\e[0m"
    prior_d = d.deep_dup
  end
end

metadata_thread = Thread.new do
  Thread.current.name = 'metadata thread'

  player = IO.popen('playerctl -F metadata')
  until player.eof? do
    l = player.readline.strip

    matches = l.match(/(?<app>\w+)\s+xesam:(?<tag>title|artist|album)\s+(?<value>.*)/)
    next unless matches

    app = matches['app']

    d[app] ||= {}
    app_data = d[app]
    app_data[matches['tag'].to_sym] = matches['value']

    timeout.reset
  end
end

status_thread = Thread.new do
  Thread.current.name = 'status thread'

  player = IO.popen('playerctl -a -F status -f "{{playerName}}||{{status}}"')
  until player.eof? do
    l = player.readline.strip
    app, status = l.split('||', 2)
    
    d[app] ||= {}
    d[app][:status] = status

    timeout.reset
  end
end

sleep
