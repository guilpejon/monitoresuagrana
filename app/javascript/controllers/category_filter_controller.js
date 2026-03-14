import { Controller } from "@hotwired/stimulus"
import flatpickr from "flatpickr"

export default class extends Controller {
  static targets = [
    "popup",
    "calendar",
    "startInput", "endInput",
    "startDisplay", "endDisplay",
    "mobileStartInput", "mobileEndInput"
  ]
  static values = { url: String, startDate: String, endDate: String }

  connect() {
    this._boundEsc = this._onEsc.bind(this)
    this._beforeCache = () => { this.picker?.destroy(); this.picker = null }
    document.addEventListener("turbo:before-cache", this._beforeCache)
  }

  disconnect() {
    document.removeEventListener("turbo:before-cache", this._beforeCache)
    document.removeEventListener("keydown", this._boundEsc)
    this.picker?.destroy()
  }

  openPopup() {
    this.popupTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"
    document.addEventListener("keydown", this._boundEsc)

    // Desktop only: lazy-init flatpickr into a now-visible element.
    // Mobile uses native date inputs instead.
    if (!this.picker && window.innerWidth >= 640) {
      this._initCalendar()
    }
  }

  closePopup() {
    this.popupTarget.classList.add("hidden")
    document.body.style.overflow = ""
    document.removeEventListener("keydown", this._boundEsc)
  }

  closeOnBackdrop(event) {
    if (event.target === event.currentTarget) this.closePopup()
  }

  // Called on mobile when a native date input changes
  syncMobileDate() {
    if (this.hasMobileStartInputTarget) {
      this.startInputTarget.value = this.mobileStartInputTarget.value
    }
    if (this.hasMobileEndInputTarget) {
      this.endInputTarget.value = this.mobileEndInputTarget.value
    }
  }

  selectPreset(event) {
    const tf = event.currentTarget.dataset.timeframe
    const url = new URL(this.urlValue, window.location.origin)
    url.searchParams.set("timeframe", tf)
    url.searchParams.delete("start_date")
    url.searchParams.delete("end_date")
    window.location.href = url.toString()
  }

  apply() {
    const start = this.startInputTarget.value
    const end   = this.endInputTarget.value
    if (!start && !end) return

    const url = new URL(this.urlValue, window.location.origin)
    url.searchParams.set("timeframe", "custom")
    if (start) url.searchParams.set("start_date", start)
    if (end)   url.searchParams.set("end_date", end)
    window.location.href = url.toString()
  }

  _initCalendar() {
    const defaults   = [this.startDateValue, this.endDateValue].filter(Boolean)
    const showMonths = window.innerWidth >= 900 ? 2 : 1

    this.picker = flatpickr(this.calendarTarget, {
      mode: "range",
      inline: true,
      showMonths,
      dateFormat: "Y-m-d",
      defaultDate: defaults.length ? defaults : null,
      onChange: (selectedDates) => {
        const start = selectedDates[0] ? this._fmt(selectedDates[0]) : ""
        const end   = selectedDates[1] ? this._fmt(selectedDates[1]) : ""
        this.startInputTarget.value = start
        this.endInputTarget.value   = end
        if (this.hasStartDisplayTarget) this.startDisplayTarget.textContent = start || "—"
        if (this.hasEndDisplayTarget)   this.endDisplayTarget.textContent   = end   || "—"
      }
    })
  }

  _fmt(date) {
    const y = date.getFullYear()
    const m = String(date.getMonth() + 1).padStart(2, "0")
    const d = String(date.getDate()).padStart(2, "0")
    return `${y}-${m}-${d}`
  }

  _onEsc(event) {
    if (event.key === "Escape") this.closePopup()
  }
}
