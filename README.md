# OBS Now Playing for Linux

*I don't recommend anyone use this.  It's hacked together for my needs.*

This is a tiny script that barely works well enough to update a text source in
OBS with the album, artist, and title of whatever media I am playing in the
background.

There's also a browser userscript for GreaseMonkey or TamperMonkey (untested)
that sends artist and title info to the operating system.

I wrote this for my livestreams, to allow me to play my own music or music from
the YouTube audio library in the background, and give due credit either way.

## Running

- Create a text source called `Overlay text` in OBS.
- Enable the OBS websocket server on the default port 4455.
- Install Ruby 3.4.x.
- Install `playerctl` (e.g. `sudo apt install playerctl`).
- Run `bundle install`.
- Run `bin/obs_now_playing.rb`.
- Start playing some music.

If the script can't find your OBS config file, you can add the OBS websocket
password to a file called `.password` in the current directory and try again.
