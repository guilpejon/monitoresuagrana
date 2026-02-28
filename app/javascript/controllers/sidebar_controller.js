import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "overlay"]

  toggle() {
    const sidebar = this.element.querySelector("aside")
    const overlay = this.overlayTarget

    if (sidebar.classList.contains("hidden")) {
      sidebar.classList.remove("hidden")
      sidebar.classList.add("flex", "fixed", "inset-y-0", "left-0", "z-30", "w-60", "flex-col")
      overlay.classList.remove("hidden")
    } else {
      this.close()
    }
  }

  close() {
    const sidebar = this.element.querySelector("aside")
    const overlay = this.overlayTarget

    sidebar.classList.add("hidden")
    sidebar.classList.remove("flex", "fixed", "inset-y-0", "left-0", "z-30", "w-60", "flex-col")
    overlay.classList.add("hidden")
  }
}
