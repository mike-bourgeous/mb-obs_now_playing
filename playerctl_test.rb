#!/usr/bin/env ruby

require 'pry'

# Waits for a moment of silence before taking an action.  Every time reset is
# called, the timer starts over.  When the timer expires, the block passed to
# the constructor is called.
class RateLimitTimer
  class SillyError < RuntimeError; end

  def initialize(timeout, &block)
    @timeout = timeout.to_f

    @mtx = Mutex.new

    @t = Thread.current
    @first = true
    @waiting = false

    @thread = Thread.new do
      Thread.current.name = 'timer thread'

      loop do
        begin
          begin
            @t.wakeup if @first
            @first = false

            @waiting = true
            sleep @timeout
            @waiting = false

            @mtx.synchronize do
              block.call
            end

          rescue SillyError
            @waiting = false

            # FIXME: this sync structure is messy and could allow exceptions to
            # be raised between locks.
            @mtx.synchronize do
              puts "Reset timer to #{@timeout}"
            end
          end

        rescue SillyError
          puts "Another error!"
          retry
        end
      end
    end

    sleep
  end

  def reset
    @mtx.lock
    puts "Thread #{Thread.current} #{caller} waking up #{@thread} while waiting #{@waiting}"
    @thread.raise SillyError

  ensure
    @mtx.unlock
  end
end

d = {}

timeout = RateLimitTimer.new(0.5) do
  puts d
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
