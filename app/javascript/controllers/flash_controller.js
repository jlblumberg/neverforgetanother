import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["message"]
  static values = { autoDismiss: Number }

  connect() {
    if (this.autoDismissValue > 0) {
      this.timeout = setTimeout(() => {
        this.dismiss()
      }, this.autoDismissValue)
    }
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  dismiss() {
    this.messageTargets.forEach(message => {
      message.style.transition = "opacity 0.3s ease-out, transform 0.3s ease-out"
      message.style.opacity = "0"
      message.style.transform = "translateX(100%)"
      
      setTimeout(() => {
        message.remove()
        // Remove the container if no messages remain
        if (this.element.children.length === 0) {
          this.element.remove()
        }
      }, 300)
    })
  }
}


