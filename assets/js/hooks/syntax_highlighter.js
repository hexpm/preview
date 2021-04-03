import Prism from 'prismjs'

window.addEventListener("phx:page-loading-stop", (info) => {
  Prism.highlightAll()
})

export const SyntaxHighlighterHook = {
  updated() {
    setTimeout(() => {
      Prism.highlightElement(this.el.firstChild)
    })
  },
}
