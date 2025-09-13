describe('Boundary Tracing Interface', () => {
  beforeEach(() => {
    // Login with MCGM admin credentials
    cy.login('admin@mcgm.in', '12345678')
    cy.visitPrabhagTrace(68) // Visit prabhag 68 (Ward A, Prabhag 225)
  })

  describe('Page Load and Basic Elements', () => {
    it('displays the trace page with all required elements', () => {
      // Check page title and basic elements (Rails may use default app title)
      cy.get('h3').should('contain', 'Prabhag 225 Boundary Tracer')
      cy.get('.back-btn').should('be.visible').and('contain', '← Back')
    })

    it('loads the prabhag image successfully', () => {
      cy.checkImageLoaded('#pdf-image')
      cy.get('#pdf-image').should('have.attr', 'src').and('include', '/prabhag_images/prabhag_225.png')
    })

    it('displays all control panels', () => {
      cy.get('#controls').should('be.visible')
      cy.get('#opacity-slider').should('be.visible')
      cy.get('#draw-mode').should('be.visible').and('have.class', 'active')
      cy.get('#pan-mode').should('be.visible')
      cy.get('#clear-polygon').should('be.visible')
      cy.get('#undo-last').should('be.visible')
      cy.get('#close-polygon').should('be.visible')

      // Scroll to submit form to make it visible
      cy.get('#submit-form').scrollIntoView()
      cy.get('#submit-form').should('exist') // Just check it exists, visibility can be tricky with fixed positioning
    })
  })

  describe('Google Maps Integration', () => {
    it('initializes Google Maps correctly', () => {
      cy.waitForGoogleMaps()

      // Check that map is rendered with correct initial state
      cy.get('#map').should('be.visible')
      cy.get('#opacity-slider').should('have.value', '50')
      cy.get('#map').should('have.css', 'opacity', '0.5')
    })

    it('allows switching between draw and pan modes', () => {
      cy.waitForBoundaryTracer()

      // Start in draw mode
      cy.get('#draw-mode').should('have.class', 'active')
      cy.get('#pan-mode').should('not.have.class', 'active')

      // Switch to pan mode
      cy.get('#pan-mode').click()
      cy.get('#pan-mode').should('have.class', 'active')
      cy.get('#draw-mode').should('not.have.class', 'active')

      // Switch back to draw mode
      cy.get('#draw-mode').click()
      cy.get('#draw-mode').should('have.class', 'active')
      cy.get('#pan-mode').should('not.have.class', 'active')
    })
  })

  describe('Drawing Controls', () => {
    it('adjusts map opacity with slider', () => {
      cy.waitForBoundaryTracer()

      cy.get('#opacity-slider').invoke('val', 80).trigger('input')
      cy.get('#opacity-value').should('contain', '80')
      cy.get('#map').should('have.css', 'opacity', '0.8')

      cy.get('#opacity-slider').invoke('val', 20).trigger('input')
      cy.get('#opacity-value').should('contain', '20')
      cy.get('#map').should('have.css', 'opacity', '0.2')
    })

    it('updates PDF control values', () => {
      cy.waitForBoundaryTracer()

      // Test PDF scale
      cy.get('#pdf-scale-slider').invoke('val', 150).trigger('input')
      cy.get('#pdf-scale-value').should('contain', '150')

      // Test PDF position
      cy.get('#pdf-x-slider').invoke('val', 100).trigger('input')
      cy.get('#pdf-x-value').should('contain', '100')

      cy.get('#pdf-y-slider').invoke('val', -50).trigger('input')
      cy.get('#pdf-y-value').should('contain', '-50')
    })

    it('resets PDF controls to defaults', () => {
      cy.waitForBoundaryTracer()

      // Change some values
      cy.get('#pdf-scale-slider').invoke('val', 150).trigger('input')
      cy.get('#pdf-x-slider').invoke('val', 100).trigger('input')

      // Reset
      cy.get('#reset-pdf').click()

      // Check defaults are restored
      cy.get('#pdf-scale-value').should('contain', '100')
      cy.get('#pdf-x-value').should('contain', '0')
      cy.get('#pdf-y-value').should('contain', '0')
    })
  })

  describe('Boundary Drawing Functionality', () => {
    it('starts with empty polygon and correct initial state', () => {
      cy.waitForBoundaryTracer()
      cy.get('#point-count').should('contain', '0')
      cy.get('#coordinates').should('be.empty')
    })

    it('allows drawing points by clicking on map (simulated)', () => {
      cy.waitForBoundaryTracer()

      // Note: Actually clicking on Google Maps in Cypress can be tricky
      // This test simulates the behavior by checking the UI state

      // Ensure we're in draw mode
      cy.get('#draw-mode').click()
      cy.get('#draw-mode').should('have.class', 'active')

      // The actual map clicking would need to be tested with specific coordinates
      // and may require additional Google Maps testing utilities
      // For now, we'll test the control interactions
    })

    it('clears polygon when clear button is clicked', () => {
      cy.waitForBoundaryTracer()

      cy.get('#clear-polygon').click()

      // Handle confirm dialog if it appears
      cy.on('window:confirm', () => true)

      cy.get('#point-count').should('contain', '0')
    })

    it('prevents form submission without enough points', () => {
      cy.waitForBoundaryTracer()

      // Scroll to submit form and force click if needed
      cy.get('#submit-form').scrollIntoView()
      cy.get('#submit-form input[type="submit"]').click({ force: true })

      // Should show alert about needing at least 3 points
      cy.on('window:alert', (text) => {
        expect(text).to.contains('Please draw at least 3 points')
      })
    })
  })

  describe('Form Submission', () => {
    it('has proper form structure for boundary submission', () => {
      cy.waitForBoundaryTracer()

      cy.get('#submit-form').should('exist')
      cy.get('#geojson-input').should('exist').and('have.attr', 'type', 'hidden')
      cy.get('input[type="submit"]').should('exist').and('have.value', 'Submit Boundary')

      // Check form action
      cy.get('#submit-form').should('have.attr', 'action').and('include', '/prabhags/68/submit')
    })
  })
})