require 'obsws'

module MB
  # Makes it very easy to set the contents of a text element in OBS over websocket.
  class ObsTextClient
    OBS_CONFIG_PATHS = [
      '~/.var/app/com.obsproject.Studio/config/obs-studio/user.ini',
      '~/.config/obs-studio/user.ini',
    ].freeze

    def initialize(text_source_name)
      @text_source_name = text_source_name.dup.freeze
      @password = nil
    end

    def text
      # TODO: maybe use a persistent connection
      # TODO: error handling
      OBSWS::Requests::Client.new(host: 'localhost', port: 4455, password: password).run do |sock|
        sock.get_input_settings(@text_source_name).input_settings[:text]
      end
    end

    def text=(new_text)
      OBSWS::Requests::Client.new(host: 'localhost', port: 4455, password: password).run do |sock|
        sock.set_input_settings(
          'Overlay text', # input name
          { from_file: false, text: new_text }, # input settings
          true # merge rather than overwrite
        )
        "OK\n"
      end
    end

    private

    def password
      # TODO: reset password and try again if connection fails
      @password ||= find_obs_password
    end

    def find_obs_password
      config_file = OBS_CONFIG_PATHS.detect { |p| File.readable?(p) }

      unless config_file
        puts "Unable to find OBS configuration file to read websocket password"

        if File.readable?('.password')
          puts "Reading password from .password"
          return File.read('.password').strip
        else
          raise 'Unable to find OBS password in config files or in file named .password'
        end
      end

      puts "Reading password from OBS config file: #{config_file}"

      File
        .readlines(config_file)
        .detect { |l| l.strip.start_with?(ServerPassword) }
        .split('=', 2)[1]
        .rstrip
    end
  end
end
