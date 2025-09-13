// ***********************************************************
// This file is loaded automatically before your test files.
//
// This is a great place to put global configuration and
// behavior that modifies Cypress.
//
// ***********************************************************

// Import commands.js using ES2015 syntax:
import './commands'

// Cypress Google Maps helper commands
Cypress.Commands.add('waitForGoogleMaps', () => {
  cy.window().should('have.property', 'google')
  cy.window().its('google').should('have.property', 'maps')
  cy.get('#map').should('be.visible')
})

// Wait for boundary tracer to initialize
Cypress.Commands.add('waitForBoundaryTracer', () => {
  cy.waitForGoogleMaps()
  cy.get('#controls').should('be.visible')
  cy.get('#pdf-image').should('be.visible')
})