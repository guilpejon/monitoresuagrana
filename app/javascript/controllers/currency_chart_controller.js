import { Controller } from "@hotwired/stimulus"

// Plugin registration moved to application.js to guarantee it runs before
// Chartkick initializes any charts on page load.
export default class extends Controller {}
