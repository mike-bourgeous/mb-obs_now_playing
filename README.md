Test for OBS websocket control.

Ultimate goal is to show currently playing music from local media or from YouTube Audio Library.

```bash
if [ ! -e .password ]; then
    echo 'the obs password' > .password
fi

# Get overlay text settings
curl localhost:4567 | jq

# Set overlay text
curl --data-raw 'Song title' localhost:4567
```
