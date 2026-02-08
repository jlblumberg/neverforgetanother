import { Controller } from "@hotwired/stimulus"

// Formats US phone number as (XXX) XXX-XXXX while typing.
export default class extends Controller {
  static targets = ["input"]

  connect() {
    this.format()
  }

  format() {
    const input = this.inputTarget
    const start = input.selectionStart ?? input.value.length
    const digitsBeforeCursor = input.value.slice(0, start).replace(/\D/g, "").length
    const digits = input.value.replace(/\D/g, "").slice(0, 10)
    let formatted = ""
    if (digits.length > 0) {
      formatted = "(" + digits.slice(0, 3)
      if (digits.length > 3) {
        formatted += ") " + digits.slice(3, 6)
        if (digits.length > 6) {
          formatted += "-" + digits.slice(6)
        }
      }
    }
    input.value = formatted
    let seen = 0
    let newCursor = formatted.length
    for (let i = 0; i < formatted.length; i++) {
      if (/\d/.test(formatted[i])) seen++
      if (seen === digitsBeforeCursor) {
        newCursor = i + 1
        break
      }
    }
    input.setSelectionRange(newCursor, newCursor)
  }
}
