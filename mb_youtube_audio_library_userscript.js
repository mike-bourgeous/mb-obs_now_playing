// ==UserScript==
// @name     MB - YouTube Audio Library now playing details 
// @version  2025-09-03
// @grant    none
// @include  https://studio.youtube.com/channel/*/music
// ==/UserScript==


// The initial delay and interval handles page title change by JS during
// loading, the addition of the player HTML only when playback starts, and any
// DOM changes down the line.


(function() {
    let originalTitle = undefined;
    let priorMsg = null;

    // TODO: maybe hook into DOM events and playback status events?
    setInterval(
        function() {
            const titleElement = document.querySelector('.ytmus-player.track-info #title');
            const artistElement = document.querySelector('.ytmus-player.track-info #artist');
            const playerElement = document.querySelector('audio.ytmus-player');

            // TODO: it might be possible to get the license type from aria
            // attributes, making it easier to include CC license info in the
            // chat or description

            if (originalTitle === undefined) {
                originalTitle = document.title;
            }

            let msg = null;
            let titleText = undefined;
            let artistText = undefined;

            if (titleElement && artistElement && playerElement && !playerElement.paused) {
                titleText = titleElement.textContent;
                artistText = artistElement.textContent;
                msg = "YouTube Audio Library: " + artistText + " - " + titleText;
            } else {
                msg = "" + originalTitle + ": Not playing";
            }

            if (priorMsg !== msg) {
                console.log("Playback status: " + msg);
                document.title = msg;
                priorMsg = msg;
                navigator.mediaSession.metadata = new MediaMetadata({
                    title: titleText,
                    artist: artistText,
                    album: "YouTube Audio Library",
                });
            }
        },
        500
    );
})();
