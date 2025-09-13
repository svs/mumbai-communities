import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="boundary-tracer"
export default class extends Controller {
  static values = {
    prabhagId: Number,
    pdfUrl: String,
    apiKey: String,
    center: Object,
    initialZoom: Number
  }

  static targets = [
    "pdfImage", "map", "pdfControls", "mapControls",
    "coordinatesDisplay", "pointCount",
    "geojsonInput", "submitForm"
  ]

  connect() {
    console.log("Boundary tracer connected")

    // Initialize drawing state
    this.coordinates = []
    this.markers = []
    this.polygon = null
    this.map = null

    // Initialize PDF zoom and pan state
    this.pdfZoomLevel = 1
    this.pdfPanX = 0
    this.pdfPanY = 0

    // Initialize PDF drag state
    this.isDragging = false
    this.dragStartX = 0
    this.dragStartY = 0

    this.initializeMap()
    this.setupPDFDrag()
  }

  initializeMap() {
    console.log("Initializing map...")

    const script = document.createElement('script')
    script.src = `https://maps.googleapis.com/maps/api/js?key=${this.apiKeyValue}&callback=initMapCallback`
    script.async = true
    script.defer = true

    // Set up global callback
    window.initMapCallback = () => {
      console.log("Google Maps API loaded, creating map...")
      this.createMap()
    }

    script.onerror = (error) => {
      console.error("Failed to load Google Maps API:", error)
    }

    document.head.appendChild(script)
    console.log("Google Maps script added to head")
  }

  createMap() {
    console.log("Creating map...")
    const center = this.centerValue || { lat: 19.137, lng: 72.849 }
    const zoom = this.initialZoomValue || 15

    try {
      this.map = new google.maps.Map(this.mapTarget, {
        center: center,
        zoom: zoom,
        mapTypeId: 'roadmap',
        disableDefaultUI: false,
        scrollwheel: true,
        draggable: true
      })

      console.log("Map created successfully")
    } catch (error) {
      console.error("Error creating map:", error)
      return
    }

    this.setupPolygon()
    this.setupMapListeners()
  }

  setupPolygon() {
    this.polygon = new google.maps.Polygon({
      paths: this.coordinates,
      strokeColor: '#FF0000',
      strokeOpacity: 0.8,
      strokeWeight: 3,
      fillColor: '#FF0000',
      fillOpacity: 0.2,
      editable: false,
      clickable: false
    })
    this.polygon.setMap(this.map)
  }

  setupMapListeners() {
    // Add click listener for drawing (always active)
    this.map.addListener('click', (event) => {
      this.addPoint(event.latLng)
    })
  }


  addPoint(latLng) {
    const coord = {
      lat: latLng.lat(),
      lng: latLng.lng()
    }
    
    this.coordinates.push(coord)
    
    // Add small invisible marker for dragging
    const marker = new google.maps.Marker({
      position: latLng,
      map: this.map,
      draggable: true,
      icon: {
        path: google.maps.SymbolPath.CIRCLE,
        scale: 3,
        fillColor: '#FF0000',
        fillOpacity: 0.6,
        strokeColor: '#FFFFFF',
        strokeWeight: 1
      }
    })
    
    // Handle marker drag
    marker.addListener('dragend', () => {
      const index = this.markers.indexOf(marker)
      this.coordinates[index] = {
        lat: marker.getPosition().lat(),
        lng: marker.getPosition().lng()
      }
      this.updatePolygon()
    })
    
    // Handle marker click to delete
    marker.addListener('click', () => {
      this.deletePoint(marker)
    })
    
    this.markers.push(marker)
    this.updatePolygon()
    this.updatePointCount()
  }

  updatePolygon() {
    this.polygon.setPath(this.coordinates)
  }

  updatePointCount() {
    this.pointCountTarget.textContent = this.coordinates.length
  }


