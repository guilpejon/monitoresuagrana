import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "dialog"]

  connect() {
    this.boundHandleKeydown = this.handleKeydown.bind(this)
  }

  open(event) {
    event.preventDefault()
    const url = event.currentTarget.dataset.modalUrlValue ||
                event.currentTarget.getAttribute("href") ||
                event.params?.url

    if (url) {
      fetch(url, {
        headers: { "Accept": "text/html", "X-Requested-With": "XMLHttpRequest" }
      })
      .then(r => r.text())
      .then(html => {
        document.getElementById("modal-content").innerHTML = html
        this.show()
      })
    }
  }

  show() {
    this.element.classList.remove("hidden")
    document.addEventListener("keydown", this.boundHandleKeydown)
    document.body.style.overflow = "hidden"
  }

  close(event) {
    if (event) {
      // Only close if clicking the backdrop itself
      if (event.target !== this.element) return
    }
    this.hide()
  }

  hide() {
    this.element.classList.add("hidden")
    document.getElementById("modal-content").innerHTML = ""
    document.removeEventListener("keydown", this.boundHandleKeydown)
    document.body.style.overflow = ""
  }

  handleKeydown(event) {
    if (event.key === "Escape") this.hide()
  }
}
