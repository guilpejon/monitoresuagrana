import { Controller } from "@hotwired/stimulus"

const DESKTOP_BREAKPOINT = 1024

export default class extends Controller {
  static targets = ["panel", "overlay", "label", "userInfo", "userLink", "content"]

  connect() {
    const collapsed = localStorage.getItem("sidebar-collapsed") === "true"
    if (collapsed) this._applyCollapsed(true, false)
  }

  // Single toggle: collapses on desktop, shows overlay on mobile
  toggle() {
    if (window.innerWidth >= DESKTOP_BREAKPOINT) {
      this.collapseToggle()
    } else {
      this._mobileToggle()
    }
  }

  close() {
    const panel = this.panelTarget
    const overlay = this.overlayTarget

    panel.classList.add("hidden")
    panel.classList.remove("flex", "fixed", "inset-y-0", "left-0", "z-50", "flex-col")
    panel.style.width = ""
    overlay.classList.add("hidden")
    if (this.hasContentTarget) this.contentTarget.style.marginLeft = ""
  }

  collapseToggle() {
    const collapsed = localStorage.getItem("sidebar-collapsed") === "true"
    const next = !collapsed
    localStorage.setItem("sidebar-collapsed", String(next))
    this._applyCollapsed(next, true)
  }

  _mobileToggle() {
    const panel = this.panelTarget
    const overlay = this.overlayTarget

    if (panel.classList.contains("hidden")) {
      panel.classList.remove("hidden")
      panel.classList.add("flex", "fixed", "inset-y-0", "left-0", "z-50", "flex-col")
      panel.style.width = "240px"
      overlay.classList.remove("hidden")
    } else {
      this.close()
    }
  }

  _applyCollapsed(collapsed, animate) {
    const panel = this.panelTarget

    if (animate) {
      panel.style.transition = "width 0.2s ease"
      if (this.hasContentTarget) {
        this.contentTarget.style.transition = "margin-left 0.2s ease"
      }
    }

    if (collapsed) {
      panel.style.width = "64px"
      this.labelTargets.forEach(el => el.classList.add("lg:hidden"))
      if (this.hasUserInfoTarget) this.userInfoTarget.classList.add("lg:hidden")
      if (this.hasUserLinkTarget) this.userLinkTarget.classList.add("justify-center")
      if (this.hasContentTarget && window.innerWidth >= DESKTOP_BREAKPOINT) this.contentTarget.style.marginLeft = "64px"
    } else {
      panel.style.width = ""
      this.labelTargets.forEach(el => el.classList.remove("lg:hidden"))
      if (this.hasUserInfoTarget) this.userInfoTarget.classList.remove("lg:hidden")
      if (this.hasUserLinkTarget) this.userLinkTarget.classList.remove("justify-center")
      if (this.hasContentTarget && window.innerWidth >= DESKTOP_BREAKPOINT) this.contentTarget.style.marginLeft = ""
    }
  }
}
