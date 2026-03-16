import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results"]

  connect() {
    this.timeout = null
    this.selectedIndex = -1
  }

  disconnect() {
    clearTimeout(this.timeout)
  }

  search() {
    clearTimeout(this.timeout)
    this.selectedIndex = -1
    const query = this.inputTarget.value.trim()

    if (query.length < 3) {
      this.hideResults()
      return
    }

    this.timeout = setTimeout(() => this.fetchResults(query), 300)
  }

  keydown(event) {
    const items = this.resultItems
    if (items.length === 0) return

    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
        this.selectedIndex = Math.min(this.selectedIndex + 1, items.length - 1)
        this.highlightItem()
        break
      case "ArrowUp":
        event.preventDefault()
        this.selectedIndex = Math.max(this.selectedIndex - 1, 0)
        this.highlightItem()
        break
      case "Enter":
        event.preventDefault()
        if (this.selectedIndex >= 0 && items[this.selectedIndex]) {
          items[this.selectedIndex].click()
        }
        break
      case "Escape":
        this.hideResults()
        break
    }
  }

  get resultItems() {
    return this.resultsTarget.querySelectorAll("button")
  }

  highlightItem() {
    this.resultItems.forEach((item, i) => {
      if (i === this.selectedIndex) {
        item.classList.add("bg-stone-100")
      } else {
        item.classList.remove("bg-stone-100")
      }
    })
  }

  async fetchResults(query) {
    const url = `https://nominatim.openstreetmap.org/search?` +
      new URLSearchParams({
        q: query,
        format: "json",
        addressdetails: "1",
        limit: "5",
        viewbox: "72.78,19.30,72.98,18.88",
        bounded: "1",
        countrycodes: "in"
      })

    try {
      const response = await fetch(url, {
        headers: { "Accept-Language": "en" }
      })
      const results = await response.json()
      this.showResults(results)
    } catch (e) {
      this.hideResults()
    }
  }

  showResults(results) {
    this.selectedIndex = -1

    if (results.length === 0) {
      this.resultsTarget.innerHTML = `<div class="px-3 py-2 text-xs text-stone-400 italic">No results in Mumbai</div>`
      this.resultsTarget.classList.remove("hidden")
      return
    }

    this.resultsTarget.innerHTML = results.map(r =>
      `<button type="button"
              class="block w-full text-left px-3 py-2 text-xs text-stone-700 hover:bg-stone-100 truncate"
              data-action="click->location-search#select"
              data-lat="${r.lat}"
              data-lng="${r.lon}">
        ${r.display_name}
      </button>`
    ).join("")
    this.resultsTarget.classList.remove("hidden")
  }

  hideResults() {
    this.resultsTarget.innerHTML = ""
    this.resultsTarget.classList.add("hidden")
    this.selectedIndex = -1
  }

  select(event) {
    const lat = event.currentTarget.dataset.lat
    const lng = event.currentTarget.dataset.lng
    window.location.href = `/wards/locate?lat=${lat}&lng=${lng}`
  }

  closeResults(event) {
    if (!this.element.contains(event.target)) {
      this.hideResults()
    }
  }
}
