import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.loadTwitterWidgets()
  }

  loadTwitterWidgets() {
    if (window.twttr && window.twttr.widgets) {
      window.twttr.widgets.load(this.element)
      return
    }

    // Remove any existing widget script so it re-initializes
    const existing = document.querySelector('script[src*="platform.twitter.com/widgets.js"]')
    if (existing) existing.remove()

    const script = document.createElement("script")
    script.src = "https://platform.twitter.com/widgets.js"
    script.charset = "utf-8"
    script.async = true
    script.onload = () => {
      if (window.twttr && window.twttr.widgets) {
        window.twttr.widgets.load(this.element)
      }
    }
    document.head.appendChild(script)
  }
}
