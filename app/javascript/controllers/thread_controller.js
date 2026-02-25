import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["replyForm"]

  toggleReply() {
    this.replyFormTarget.classList.toggle("hidden")
  }
}
