import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["usb", "rtsp"];

  connect() {
    this.toggle("usb");
  }

  changeType(event) {
    this.toggle(event.target.value);
  }

  toggle(type) {
    if (type === "usb") {
      this.usbTarget.classList.remove("hidden");
      this.rtspTarget.classList.add("hidden");
    } else {
      this.usbTarget.classList.add("hidden");
      this.rtspTarget.classList.remove("hidden");
    }
  }
}
