import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  myFunction() {
      console.log("test")
  }  
  connect() {
    console.log("Hello World!");
  }
}
