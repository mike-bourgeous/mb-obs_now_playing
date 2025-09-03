// ==UserScript==
// @name     MB - YouTube Audio Library now playing details 
// @version  August 2025
// @grant    none
// @include  https://studio.youtube.com/channel/*/music
// ==/UserScript==


// The initial 2s delay and interval handles page title change by JS during
// loading, the addition of the player HTML only when playback starts, and
// any DOM changes down the line.


(function() {
    let originalTitle = undefined;
    let priorMsg = null;

    // TODO: maybe hook into DOM events and playback status events?
    setInterval(
        function() {
            const title = document.querySelector('.ytmus-player.track-info #title');
            const artist = document.querySelector('.ytmus-player.track-info #artist');
            const player = document.querySelector('audio.ytmus-player');

            if (originalTitle === undefined) {
                originalTitle = document.title;
            }

            let msg = null;

            if (title && artist && player && !player.paused) {
                msg = "YouTube Audio Library: " + artist.textContent + " - " + title.textContent;
            } else {
                msg = "" + originalTitle + ": Not playing";
            }

            if (priorMsg !== msg) {
                console.log("Playback status: " + msg);
                document.title = msg;
                priorMsg = msg;
            }
        },
        2000
    );
})();
