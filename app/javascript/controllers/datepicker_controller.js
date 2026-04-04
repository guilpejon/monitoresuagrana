import { Controller } from "@hotwired/stimulus"
import flatpickr from "flatpickr"

export default class extends Controller {
  connect() {
    this._initPicker()

    this._beforeCache = () => this.picker?.destroy()
    document.addEventListener("turbo:before-cache", this._beforeCache)

    this._onVisibilityChange = () => {
      if (document.visibilityState === "visible") {
        this._initPicker()
      }
    }
    document.addEventListener("visibilitychange", this._onVisibilityChange)
  }

  disconnect() {
    document.removeEventListener("turbo:before-cache", this._beforeCache)
    document.removeEventListener("visibilitychange", this._onVisibilityChange)
    this.picker?.destroy()
  }

  _initPicker() {
    const currentValue = this.element.value
    if (this.element._flatpickr) {
      this.element._flatpickr.destroy()
    }
    this.picker = flatpickr(this.element, {
      dateFormat: "Y-m-d",
      defaultDate: currentValue || null,
      disableMobile: true,
    })
  }
}
