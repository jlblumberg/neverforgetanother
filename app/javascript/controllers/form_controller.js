import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["submit"]

  connect() {
    if (this.hasSubmitTarget) {
      this.originalSubmitText = this.submitTarget.textContent.trim()
    }
  }

  submit(event) {
    if (this.hasSubmitTarget && !this.submitTarget.disabled) {
      this.submitTarget.disabled = true
      this.submitTarget.classList.add("opacity-75", "cursor-not-allowed")
      
      // Store original HTML
      const originalHTML = this.submitTarget.innerHTML
      
      // Add loading spinner and update text
      const spinner = document.createElement("span")
      spinner.className = "inline-block animate-spin rounded-full h-4 w-4 border-2 border-current border-t-transparent mr-2 align-middle"
      this.submitTarget.innerHTML = ""
      this.submitTarget.appendChild(spinner)
      this.submitTarget.appendChild(document.createTextNode(" Saving..."))
      
      // Store for potential restore (though form will redirect on success)
      this.originalHTML = originalHTML
    }
  }
}