  // Mode switching (no longer needed but kept for compatibility)
  setDrawMode(event) {
    // Draw mode is always active now
    if (event && event.target) {
      event.target.classList.add('active')
      const buttons = event.target.parentElement.querySelectorAll('button')
      buttons.forEach(btn => {
        if (btn !== event.target) btn.classList.remove('active')
      })
    }
  }

  setPanMode(event) {
    // Pan mode is always active now
    if (event && event.target) {
      event.target.classList.add('active')
      const buttons = event.target.parentElement.querySelectorAll('button')
      buttons.forEach(btn => {
        if (btn !== event.target) btn.classList.remove('active')
      })
    }
  }

  closePolygon() {
    if (this.coordinates.length > 2) {
      // Close the polygon by adding the first point to the end
      const firstCoord = this.coordinates[0]
      const lastCoord = this.coordinates[this.coordinates.length - 1]
      
      if (firstCoord.lat !== lastCoord.lat || firstCoord.lng !== lastCoord.lng) {
        this.coordinates.push(firstCoord)
        this.updatePolygon()
        this.updatePointCount()
      }
      
      // Generate GeoJSON and populate hidden field
      this.generateGeoJSON()
    }
  }

  clearBoundary() {
    if (confirm('Clear all points?')) {
      this.coordinates = []
      this.markers.forEach(marker => marker.setMap(null))
      this.markers = []
      this.updatePolygon()
      this.updatePointCount()
      this.geojsonInputTarget.value = ''
    }
  }

  undoLastPoint() {
    if (this.coordinates.length > 0) {
      this.coordinates.pop()
      const marker = this.markers.pop()
      if (marker) marker.setMap(null)
      this.updatePolygon()
      this.updatePointCount()
    }
  }

  deletePoint(marker) {
    const index = this.markers.indexOf(marker)
    if (index > -1) {
      this.coordinates.splice(index, 1)
      this.markers.splice(index, 1)
      marker.setMap(null)
      this.updatePolygon()
      this.updatePointCount()
    }
  }

  generateGeoJSON(event) {
    if (this.coordinates.length < 3) {
      alert('Please draw at least 3 points')
      event.preventDefault()
      return
    }

    // Ensure polygon is closed
    let exportCoords = [...this.coordinates]
    if (exportCoords[0] !== exportCoords[exportCoords.length - 1]) {
      exportCoords.push(exportCoords[0])
    }

    const geojson = {
      type: 'Feature',
      properties: {
        prabhag_id: this.prabhagIdValue,
        created: new Date().toISOString()
      },
      geometry: {
        type: 'Polygon',
        coordinates: [exportCoords.map(coord => [coord.lng, coord.lat])]
      }
    }

    this.geojsonInputTarget.value = JSON.stringify(geojson)
    console.log('Generated GeoJSON:', geojson)
  }

  updateCoordinatesDisplay() {
    if (this.hasCoordinatesDisplayTarget) {
      this.coordinatesDisplayTarget.innerHTML = this.coordinates.map((coord, i) =>
        `${i + 1}: [${coord.lng.toFixed(6)}, ${coord.lat.toFixed(6)}]`
      ).join('<br>')
    }
  }

  // PDF Zoom Controls
  zoomPDFIn() {
    this.pdfZoomLevel = Math.min(this.pdfZoomLevel * 1.2, 5) // Max 5x zoom
    this.updatePDFZoom()
  }

  zoomPDFOut() {
    this.pdfZoomLevel = Math.max(this.pdfZoomLevel / 1.2, 0.5) // Min 0.5x zoom
    this.updatePDFZoom()
  }

  resetPDFZoom() {
    this.pdfZoomLevel = 1
    this.pdfPanX = 0
    this.pdfPanY = 0
    this.updatePDFTransform()
  }

  updatePDFZoom() {
    this.updatePDFTransform()
  }

