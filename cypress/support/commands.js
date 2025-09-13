// ***********************************************
// Custom commands for Rails authentication and common actions
// ***********************************************

// Login command with correct MCGM credentials
Cypress.Commands.add('login', (email = 'admin@mcgm.in', password = '12345678') => {
  cy.visit('/users/sign_in')
  cy.get('input[name="user[email]"]', { timeout: 8000 }).should('be.visible').type(email)
  cy.get('input[name="user[password]"]').should('be.visible').type(password)
  cy.get('input[type="submit"]').click()

  // Wait for successful login redirect
  cy.url().should('not.include', '/sign_in')
})

// Navigate to prabhag trace page
Cypress.Commands.add('visitPrabhagTrace', (prabhagId = 68) => {
  cy.visit(`/prabhags/${prabhagId}/trace`)
})

// Add point to map by clicking coordinates
Cypress.Commands.add('addMapPoint', (x, y) => {
  cy.get('#map').click(x, y)
})

// Check if image loads successfully
Cypress.Commands.add('checkImageLoaded', (selector) => {
  cy.get(selector)
    .should('be.visible')
    .and(($img) => {
      expect($img[0].naturalWidth).to.be.greaterThan(0)
    })
})