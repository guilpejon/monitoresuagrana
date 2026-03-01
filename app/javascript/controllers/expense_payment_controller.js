import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "creditCardField",
    "installmentsField",
    "installments",
    "amount",
    "perInstallmentDisplay",
    "recurringField",
    "recurring"
  ]

  connect() {
    this.updateVisibility()
    this.updatePerInstallment()
  }

  methodChanged() {
    this.updateVisibility()
    this.updatePerInstallment()
  }

  updatePerInstallment() {
    if (!this.hasPerInstallmentDisplayTarget) return

    const amount = parseFloat(this.amountTarget.value) || 0
    const installments = parseInt(this.installmentsTarget.value) || 1
    const per = installments > 0 ? (amount / installments).toFixed(2) : amount.toFixed(2)
    this.perInstallmentDisplayTarget.textContent = `R$ ${per.replace(".", ",")}`
  }

  updateVisibility() {
    const method = this.selectedMethod()
    const showCreditCard = method === "credit_card"
    const showInstallments = method === "credit_card" || method === "boleto"

    if (this.hasCreditCardFieldTarget) {
      this.creditCardFieldTarget.style.display = showCreditCard ? "" : "none"
    }

    if (this.hasInstallmentsFieldTarget) {
      const isRecurring = this.hasRecurringTarget && this.recurringTarget.checked
      const show = showInstallments && !isRecurring
      this.installmentsFieldTarget.style.display = show ? "" : "none"
      if (!show) {
        this.installmentsTarget.value = 1
        this.updatePerInstallment()
      }
    }

    if (this.hasRecurringFieldTarget) {
      const installments = this.hasInstallmentsTarget ? (parseInt(this.installmentsTarget.value) || 1) : 1
      this.recurringFieldTarget.style.display = (showInstallments && installments > 1) ? "none" : ""
    }
  }

  recurringChanged() {
    if (!this.hasInstallmentsFieldTarget) return
    const isRecurring = this.recurringTarget.checked
    if (isRecurring) {
      this.installmentsFieldTarget.style.display = "none"
      this.installmentsTarget.value = 1
      this.updatePerInstallment()
    } else {
      const method = this.selectedMethod()
      const showInstallments = method === "credit_card" || method === "boleto"
      this.installmentsFieldTarget.style.display = showInstallments ? "" : "none"
    }
  }

  installmentsChanged() {
    this.updatePerInstallment()
    if (this.hasRecurringFieldTarget) {
      const installments = parseInt(this.installmentsTarget.value) || 1
      const method = this.selectedMethod()
      const showInstallments = method === "credit_card" || method === "boleto"
      this.recurringFieldTarget.style.display = (showInstallments && installments > 1) ? "none" : ""
    }
  }

  selectedMethod() {
    const radios = this.element.querySelectorAll("input[name*='payment_method']")
    for (const radio of radios) {
      if (radio.checked) return radio.value
    }
    return "cash"
  }
}
