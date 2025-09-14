import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="ward"
export default class extends Controller {
  static values = {
    wardBoundary: Object,
    prabhagBoundaries: Array,
    wardCode: String
  }

  connect() {
    // Load Leaflet CSS and JS dynamically
    this.loadLeaflet().then(() => {
      this.initializeMap()
    })
  }

  disconnect() {
    if (this.mapInstance) {
      this.mapInstance.remove()
      this.mapInstance = null
    }
  }

  async loadLeaflet() {
    // Load CSS if not already loaded
    if (!document.querySelector('link[href*="leaflet"]')) {
      const css = document.createElement('link')
      css.rel = 'stylesheet'
      css.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css'
      document.head.appendChild(css)
    }

    // Load JS if not already loaded
    if (!window.L) {
      return new Promise((resolve) => {
        const script = document.createElement('script')
        script.src = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js'
        script.onload = resolve
        document.head.appendChild(script)
      })
    }
  }

  initializeMap() {
    // Clean up existing map
    if (this.mapInstance) {
      this.mapInstance.remove()
      this.mapInstance = null
    }

    // Initialize map centered on Mumbai
    this.mapInstance = L.map(this.element).setView([19.0760, 72.8777], 12)

    // Add OpenStreetMap tiles
    L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 18,
      attribution: '© OpenStreetMap contributors'
    }).addTo(this.mapInstance)

    let bounds = L.latLngBounds()

    // Add ward boundary if available
    if (this.wardBoundaryValue && Object.keys(this.wardBoundaryValue).length > 0) {
      try {
        const wardGeoJSON = JSON.parse(this.wardBoundaryValue.geojson)

        const wardLayer = L.geoJSON(wardGeoJSON, {
          style: {
            color: '#2563eb',
            weight: 3,
            opacity: 0.8,
            fillColor: '#3b82f6',
            fillOpacity: 0.1
          }
        }).addTo(this.mapInstance)

        wardLayer.bindPopup(`
          <div class="p-2">
            <h3 class="font-semibold">Ward ${this.wardCodeValue}</h3>
            <p class="text-sm text-gray-600">Municipal Ward Boundary</p>
            <p class="text-xs text-gray-500 mt-1">${this.wardBoundaryValue.source_type} (${this.wardBoundaryValue.year})</p>
          </div>
        `)

        bounds.extend(wardLayer.getBounds())
      } catch (e) {
        console.error('Error loading ward boundary:', e)
      }
    }

    // Add prabhag boundaries if available
    if (this.prabhagBoundariesValue && this.prabhagBoundariesValue.length > 0) {
      this.prabhagBoundariesValue.forEach(prabhag => {
        if (prabhag.geojson) {
          try {
            // Parse the JSON string - it's already a complete GeoJSON Feature
            const prabhagGeoJSON = JSON.parse(prabhag.geojson)

            // Get colors based on boundary type and status
            const colors = this.getBoundaryColors(prabhag.source_type, prabhag.status)

            const prabhagLayer = L.geoJSON(prabhagGeoJSON, {
              style: {
                color: colors.border,
                weight: 2,
                opacity: 0.8,
                fillColor: colors.fill,
                fillOpacity: 0.2
              }
            }).addTo(this.mapInstance)

            prabhagLayer.bindPopup(`
              <div class="p-2">
                <h3 class="font-semibold">Prabhag ${prabhag.number}</h3>
                <p class="text-sm text-gray-600">Ward ${this.wardCodeValue}</p>
                <p class="text-xs text-gray-500 mt-1">${this.getBoundaryLabel(prabhag.source_type, prabhag.status)} (${prabhag.year})</p>
                <div class="mt-2">
                  <a href="/prabhags/${prabhag.id}" class="text-blue-600 hover:underline text-sm">
                    View Details →
                  </a>
                </div>
              </div>
            `)

            bounds.extend(prabhagLayer.getBounds())
          } catch (e) {
            console.error(`Error loading prabhag ${prabhag.number} boundary:`, e)
          }
        }
      })
    }

    // Fit map to show all boundaries
    if (bounds.isValid()) {
      this.mapInstance.fitBounds(bounds, { padding: [20, 20] })
    }
  }

  // Determine boundary colors based on source type and status
  getBoundaryColors(sourceType, status) {
    // Legacy boundaries (from old KML import)
    if (sourceType === 'kml_import') {
      if (status === 'approved') {
        return { border: '#f59e0b', fill: '#fbbf24' } // amber - legacy approved
      }
    }

    // New official boundaries
    if (sourceType === 'official_import') {
      if (status === 'canonical') {
        return { border: '#16a34a', fill: '#22c55e' } // green - new canonical
      }
      if (status === 'approved') {
        return { border: '#059669', fill: '#10b981' } // emerald - new approved
      }
    }

    // User submissions
    if (sourceType === 'user_submission') {
      if (status === 'approved') {
        return { border: '#8b5cf6', fill: '#a78bfa' } // purple - user approved
      }
    }

    // Default fallback
    return { border: '#6b7280', fill: '#9ca3af' } // gray - unknown status
  }

  // Get human-readable label for boundary
  getBoundaryLabel(sourceType, status) {
    if (sourceType === 'kml_import' && status === 'approved') {
      return 'Legacy boundary'
    }
    if (sourceType === 'official_import' && status === 'canonical') {
      return 'Official (canonical)'
    }
    if (sourceType === 'official_import' && status === 'approved') {
      return 'Official (approved)'
    }
    if (sourceType === 'user_submission' && status === 'approved') {
      return 'Community mapped'
    }
    return `${sourceType} (${status})`
  }
}