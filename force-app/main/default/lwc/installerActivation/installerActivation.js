import { LightningElement, api, wire, track } from "lwc";
import submitActivationRequest from "@salesforce/apex/ADG_ContractProRegister.submitActivationRequest";
import doesContactExist from "@salesforce/apex/ADG_ContractProRegister.doesContactExist";
import getAccountList from "@salesforce/apex/ADG_ContractProRegister.getAccountList";

export default class InstallerActivation extends LightningElement {
  templateKey = "normal";
  firstName = "";
  lastName = "";
  phone = "";
  contactId = "";
  error = "";
  searchKey = "";
  selectedAccount;
  message = "An activation link was sent via txt to the number assigned.";
  // @api recordId;

  columns = [
    { label: "First Name", fieldName: "FirstName" },
    { label: "Last Name", fieldName: "LastName" },
    { label: "Phone", fieldName: "Phone", type: "phone" },
    { label: "Email", fieldName: "Email", type: "email" }
  ];

  accountColumns = [
    { label: "Entity", fieldName: "Entity__c" },
    {
      label: "Installer #",
      fieldName: "Installer__c"
    },
    { label: "Account Name", fieldName: "Name" },
    { label: "Short Name", fieldName: "Account_Short_Name__c" }
  ];

  @api isModalOpen = false;

  @api
  openModal() {
    this.isModalOpen = true;
  }

  @api
  closeModal() {
    this.searchKey = "";
    this.selectedAccount = null;
    this.isModalOpen = false;
    this.accounts = [];
    this.searchKey = "";
    this.templateKey = "normal";
    this.firstName = "";
    this.lastName = "";
    this.phone = "";
    this.contactId = "";
    this.error = "";
    this.submitButtonDisabled = true; // disable submit button
  }

  loadMoreStatus;
  @api totalNumberOfRows;

  accounts = [];

  @wire(getAccountList, { searchKey: "$searchKey" })
  wiredAccounts({ error, data }) {
    if (data) {
      this.accounts = data.map((account) => ({
        ...account,
        Installer__c:
          account.Installer__c == null
            ? account.Installer__c
            : account.Installer__c.split(":").pop()
      }));
    } else if (error) {
      this.error = error;
    }
  }

  handleSearchInput(event) {
    // Debouncing this method
    window.clearTimeout(this.delayTimeout);
    const searchKey = event.target.value;
    this.delayTimeout = setTimeout(() => {
      this.searchKey = searchKey;
    }, 300);
  }

  @track
  submitButtonDisabled = true;

  validateForm() {
    this.submitButtonDisabled = !(
      this.selectedAccount &&
      this.firstName &&
      this.lastName &&
      this.phone.length === 14
    );
  }

  getSelectedAccount(event) {
    this.selectedAccount = event.detail.selectedRows[0];
    this.validateForm();
  }

  get isNormal() {
    return this.templateKey === "normal";
  }

  get isError() {
    return this.templateKey === "error";
  }

  get isLoading() {
    return this.templateKey === "loading";
  }

  get isComplete() {
    return this.templateKey === "complete";
  }

  get hasAccounts() {
    return this.accounts.length > 0;
  }

  setFirstName(event) {
    this.firstName = event.detail.value;
    this.validateForm();
  }

  setLastName(event) {
    this.lastName = event.detail.value;
    this.validateForm();
  }

  setPhone(event) {
    const x = event.target.value
      .replace(/\D+/g, "")
      .match(/(\d{0,3})(\d{0,3})(\d{0,4})/);
    event.target.value = !x[2]
      ? x[1]
      : `(${x[1]}) ${x[2]}` + (x[3] ? `-${x[3]}` : ``);
    this.phone = event.target.value;
    this.validateForm();
  }

  async contactExists() {
    try {
      let contact = await doesContactExist({ phone: this.phone });
      if (contact === true) {
        this.templateKey = "error";
      }
    } catch (error) {
      this.error =
        "A contact with this phone number already exists. Try again with a a different number or go to the existing contact page and send a new activation link.";
      throw error;
    }
  }

  async activationRequest() {
    try {
      let activation = await submitActivationRequest({
        activateReq: {
          account_id: this.selectedAccount["Id"],
          first_name: this.firstName,
          last_name: this.lastName,
          phone: this.phone
        }
      });
      this.isSuccess = activation.success;
    } catch (error) {
      this.error = "Failed to submit activation request. Please try again.";
      throw error;
    }
  }

  validateFields() {
    return [...this.template.querySelectorAll("lightning-input")].reduce(
      (validSoFar, field) => {
        return validSoFar && field.reportValidity();
      },
      true
    );
  }

  async submit() {
    if (this.validateFields()) {
      this.templateKey = "loading";
      try {
        await this.contactExists();
        await this.activationRequest();
        this.templateKey = "complete";
      } catch (e) {
        this.templateKey = "error";
      }
    }
  }
}