  updatePDFTransform() {
    this.pdfImageTarget.style.transform = `translate(${this.pdfPanX}px, ${this.pdfPanY}px) scale(${this.pdfZoomLevel})`
    this.pdfImageTarget.style.transformOrigin = 'center center'
  }

  // PDF Drag functionality
  setupPDFDrag() {
    const pdfImage = this.pdfImageTarget
    pdfImage.style.cursor = 'grab'
    
    // Mouse events
    pdfImage.addEventListener('mousedown', this.startDrag.bind(this))
    document.addEventListener('mousemove', this.drag.bind(this))
    document.addEventListener('mouseup', this.endDrag.bind(this))
    
    // Touch events for mobile
    pdfImage.addEventListener('touchstart', this.startDrag.bind(this))
    document.addEventListener('touchmove', this.drag.bind(this))
    document.addEventListener('touchend', this.endDrag.bind(this))
    
    // Prevent context menu on right click
    pdfImage.addEventListener('contextmenu', (e) => e.preventDefault())
  }

  startDrag(e) {
    this.isDragging = true
    const clientX = e.clientX || e.touches[0].clientX
    const clientY = e.clientY || e.touches[0].clientY
    this.dragStartX = clientX - this.pdfPanX
    this.dragStartY = clientY - this.pdfPanY
    this.pdfImageTarget.style.cursor = 'grabbing'
    e.preventDefault()
  }

  drag(e) {
    if (!this.isDragging) return
    
    const clientX = e.clientX || e.touches[0].clientX
    const clientY = e.clientY || e.touches[0].clientY
    
    this.pdfPanX = clientX - this.dragStartX
    this.pdfPanY = clientY - this.dragStartY
    
    this.updatePDFTransform()
    e.preventDefault()
  }

  endDrag(e) {
    if (!this.isDragging) return
    this.isDragging = false
    this.pdfImageTarget.style.cursor = 'grab'
  }

  // PDF Drag functionality
  setupPDFDrag() {
    const pdfImage = this.pdfImageTarget
    
    // Mouse events
    pdfImage.addEventListener('mousedown', this.startDrag.bind(this))
    document.addEventListener('mousemove', this.drag.bind(this))
    document.addEventListener('mouseup', this.endDrag.bind(this))
    
    // Touch events for mobile
    pdfImage.addEventListener('touchstart', this.startDrag.bind(this))
    document.addEventListener('touchmove', this.drag.bind(this))
    document.addEventListener('touchend', this.endDrag.bind(this))
    
    // Prevent context menu on right click
    pdfImage.addEventListener('contextmenu', (e) => e.preventDefault())
  }

  startDrag(e) {
    this.isDragging = true
    const clientX = e.clientX || e.touches[0].clientX
    const clientY = e.clientY || e.touches[0].clientY
    this.dragStartX = clientX - this.pdfPanX
    this.dragStartY = clientY - this.pdfPanY
    this.pdfImageTarget.style.cursor = 'grabbing'
    e.preventDefault()
  }

  drag(e) {
    if (!this.isDragging) return
    
    const clientX = e.clientX || e.touches[0].clientX
    const clientY = e.clientY || e.touches[0].clientY
    
    this.pdfPanX = clientX - this.dragStartX
    this.pdfPanY = clientY - this.dragStartY
    
    this.updatePDFTransform()
    e.preventDefault()
  }

  endDrag(e) {
    if (!this.isDragging) return
    this.isDragging = false
    this.pdfImageTarget.style.cursor = 'grab'
  }

  // PDF Pan Controls
  panPDFUp() {
    this.pdfPanY -= 100
    this.updatePDFTransform()
  }

  panPDFDown() {
    this.pdfPanY += 100
    this.updatePDFTransform()
  }

  panPDFLeft() {
    this.pdfPanX -= 100
    this.updatePDFTransform()
  }

  panPDFRight() {
    this.pdfPanX += 100
    this.updatePDFTransform()
  }
}
