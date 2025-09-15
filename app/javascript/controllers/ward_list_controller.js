import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item"]

  connect() {
    console.log("Ward list controller connected")
    this.setupItemListeners()
  }

  setupItemListeners() {
    // Find all ward sidebar items and add hover listeners
    const wardItems = document.querySelectorAll('.ward-sidebar-item')

    wardItems.forEach(item => {
      item.addEventListener('mouseenter', (e) => {
        const wardCode = e.currentTarget.dataset.wardCode
        if (wardCode) {
          this.hoverWard(wardCode)
        }
      })

      item.addEventListener('mouseleave', (e) => {
        const wardCode = e.currentTarget.dataset.wardCode
        if (wardCode) {
          this.unhoverWard(wardCode)
        }
      })
    })
  }

  hoverWard(wardCode) {
    // Find the leaflet map controller and trigger hover
    const mapController = this.application.getControllerForElementAndIdentifier(
      document.querySelector('[data-controller*="leaflet-map"]'),
      'leaflet-map'
    )

    if (mapController && typeof mapController.hoverWard === 'function') {
      mapController.hoverWard(wardCode)
    }
  }

  unhoverWard(wardCode) {
    // Find the leaflet map controller and trigger unhover
    const mapController = this.application.getControllerForElementAndIdentifier(
      document.querySelector('[data-controller*="leaflet-map"]'),
      'leaflet-map'
    )

    if (mapController && typeof mapController.unhoverWard === 'function') {
      mapController.unhoverWard(wardCode)
    }
  }

  scrollToWard(wardCode) {
    console.log(`Scrolling to ward ${wardCode} in sidebar`)

    // Find the ward item in the sidebar
    const wardItem = document.querySelector(`[data-ward-code="${wardCode}"]`)
    if (!wardItem) {
      console.warn(`Ward item with code ${wardCode} not found`)
      return
    }

    // Highlight the selected ward item temporarily
    this.highlightWardItem(wardItem)

    // Use scrollIntoView with center block positioning for reliable centering
    wardItem.scrollIntoView({
      behavior: 'smooth',
      block: 'center',
      inline: 'nearest'
    })
  }

  highlightWardItem(wardItem) {
    // Remove any existing highlights
    document.querySelectorAll('.ward-sidebar-item.highlighted').forEach(item => {
      item.classList.remove('highlighted')
    })

    // Add highlight class to the selected item
    wardItem.classList.add('highlighted')

    // Remove highlight after 2 seconds
    setTimeout(() => {
      wardItem.classList.remove('highlighted')
    }, 2000)
  }
}