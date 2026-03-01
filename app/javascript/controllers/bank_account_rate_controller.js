import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["fixedFields", "cdiFields", "rateTypeSelect"]

  connect() { this.toggle() }

  toggle() {
    const isCdi = this.rateTypeSelectTarget.value === "cdi_percentage"
    this.fixedFieldsTarget.classList.toggle("hidden", isCdi)
    this.cdiFieldsTarget.classList.toggle("hidden", !isCdi)
  }
}
