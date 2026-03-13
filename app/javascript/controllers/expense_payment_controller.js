import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "creditCardField",
    "bankAccountField",
    "installmentsField",
    "installments",
    "amount",
    "perInstallmentDisplay",
    "recurringField",
    "recurring",
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
      const isVariable = this.hasExpenseTypeTarget && this.expenseTypeTarget.value === "variable"
      this.recurringFieldTarget.style.display = (isVariable || (showInstallments && installments > 1)) ? "none" : ""
      if (isVariable && this.hasRecurringTarget) {
        this.recurringTarget.checked = false
      }
    }
  }

  typeChanged() {
    this.updateVisibility()
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
      const showInstallments = ["credit_card", "boleto", "debito_automatico", "pix_automatico", "pix"].includes(method)
      this.installmentsFieldTarget.style.display = showInstallments ? "" : "none"
    }
  }

  installmentsChanged() {
    this.updatePerInstallment()
    if (this.hasRecurringFieldTarget) {
      const installments = parseInt(this.installmentsTarget.value) || 1
      const method = this.selectedMethod()
      const showInstallments = ["credit_card", "boleto", "debito_automatico", "pix_automatico", "pix"].includes(method)
      this.recurringFieldTarget.style.display = (showInstallments && installments > 1) ? "none" : ""
    }
  }

  selectedMethod() {
    const radios = this.element.querySelectorAll("input[name*='payment_method']")
    for (const radio of radios) {
      if (radio.checked) return radio.value
    }
    return "credit_card"
  }
}
