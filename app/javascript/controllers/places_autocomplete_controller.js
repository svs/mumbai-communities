import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "hiddenLat", "hiddenLng", "hiddenFormattedAddress"]

  connect() {
    // Google Places API will call initPlacesAutocomplete when loaded
    window.initPlacesAutocomplete = () => {
      this.initializeAutocomplete()
    }

    // If Google Maps is already loaded, initialize immediately
    if (window.google && window.google.maps) {
      this.initializeAutocomplete()
    }
  }

  initializeAutocomplete() {
    if (!window.google || !window.google.maps) {
      console.error("Google Maps API not loaded")
      return
    }

    // Create autocomplete with restrictions to Mumbai, India
    this.autocomplete = new window.google.maps.places.Autocomplete(this.inputTarget, {
      types: ['address'],
      componentRestrictions: {
        country: 'in'  // Restrict to India
      },
      bounds: new window.google.maps.LatLngBounds(
        // Mumbai bounds - Southwest corner
        new window.google.maps.LatLng(18.8800, 72.7800),
        // Northeast corner
        new window.google.maps.LatLng(19.3000, 72.9800)
      ),
      strictBounds: false, // Allow some flexibility but prefer Mumbai
      fields: ['address_components', 'formatted_address', 'geometry', 'name']
    })

    // Listen for place selection
    this.autocomplete.addListener('place_changed', () => {
      this.handlePlaceSelect()
    })

    console.log("Google Places Autocomplete initialized")
  }

  handlePlaceSelect() {
    const place = this.autocomplete.getPlace()

    if (!place.geometry) {
      console.error("No geometry found for selected place")
      return
    }

    // Extract coordinates
    const lat = place.geometry.location.lat()
    const lng = place.geometry.location.lng()

    console.log("Selected place:", place.formatted_address, "Coordinates:", lat, lng)

    // Update hidden fields if they exist
    if (this.hasHiddenLatTarget) {
      this.hiddenLatTarget.value = lat
    }
    if (this.hasHiddenLngTarget) {
      this.hiddenLngTarget.value = lng
    }
    if (this.hasHiddenFormattedAddressTarget) {
      this.hiddenFormattedAddressTarget.value = place.formatted_address
    }

    // Check if the address is in Mumbai
    this.validateMumbaiLocation(place, lat, lng)
  }

  validateMumbaiLocation(place, lat, lng) {
    const isMumbai = this.checkIfMumbai(place.address_components)

    if (!isMumbai) {
      this.showLocationWarning("Please select an address within Mumbai city limits.")
      return false
    }

    // Check if coordinates are within Mumbai bounds
    if (lat < 18.88 || lat > 19.30 || lng < 72.78 || lng > 72.98) {
      this.showLocationWarning("The selected address appears to be outside Mumbai. Please choose an address within Mumbai city.")
      return false
    }

    this.hideLocationWarning()

    // Emit custom event for other controllers to listen to
    const event = new CustomEvent('places-autocomplete:place-selected', {
      detail: {
        place: place,
        lat: lat,
        lng: lng,
        formatted_address: place.formatted_address
      },
      bubbles: true
    })
    this.element.dispatchEvent(event)

    return true
  }

  checkIfMumbai(addressComponents) {
    for (const component of addressComponents) {
      const types = component.types
      const name = component.long_name.toLowerCase()

      // Check for Mumbai in various address component types
      if ((types.includes('locality') || types.includes('administrative_area_level_2') ||
           types.includes('sublocality') || types.includes('administrative_area_level_1')) &&
          (name.includes('mumbai') || name.includes('bombay'))) {
        return true
      }
    }
    return false
  }

  showLocationWarning(message) {
    // Remove existing warning
    this.hideLocationWarning()

    // Create warning element
    const warning = document.createElement('div')
    warning.className = 'location-warning mt-2 p-3 bg-orange-100 border border-orange-300 text-orange-800 rounded-lg text-sm'
    warning.innerHTML = `
      <div class="flex items-center">
        <span class="mr-2">⚠️</span>
        <span>${message}</span>
      </div>
    `

    // Insert after the input
    this.inputTarget.parentNode.insertBefore(warning, this.inputTarget.nextSibling)
  }

  hideLocationWarning() {
    const existing = document.querySelector('.location-warning')
    if (existing) {
      existing.remove()
    }
  }

  disconnect() {
    if (this.autocomplete) {
      window.google.maps.event.clearInstanceListeners(this.autocomplete)
    }
    delete window.initPlacesAutocomplete
  }
}