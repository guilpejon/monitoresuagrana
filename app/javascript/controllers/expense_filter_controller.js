import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "row", "fixedEmpty", "variableEmpty", "clear"]

  filter() {
    const query = this.inputTarget.value.toLowerCase().trim()
    this.clearTarget.hidden = query === ""

    let fixedVisible = 0
    let variableVisible = 0

    this.rowTargets.forEach(row => {
      const visible = query === "" || row.dataset.searchText.toLowerCase().includes(query)
      row.hidden = !visible
      if (visible) {
        if (row.dataset.section === "fixed") fixedVisible++
        else variableVisible++
      }
    })

    if (this.hasFixedEmptyTarget) {
      this.fixedEmptyTarget.hidden = !(fixedVisible === 0 && query !== "")
    }
    if (this.hasVariableEmptyTarget) {
      this.variableEmptyTarget.hidden = !(variableVisible === 0 && query !== "")
    }
  }

  clear() {
    this.inputTarget.value = ""
    this.filter()
    this.inputTarget.focus()
  }
}
