import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { splitTemplate: String }

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

  // Mirrors InstallmentSplit in app/services/installment_split.rb
  static installmentAmounts(total, count) {
    if (count <= 1) return [total]
    const per = Math.round((total / count) * 100) / 100
    const last = Math.round((total - per * (count - 1)) * 100) / 100
    return [...Array(count - 1).fill(per), last]
  }

  static formatBrl(n) {
    return `R$ ${n.toFixed(2).replace(".", ",")}`
  }

  methodChanged() {
    this.updateVisibility()
    this.updatePerInstallment()
  }

  updatePerInstallment() {
    if (!this.hasPerInstallmentDisplayTarget) return

    const amount = parseFloat(this.amountTarget.value) || 0
    const installments = parseInt(this.installmentsTarget.value) || 1

    if (installments <= 1) {
      this.perInstallmentDisplayTarget.textContent = this.constructor.formatBrl(amount)
      return
    }

    const amounts = this.constructor.installmentAmounts(amount, installments)
    const per = amounts[0]
    const last = amounts[amounts.length - 1]

    if (Math.abs(per - last) < 0.005) {
      this.perInstallmentDisplayTarget.textContent = this.constructor.formatBrl(per)
      return
    }

    const tpl = this.hasSplitTemplateValue ? this.splitTemplateValue : "__RN__× __R__ + last __L__"
    const text = tpl
      .replaceAll("__RN__", String(installments - 1))
      .replaceAll("__R__", this.constructor.formatBrl(per))
      .replaceAll("__L__", this.constructor.formatBrl(last))
    this.perInstallmentDisplayTarget.textContent = text
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
