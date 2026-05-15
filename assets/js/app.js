import "phoenix_html"
import { initializeTheme } from "./theme"
initializeTheme()

import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"

let Hooks = {}

Hooks.updateHash = {
  mounted() {
    this.el.addEventListener("click", e => {
      const loc = window.location
      const url = loc.protocol + "//" + loc.host + loc.pathname + "#L" + this.el.dataset.lineNumber
      history.pushState(history.state, document.title, url)
      updateHash()
      e.preventDefault()
    })
  }
}

window.onhashchange = function () {
  updateHash()
}

function updateHash() {
  const hash = location.hash

  Array.from(document.getElementsByClassName("highlighted")).forEach((n) => {
    n.classList.remove("highlighted")
  })

  if (hash.startsWith("#L")) {
    const id = hash.slice(1)
    const el = document.getElementById(id)
    if (el) {
      el.classList.add("highlighted")
      el.scrollIntoView({ block: "center" })
    }
  }
}

const backToTop = document.getElementById("back-to-top")
if (backToTop) {
  window.addEventListener("scroll", () => {
    const visible = window.scrollY > 400
    backToTop.classList.toggle("opacity-0", !visible)
    backToTop.classList.toggle("pointer-events-none", !visible)
  }, { passive: true })
}

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: Hooks,
})

window.addEventListener("phx:page-loading-stop", () => updateHash())

liveSocket.connect()

window.liveSocket = liveSocket
