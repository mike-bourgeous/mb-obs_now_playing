#!/usr/bin/env ruby

class PlayerctlClient
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

  def initialize(timeout = 0.5, &block)
    d = {}
    prior_d = nil

    timer = RateLimitTimer.new(timeout) do
      if d != prior_d
        if block
          block.call(d)
        else
          puts "\e[1m#{d}\e[0m (no block given)"
        end

        prior_d = deep_dup(d)
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

        timer.reset
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

        timer.reset
      end
    end

    sleep
  end

  def deep_dup(h)
    seen_map = {}

    h.map { |k, v|
      knew = seen_map[k] || k.is_a?(Hash) ? deep_dup(k) : k.dup
      vnew = seen_map[v] || v.is_a?(Hash) ? deep_dup(v) : v.dup

      seen_map[k] ||= knew
      seen_map[v] ||= vnew

      [knew, vnew]
    }.to_h
  end
end

PlayerctlClient.new do |d|
  app, v = d.detect { |app, h| h[:status] == 'Playing' }
  if v
    puts "\e[33m#{app} playing \e[1m#{[v[:album], v[:artist], v[:title]].compact.join(' - ')}\e[0m"
  else
    puts "\e[34mpaused\e[0m"
  end
end
