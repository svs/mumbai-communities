import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String,
    wardId: String
  }

  connect() {
    this.facilityLayers = new Map()
    this.waitForMap()
  }

  disconnect() {
    this.facilityLayers.forEach(layer => {
      if (this.map) this.map.removeLayer(layer)
    })
  }

  waitForMap() {
    // Wait for the leaflet-map controller to initialize
    const mapElement = document.querySelector('[data-controller*="leaflet-map"]')
    if (!mapElement) return

    const check = () => {
      const mapController = this.application.getControllerForElementAndIdentifier(mapElement, 'leaflet-map')
      if (mapController && mapController.mapInstance) {
        this.map = mapController.mapInstance
        this.loadFacilities()
      } else {
        setTimeout(check, 200)
      }
    }
    check()
  }

  async loadFacilities() {
    if (!this.map || !this.urlValue) return

    try {
      const response = await fetch(this.urlValue)
      const geojson = await response.json()

      if (!geojson.features) return

      // Group features by facility_type
      const byType = {}
      geojson.features.forEach(feature => {
        const type = feature.properties.facility_type
        if (!byType[type]) byType[type] = []
        byType[type].push(feature)
      })

      // Create a LayerGroup per type
      Object.entries(byType).forEach(([type, features]) => {
        const markers = features.map(feature => {
          const [lng, lat] = feature.geometry.coordinates
          const props = feature.properties
          const color = props.marker_color || '#6b7280'

          return window.L.circleMarker([lat, lng], {
            radius: 6,
            fillColor: color,
            color: color,
            weight: 1,
            opacity: 0.9,
            fillOpacity: 0.7
          }).bindPopup(`
            <div class="text-sm">
              <strong>${props.name || 'Unnamed'}</strong>
              <div class="text-xs text-gray-500 mt-1">${props.facility_type_label}</div>
              <div class="text-xs mt-1">
                <span class="inline-block px-1 rounded ${props.source_badge_class}">${props.source_label}</span>
              </div>
              ${props.address ? `<div class="text-xs text-gray-400 mt-1">${props.address}</div>` : ''}
            </div>
          `)
        })

        const layerGroup = window.L.layerGroup(markers).addTo(this.map)
        this.facilityLayers.set(type, layerGroup)
      })
    } catch (error) {
      console.error("Failed to load facilities:", error)
    }
  }

  toggleType(event) {
    const type = event.currentTarget.dataset.facilityType
    const layer = this.facilityLayers.get(type)
    if (!layer) return

    if (event.currentTarget.checked) {
      this.map.addLayer(layer)
    } else {
      this.map.removeLayer(layer)
    }
  }
}
