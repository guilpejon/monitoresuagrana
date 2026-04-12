import { Controller } from "@hotwired/stimulus"
import flatpickr from "flatpickr"
import monthSelectPlugin from "flatpickr/dist/plugins/monthSelect/index.js"
import { Portuguese } from "flatpickr/dist/l10n/pt.js"
import { Spanish } from "flatpickr/dist/l10n/es.js"

function localeFor(code) {
  if (code === "pt-BR" || code === "pt") return Portuguese
  if (code === "es") return Spanish
  return undefined
}

// Month jump in topbar: same Flatpickr + monthSelect plugin as themed pickers elsewhere.
export default class extends Controller {
  static targets = ["dialog", "input"]
  static values = {
    min: String,
    max: String,
    path: String,
    current: String,
    locale: { type: String, default: "en" }
  }

  connect() {
    this.picker = null
    this._onDialogClose = () => this._destroyPicker()
    this.dialogTarget.addEventListener("close", this._onDialogClose)
    this._beforeCache = () => this._destroyPicker()
    document.addEventListener("turbo:before-cache", this._beforeCache)
  }

  disconnect() {
    this.dialogTarget.removeEventListener("close", this._onDialogClose)
    document.removeEventListener("turbo:before-cache", this._beforeCache)
    this._destroyPicker()
  }

  open(event) {
    event.preventDefault()
    this._destroyPicker()
    this.dialogTarget.showModal()

    const minDate = this._monthStart(this.minValue)
    const maxDate = this._monthEnd(this.maxValue)
    const loc = localeFor(this.localeValue)

    // Inline mode: calendar mounts in the flow under the input (no floating
    // position math). Popover + appendTo inside <dialog> was anchoring far
    // off and clipping, which also triggered scrollbars on the dialog.
    this.picker = flatpickr(this.inputTarget, {
      inline: true,
      disableMobile: true,
      dateFormat: "Y-m",
      defaultDate: this.currentValue,
      minDate,
      maxDate,
      locale: loc,
      plugins: [
        monthSelectPlugin({
          shorthand: true,
          dateFormat: "Y-m",
          theme: "dark"
        })
      ],
      clickOpens: false,
      closeOnSelect: true
    })
  }

  cancel() {
    this._destroyPicker()
    this.dialogTarget.close()
  }

  apply(event) {
    event.preventDefault()
    const month = this.inputTarget.value
    if (!month) return
    this._destroyPicker()
    const url = `${this.pathValue}?month=${encodeURIComponent(month)}`
    window.location.assign(url)
  }

  _destroyPicker() {
    if (this.picker) {
      this.picker.destroy()
      this.picker = null
    }
  }

  _monthStart(ym) {
    const [y, m] = ym.split("-").map(Number)
    return new Date(y, m - 1, 1)
  }

  _monthEnd(ym) {
    const [y, m] = ym.split("-").map(Number)
    return new Date(y, m, 0)
  }
}
