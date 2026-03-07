import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "pwa-install-dismissed"
const THIRTY_DAYS_MS = 30 * 24 * 60 * 60 * 1000

export default class extends Controller {
  static targets = ["banner", "iosContent", "androidContent", "androidStaticContent"]
  static values = { mode: { type: String, default: "banner" } }

  connect() {
    // Already running as installed PWA — nothing to do
    if (window.matchMedia("(display-mode: standalone)").matches) {
      this.element.remove()
      return
    }

    const isIos = /iphone|ipad|ipod/i.test(navigator.userAgent)
    const isAndroid = /android/i.test(navigator.userAgent)

    if (!isIos && !isAndroid) {
      this.element.remove()
      return
    }

    const isBanner = this.modeValue === "banner"

    if (isBanner) {
      const dismissed = localStorage.getItem(STORAGE_KEY)
      if (dismissed && Date.now() - parseInt(dismissed) < THIRTY_DAYS_MS) return
    }

    if (isIos) {
      this._show("ios")
    } else {
      window.addEventListener("beforeinstallprompt", (e) => {
        e.preventDefault()
        this._deferredPrompt = e
        this._show("android")
      }, { once: true })

      // On settings card, show static Android instructions if the install prompt
      // never fires (app already installed, browser criteria not met, etc.)
      if (!isBanner) {
        setTimeout(() => {
          if (!this._deferredPrompt) this._show("android-static")
        }, 800)
      }
    }
  }

  _show(platform) {
    if (this.hasBannerTarget) this.bannerTarget.classList.remove("hidden")

    if (platform === "ios" && this.hasIosContentTarget) {
      this.iosContentTarget.classList.remove("hidden")
    } else if (platform === "android" && this.hasAndroidContentTarget) {
      this.androidContentTarget.classList.remove("hidden")
    } else if (platform === "android-static" && this.hasAndroidStaticContentTarget) {
      this.androidStaticContentTarget.classList.remove("hidden")
    }
  }

  install() {
    if (!this._deferredPrompt) return
    this._deferredPrompt.prompt()
    this._deferredPrompt.userChoice.then(() => {
      this._deferredPrompt = null
      this.dismiss()
    })
  }

  dismiss() {
    localStorage.setItem(STORAGE_KEY, Date.now().toString())
    if (this.hasBannerTarget) this.bannerTarget.classList.add("hidden")
  }
}
