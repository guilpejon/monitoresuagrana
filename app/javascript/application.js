import "@hotwired/turbo-rails"
import "controllers"

if ("serviceWorker" in navigator) {
  navigator.serviceWorker.register("/service-worker", { scope: "/" });
}

import Chartkick from "chartkick"
// window.Chart is the UMD exports object; .Chart is the actual Chart class
Chartkick.use(window.Chart.Chart)

window.Chart.Chart.register({
  id: 'currencyTooltip',
  afterInit(chart) {
    const currency = document.querySelector('meta[name="user-currency"]')?.content || 'BRL'
    const localeMap = { BRL: 'pt-BR', USD: 'en-US', EUR: 'de-DE' }
    const formatter = new Intl.NumberFormat(localeMap[currency] || 'pt-BR', { style: 'currency', currency })
    chart.options.plugins.tooltip.callbacks.label = function(context) {
      const type = context.chart.config.type
      if (type === 'pie' || type === 'doughnut') {
        return ' ' + formatter.format(context.parsed)
      }
      const label = context.dataset.label || ''
      const isHorizontal = context.chart.options.indexAxis === 'y'
      return ' ' + (label ? label + ': ' : '') + formatter.format(isHorizontal ? context.parsed.x : context.parsed.y)
    }
  }
})
