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
    // Find the ward boundary controller and trigger hover
    const mapController = this.application.getControllerForElementAndIdentifier(
      document.querySelector('[data-controller*="ward-boundary"]'),
      'ward-boundary'
    )

    if (mapController && typeof mapController.hoverWard === 'function') {
      mapController.hoverWard(wardCode)
    }
  }

  unhoverWard(wardCode) {
    // Find the ward boundary controller and trigger unhover
    const mapController = this.application.getControllerForElementAndIdentifier(
      document.querySelector('[data-controller*="ward-boundary"]'),
      'ward-boundary'
    )

    if (mapController && typeof mapController.unhoverWard === 'function') {
      mapController.unhoverWard(wardCode)
    }
  }
}