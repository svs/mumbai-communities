import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["searchInput"]

  connect() {
    console.log("Home controller connected")
  }


  searchArea(event) {
    const query = event.target.value.trim()

    if (query.length > 2) {
      console.log(`Searching for area: ${query}`)
      // TODO: Implement autocomplete search
      // For now, we'll implement basic search behavior
      this.debounce(() => {
        this.performSearch(query)
      }, 300)
    }
  }

  performSearch(query) {
    // TODO: Make AJAX request to search for wards/areas
    // For now, just log the search
    console.log(`Performing search for: ${query}`)

    // Future implementation:
    // - Fetch matching wards from API
    // - Show dropdown with results
    // - Allow selection and navigation
  }


  debounce(func, wait) {
    if (this.debounceTimeout) {
      clearTimeout(this.debounceTimeout)
    }
    this.debounceTimeout = setTimeout(func, wait)
  }

}