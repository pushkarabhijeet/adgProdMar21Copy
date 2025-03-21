import { LightningElement, api, track } from "lwc";

export default class InstallerPanel extends LightningElement {
  openModal() {
    this.template.querySelector("c-installer-activation").openModal();
  }
}