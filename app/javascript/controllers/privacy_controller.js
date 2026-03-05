import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "values-hidden"

function updateCharts(hidden) {
  if (!window.Chart?.Chart) return
  Object.values(window.Chart.Chart.instances).forEach(chart => {
    chart.options.plugins.tooltip.enabled = !hidden
    chart.update("none")
  })
}

export default class extends Controller {
  static targets = ["eyeIcon", "eyeOffIcon"]

  connect() {
    const hidden = localStorage.getItem(STORAGE_KEY) === "true"
    this._apply(hidden)

    // Re-apply after Chartkick renders a chart (handles post-Turbo-navigation timing)
    this._onChartRender = () => updateCharts(localStorage.getItem(STORAGE_KEY) === "true")
    document.addEventListener("chartkick:render", this._onChartRender)
  }

  disconnect() {
    document.removeEventListener("chartkick:render", this._onChartRender)
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()
    const hidden = localStorage.getItem(STORAGE_KEY) === "true"
    const next = !hidden
    localStorage.setItem(STORAGE_KEY, String(next))
    this._apply(next)
  }

  _apply(hidden) {
    document.documentElement.classList.toggle("values-hidden", hidden)
    updateCharts(hidden)
    if (this.hasEyeIconTarget) this.eyeIconTarget.classList.toggle("hidden", hidden)
    if (this.hasEyeOffIconTarget) this.eyeOffIconTarget.classList.toggle("hidden", !hidden)
  }
}
