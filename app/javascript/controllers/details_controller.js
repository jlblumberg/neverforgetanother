import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { storageKey: String }

  connect() {
    const storageKey = this.storageKeyValue || "details_open"
    const savedState = localStorage.getItem(storageKey)
    
    if (savedState === "true") {
      this.element.open = true
    } else if (savedState === "false") {
      this.element.open = false
    }
  }

  toggle() {
    const storageKey = this.storageKeyValue || "details_open"
    localStorage.setItem(storageKey, this.element.open ? "true" : "false")
  }
}

