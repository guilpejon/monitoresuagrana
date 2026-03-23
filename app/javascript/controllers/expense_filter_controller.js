import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "row", "fixedEmpty", "variableEmpty", "installmentEmpty", "creditCardInstallmentEmpty", "clear",
                    "grandTotal", "fixedTotal", "variableTotal", "installmentTotal", "regularTotal", "creditCardInstallmentTotal"]

  filter() {
    const query = this.inputTarget.value.toLowerCase().trim()
    this.clearTarget.hidden = query === ""

    let fixedVisible = 0
    let variableVisible = 0
    let installmentVisible = 0
    let creditCardInstallmentVisible = 0
    let fixedSum = 0
    let variableSum = 0
    let installmentSum = 0
    let regularSum = 0
    let creditCardInstallmentSum = 0

    this.rowTargets.forEach(row => {
      const visible = query === "" || row.dataset.searchText.toLowerCase().includes(query)
      row.hidden = !visible
      if (visible) {
        const amount = parseFloat(row.dataset.amount) || 0
        if (row.dataset.section === "fixed") {
          fixedVisible++
          fixedSum += amount
        } else if (row.dataset.section === "installment") {
          installmentVisible++
          installmentSum += amount
          variableSum += amount
        } else if (row.dataset.section === "credit_card_installment") {
          creditCardInstallmentVisible++
          creditCardInstallmentSum += amount
          variableSum += amount
        } else {
          variableVisible++
          regularSum += amount
          variableSum += amount
        }
      }
    })

    if (this.hasFixedEmptyTarget) {
      this.fixedEmptyTarget.hidden = !(fixedVisible === 0 && query !== "")
    }
    if (this.hasVariableEmptyTarget) {
      this.variableEmptyTarget.hidden = !(variableVisible === 0 && query !== "")
    }
    if (this.hasInstallmentEmptyTarget) {
      this.installmentEmptyTarget.hidden = !(installmentVisible === 0 && query !== "")
    }
    if (this.hasCreditCardInstallmentEmptyTarget) {
      this.creditCardInstallmentEmptyTarget.hidden = !(creditCardInstallmentVisible === 0 && query !== "")
    }

    if (this.hasGrandTotalTarget) {
      this.grandTotalTarget.innerHTML = `<span class="sensitive-value">${this.formatCurrency(fixedSum + variableSum)}</span>`
    }
    if (this.hasFixedTotalTarget) {
      this.fixedTotalTarget.innerHTML = `<span class="sensitive-value">${this.formatCurrency(fixedSum)}</span>`
    }
    if (this.hasVariableTotalTarget) {
      this.variableTotalTarget.innerHTML = `<span class="sensitive-value">${this.formatCurrency(variableSum)}</span>`
    }
    if (this.hasInstallmentTotalTarget) {
      this.installmentTotalTarget.innerHTML = `<span class="sensitive-value">${this.formatCurrency(installmentSum)}</span>`
    }
    if (this.hasRegularTotalTarget) {
      this.regularTotalTarget.innerHTML = `<span class="sensitive-value">${this.formatCurrency(regularSum)}</span>`
    }
    if (this.hasCreditCardInstallmentTotalTarget) {
      this.creditCardInstallmentTotalTarget.innerHTML = `<span class="sensitive-value">${this.formatCurrency(creditCardInstallmentSum)}</span>`
    }
  }

  clear() {
    this.inputTarget.value = ""
    this.filter()
    this.inputTarget.focus()
  }

  formatCurrency(amount) {
    const currency = this.element.dataset.currency || "BRL"
    const num = Math.abs(amount)
    const sign = amount < 0 ? "-" : ""
    const [intPart, decPart] = num.toFixed(2).split(".")

    if (currency === "USD") {
      const formatted = intPart.replace(/\B(?=(\d{3})+(?!\d))/g, ",")
      return `${sign}$${formatted}.${decPart}`
    } else if (currency === "EUR") {
      const formatted = intPart.replace(/\B(?=(\d{3})+(?!\d))/g, ".")
      return `${sign}${formatted},${decPart} €`
    } else {
      const formatted = intPart.replace(/\B(?=(\d{3})+(?!\d))/g, ".")
      return `${sign}R$ ${formatted},${decPart}`
    }
  }
}
