import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]
  static values = {
    dataUrl: String,
    showLabels: { type: Boolean, default: true },
    showLegend: { type: Boolean, default: true },
    clickable: { type: Boolean, default: true },
    zoom: { type: Number, default: 11 },
    static: { type: Boolean, default: false }
  }

  connect() {
    console.log("Ward boundary controller connected")
    this.wardLayers = new Map() // Store ward layers by ward_code
    this.wardLabels = new Map() // Store ward labels by ward_code
    this.initializeMap()
  }

  disconnect() {
    if (this.mapInstance) {
      this.mapInstance.remove()
      this.mapInstance = null
    }
  }

  async initializeMap() {
    try {
      // Load Leaflet if not already loaded
      if (!window.L) {
        const script = document.createElement('script')
        script.src = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js'
        document.head.appendChild(script)

        await new Promise((resolve) => {
          script.onload = resolve
        })
      }

      // Load CSS if not already loaded
      if (!document.querySelector('link[href*="leaflet"]')) {
        const css = document.createElement('link')
        css.rel = 'stylesheet'
        css.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css'
        document.head.appendChild(css)
      }

      // Create map centered on Mumbai with optional touch/scroll control disabling
      const mapOptions = this.staticValue ? {
        touchZoom: false,
        scrollWheelZoom: false,
        boxZoom: false,
        keyboard: false
      } : {}

      if (!this.containerTarget) {
        console.error("Container target not found")
        return
      }

      this.mapInstance = window.L.map(this.containerTarget, mapOptions).setView([19.0760, 72.8777], this.zoomValue)

      if (!this.mapInstance) {
        console.error("Failed to create map instance")
        return
      }

      // Move zoom control to bottom left
      this.mapInstance.zoomControl.setPosition('bottomleft')

      // Add OpenStreetMap tiles
      window.L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
        maxZoom: 20,
        attribution: '© OpenStreetMap contributors'
      }).addTo(this.mapInstance)

      console.log("Map initialized, loading ward boundaries...")
      this.loadWardBoundaries()

    } catch (error) {
      console.error("Failed to initialize map:", error)
    }
  }

  async loadWardBoundaries() {
    try {
      if (!this.mapInstance) {
        console.error("Map instance not initialized yet")
        return
      }

      const response = await fetch(this.dataUrlValue || '/wards.json')
      const data = await response.json()

      // The API should now return a simple array of GeoJSON Features
      const features = data.features || []

      console.log(`Loading ${features.length} map features`)

      features.forEach((feature) => {
        try {
          // Create layer using the styling information embedded in feature properties
          const props = feature.properties
          const layer = window.L.geoJSON(feature, {
            style: {
              color: props.color || '#6b7280',
              weight: props.weight || 1,
              opacity: 0.8,
              fillColor: props.fillColor || props.color || '#6b7280',
              fillOpacity: props.fillOpacity || 0.1
            }
          }).addTo(this.mapInstance)

          // Store the layer reference if it has a ward_code
          if (props.ward_code) {
            this.wardLayers.set(props.ward_code, layer)
          }

          // Add label if enabled and properties specify it
          let labelMarker = null
          if (this.showLabelsValue && props.short_name) {
            const bounds = layer.getBounds()
            if (bounds.isValid()) {
              const center = bounds.getCenter()

              labelMarker = window.L.marker(center, {
                icon: window.L.divIcon({
                  className: 'map-label',
                  html: `<div class="label-text" style="
                    color: #374151;
                    font-weight: 600;
                    font-size: 12px;
                    text-align: center;
                    background: white;
                    padding: 2px 4px;
                    border-radius: 2px;
                    pointer-events: none;
                    user-select: none;
                    transition: all 0.2s ease;
                  ">${props.short_name}</div>`,
                  iconSize: [30, 15],
                  iconAnchor: [15, 7]
                }),
                interactive: false
              }).addTo(this.mapInstance)

              // Store the label reference if it has a ward_code
              if (props.ward_code) {
                this.wardLabels.set(props.ward_code, labelMarker)
              }
            }
          }

          // Add interactions if clickable
          if (this.clickableValue) {
            layer.on('mouseover', (e) => {
              e.target.setStyle({
                weight: (props.weight || 1) + 1,
                opacity: 1,
                fillOpacity: Math.min((props.fillOpacity || 0.1) + 0.2, 0.5)
              })

              // Highlight the label if it exists
              if (labelMarker) {
                const labelElement = labelMarker.getElement().querySelector('.label-text')
                if (labelElement) {
                  labelElement.style.background = '#3b82f6'
                  labelElement.style.color = 'white'
                  labelElement.style.transform = 'scale(1.1)'
                }
              }
            })

            layer.on('mouseout', (e) => {
              e.target.setStyle({
                weight: props.weight || 1,
                opacity: 0.8,
                fillOpacity: props.fillOpacity || 0.1
              })

              // Reset the label if it exists
              if (labelMarker) {
                const labelElement = labelMarker.getElement().querySelector('.label-text')
                if (labelElement) {
                  labelElement.style.background = 'white'
                  labelElement.style.color = '#374151'
                  labelElement.style.transform = 'scale(1)'
                }
              }
            })

            // Add click handler for ward selection
            layer.on('click', (e) => {
              if (props.ward_code) {
                this.selectWard(props.ward_code)
              }
            })

            // Create popup using embedded information
            if (props.popup_title) {
              layer.bindPopup(`
                <div class="p-2">
                  <h3 class="font-bold">${props.popup_title}</h3>
                  ${props.popup_subtitle ? `<p class="text-sm text-gray-600">${props.popup_subtitle}</p>` : ''}
                  ${props.popup_details ? `<p class="text-xs text-gray-500 mt-1">${props.popup_details}</p>` : ''}
                  ${props.ward_code ? `<a href="/wards/${props.ward_code}" class="inline-block mt-2 text-blue-600 hover:text-blue-800 text-sm font-medium">Visit Ward →</a>` : ''}
                </div>
              `)
            }
          }

        } catch (parseError) {
          console.error(`Failed to process feature:`, parseError)
        }
      })

      // Fit bounds to show all features
      if (features.length > 0) {
        setTimeout(() => {
          try {
            const validLayers = []
            this.mapInstance.eachLayer(layer => {
              if (layer.getBounds && typeof layer.getBounds === 'function') {
                const bounds = layer.getBounds()
                if (bounds.isValid()) {
                  validLayers.push(layer)
                }
              }
            })

            console.log(`Found ${validLayers.length} valid layers for fitBounds`)

            if (validLayers.length > 0) {
              const group = new window.L.featureGroup(validLayers)
              const bounds = group.getBounds()
              console.log("Fitting bounds:", bounds)
              // For small boundaries, allow higher zoom levels
              const maxZoom = this.zoomValue || 18
              this.mapInstance.fitBounds(bounds, { padding: [20, 20], maxZoom: maxZoom })
            } else {
              console.warn("No valid layers found for fitBounds")
            }
          } catch (e) {
            console.warn("Could not fit bounds:", e)
          }
        }, 100)
      }

      console.log(`Successfully loaded ${features.length} map features`)

    } catch (error) {
      console.error("Failed to load map data:", error)
    }
  }

  // Method to hover over a specific ward from external trigger
  hoverWard(wardCode) {
    const layer = this.wardLayers.get(wardCode)
    const label = this.wardLabels.get(wardCode)

    if (layer && this.clickableValue) {
      // Get the layer's properties
      const props = layer.feature?.properties || {}

      // Apply hover styling
      layer.setStyle({
        weight: (props.weight || 1) + 1,
        opacity: 1,
        fillOpacity: Math.min((props.fillOpacity || 0.1) + 0.2, 0.5)
      })

      // Highlight the label
      if (label) {
        const labelElement = label.getElement()?.querySelector('.label-text')
        if (labelElement) {
          labelElement.style.background = '#3b82f6'
          labelElement.style.color = 'white'
          labelElement.style.transform = 'scale(1.1)'
        }
      }

      // Pan to the ward center
      const bounds = layer.getBounds()
      if (bounds.isValid()) {
        const center = bounds.getCenter()
        this.mapInstance.panTo(center, { animate: true, duration: 0.5 })
      }
    }
  }

  // Method to remove hover effect from a specific ward
  unhoverWard(wardCode) {
    const layer = this.wardLayers.get(wardCode)
    const label = this.wardLabels.get(wardCode)

    if (layer && this.clickableValue) {
      // Get the layer's properties
      const props = layer.feature?.properties || {}

      // Reset styling
      layer.setStyle({
        weight: props.weight || 1,
        opacity: 0.8,
        fillOpacity: props.fillOpacity || 0.1
      })

      // Reset the label
      if (label) {
        const labelElement = label.getElement()?.querySelector('.label-text')
        if (labelElement) {
          labelElement.style.background = 'white'
          labelElement.style.color = '#374151'
          labelElement.style.transform = 'scale(1)'
        }
      }
    }
  }

  // Method to select a ward (triggered by map click)
  selectWard(wardCode) {
    console.log(`Ward ${wardCode} selected from map`)

    // Find the ward list controller and trigger scroll to ward
    const wardListController = this.application.getControllerForElementAndIdentifier(
      document.querySelector('[data-controller*="ward-list"]'),
      'ward-list'
    )

    if (wardListController && typeof wardListController.scrollToWard === 'function') {
      wardListController.scrollToWard(wardCode)
    }

    // Dispatch a custom event for other components to listen to
    this.dispatch('wardSelected', { detail: { wardCode } })
  }

}