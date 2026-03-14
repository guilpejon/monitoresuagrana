import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "creditCardField",
    "bankAccountField",
    "installmentsField",
    "installments",
    "amount",
    "perInstallmentDisplay",
    "expenseType"
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
    const showBankAccount = ["pix", "boleto", "debito_automatico"].includes(method)
    const showInstallments = ["credit_card", "boleto", "debito_automatico", "pix_automatico", "pix"].includes(method)

    if (this.hasCreditCardFieldTarget) {
      this.creditCardFieldTarget.style.display = showCreditCard ? "" : "none"
    }

    if (this.hasBankAccountFieldTarget) {
      this.bankAccountFieldTarget.style.display = showBankAccount ? "" : "none"
    }

    if (this.hasInstallmentsFieldTarget) {
      const isFixed = this.hasExpenseTypeTarget && this.expenseTypeTarget.value === "fixed"
      const show = showInstallments && !isFixed
      this.installmentsFieldTarget.style.display = show ? "" : "none"
      if (!show) {
        this.installmentsTarget.value = 1
        this.updatePerInstallment()
      }
    }
  }

  typeChanged() {
    this.updateVisibility()
  }

  installmentsChanged() {
    this.updatePerInstallment()
  }

  selectedMethod() {
    const radios = this.element.querySelectorAll("input[name*='payment_method']")
    for (const radio of radios) {
      if (radio.checked) return radio.value
    }
    return "credit_card"
  }
}
