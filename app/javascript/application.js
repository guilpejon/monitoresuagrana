import "@hotwired/turbo-rails"
import "controllers"

if ("serviceWorker" in navigator) {
  navigator.serviceWorker.register("/service-worker", { scope: "/" });
}

import Chartkick from "chartkick"
// window.Chart is the UMD exports object; .Chart is the actual Chart class
Chartkick.use(window.Chart.Chart)

const ChartJS = window.Chart.Chart
const LOCALE_MAP = { BRL: 'pt-BR', USD: 'en-US', EUR: 'de-DE' }

function getCurrency() {
  return document.querySelector('meta[name="user-currency"]')?.content || 'BRL'
}

function isPrivacyOn() {
  return document.documentElement.classList.contains('values-hidden')
}

// Format currency values in tooltips
ChartJS.register({
  id: 'currencyTooltip',
  afterInit(chart) {
    const currency = getCurrency()
    const formatter = new Intl.NumberFormat(LOCALE_MAP[currency] || 'pt-BR', { style: 'currency', currency })
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

// Format axis ticks as currency for charts inside a [data-currency-axis] element
ChartJS.register({
  id: 'currencyTicks',
  afterInit(chart) {
    const wrapper = chart.canvas?.closest('[data-currency-axis]')
    if (!wrapper) return
    const axisId = wrapper.dataset.currencyAxis
    const scale = chart.options.scales?.[axisId]
    if (!scale) return
    if (!scale.ticks) scale.ticks = {}
    const currency = getCurrency()
    const formatter = new Intl.NumberFormat(LOCALE_MAP[currency] || 'pt-BR', { style: 'currency', currency, maximumFractionDigits: 0 })
    scale.ticks.callback = (value) => {
      if (isPrivacyOn()) return ''
      return formatter.format(value)
    }
  }
})

// Hide chart values (ticks + tooltips) when privacy mode is on
ChartJS.register({
  id: 'privacyMode',
  beforeInit(chart) {
    if (!chart.options.plugins) chart.options.plugins = {}
    if (!chart.options.plugins.tooltip) chart.options.plugins.tooltip = {}
    Object.values(chart.options.scales || {}).forEach(scale => {
      if (!scale.ticks) scale.ticks = {}
      const orig = scale.ticks.callback
      scale.ticks.callback = function(value, index, ticks) {
        if (isPrivacyOn()) return ''
        return orig ? orig.call(this, value, index, ticks) : value
      }
    })
  }
})
