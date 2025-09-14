import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["searchInput"]

  connect() {
    console.log("Home controller connected")
  }

  findMyWard(event) {
    event.preventDefault()

    if (navigator.geolocation) {
      // Show loading state
      const button = event.target
      const originalText = button.innerHTML
      button.innerHTML = '<span class="mr-2">📡</span> Finding your location...'
      button.disabled = true

      navigator.geolocation.getCurrentPosition(
        (position) => {
          const lat = position.coords.latitude
          const lng = position.coords.longitude
          console.log(`User location: ${lat}, ${lng}`)

          // TODO: Implement ward lookup based on coordinates
          // For now, just redirect to wards page
          window.location.href = '/wards'
        },
        (error) => {
          console.error('Geolocation error:', error)
          button.innerHTML = originalText
          button.disabled = false

          // Show error message
          this.showLocationError(error)
        },
        {
          enableHighAccuracy: true,
          timeout: 10000,
          maximumAge: 300000 // 5 minutes
        }
      )
    } else {
      alert("Geolocation is not supported by this browser. Please use the search option instead.")
    }
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

  showLocationError(error) {
    let message = "Unable to get your location. "

    switch(error.code) {
      case error.PERMISSION_DENIED:
        message += "Please allow location access or use the search option."
        break
      case error.POSITION_UNAVAILABLE:
        message += "Location information is unavailable."
        break
      case error.TIMEOUT:
        message += "The request to get your location timed out."
        break
      default:
        message += "An unknown error occurred."
        break
    }

    // Show error in a nice way - could be replaced with toast notification
    const errorDiv = document.createElement('div')
    errorDiv.className = 'mt-4 p-3 bg-red-100 border border-red-300 text-red-700 rounded-lg text-sm'
    errorDiv.textContent = message

    // Insert after the GPS button
    const wardDiscoverySection = document.querySelector('[data-controller="home"]')
    const existingError = wardDiscoverySection.querySelector('.bg-red-100')
    if (existingError) {
      existingError.remove()
    }
    wardDiscoverySection.appendChild(errorDiv)

    // Remove error after 5 seconds
    setTimeout(() => {
      if (errorDiv.parentNode) {
        errorDiv.remove()
      }
    }, 5000)
  }

  debounce(func, wait) {
    if (this.debounceTimeout) {
      clearTimeout(this.debounceTimeout)
    }
    this.debounceTimeout = setTimeout(func, wait)
  }
}