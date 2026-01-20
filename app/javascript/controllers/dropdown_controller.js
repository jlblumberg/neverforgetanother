import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "button"]

  connect() {
    this.close()
  }

  toggle(event) {
    event.stopPropagation()
    if (this.menuTarget.classList.contains("hidden")) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    this.menuTarget.classList.remove("hidden")
    // Close when clicking outside
    document.addEventListener("click", this.closeOnOutsideClick.bind(this))
  }

  close() {
    this.menuTarget.classList.add("hidden")
    document.removeEventListener("click", this.closeOnOutsideClick.bind(this))
  }

  closeOnOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  closeOnItemClick() {
    this.close()
  }

  disconnect() {
    document.removeEventListener("click", this.closeOnOutsideClick.bind(this))
  }
}

