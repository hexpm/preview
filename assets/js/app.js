// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import "phoenix_html"
import { Socket } from "phoenix"
import NProgress from "nprogress"
import LiveSocket from "phoenix_live_view"

let Hooks = {}
Hooks.updateHash = {
    mounted() {
        this.el.addEventListener("click", e => {
            let loc = window.location;
            let url = loc.protocol + '//' + loc.host + loc.pathname + '#L' + this.el.dataset.lineNumber;
            history.pushState(history.state, document.title, url);
            update_hash()
            e.preventDefault();
        });
    }
}

window.onhashchange = function () {
    update_hash()
}

function update_hash() {
    let hash = location.hash
    // clear existing highlighted lines
    Array.from(document.getElementsByClassName("highlighted")).forEach(function (n, i) { n.classList.remove('highlighted') })

    if (hash.startsWith("#L")) {
        let id = hash.slice(1)
        document.getElementById(id).classList.add("highlighted");
    }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, { params: { _csrf_token: csrfToken }, hooks: Hooks })

// Show progress bar on live navigation and form submits
window.addEventListener("phx:page-loading-start", info => NProgress.start())
window.addEventListener("phx:page-loading-stop", info => { NProgress.done(); update_hash(); })

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

