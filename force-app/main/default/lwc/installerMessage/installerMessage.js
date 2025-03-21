import { LightningElement, api, wire, track } from "lwc";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import { nanoid } from "./nanoid.js";
import USER_ID from "@salesforce/user/Id";
import USER_NAME_FIELD from "@salesforce/schema/User.Name";
import WORKORDER_STATUS from "@salesforce/schema/WorkOrder.Work_Order_Status__c";
import getMessages from "@salesforce/apex/ADG_InstallerMessage.getMessages";
import submitMessage from "@salesforce/apex/ADG_InstallerMessage.submitMessage";
import hasInstallerAccount from "@salesforce/apex/ADG_InstallerMessage.hasInstallerAccount";

// COMPLETE: Display warning message when failed to connect to message server.
// COMPLETE: Display loading dots on init.
// COMPLETE: Notifications.
// TODO: Any extra error handling.
// TODO: Tap to retry on failed messages.
// TODO: Mark messages as delivered / read?
// TODO: Timestamp - timezones - local time.
// TODO: Gradients on other bubbles to match style?
// COMPLETE: If no related installer / account then show a message.

export default class InstallerMessage extends LightningElement {
  outgoingMessage = "";
  @track messages = [];
  @track localMessages = [];
  error = "";
  isAtBottom;
  missingInstallerMessage =
    "No installer is currently assigned to this WorkOrder.";
  isLoading = false;
  needsScroll = false;
  emptyMessages = true;
  syncFailureCount = 0;
  syncFailureMax = 4; // how many times in a row syncing can fail before showing the alert
  connectionMessage =
    "Unable to reach messaging server. Attempting to reconnect.";
  syncTime = 5000; // How often to poll the messaging server for updates.
  @api recordId;
  isDisabledForStatus = false;
  isDisabledForMissingAccount = false;
  userName;
  @wire(getRecord, {
    recordId: USER_ID,
    fields: [USER_NAME_FIELD]
  })
  wiredUser({ error, data }) {
    if (!error && data) {
      this.userName = data.fields.Name.value;
    } else {
      this.userName = "<unknown>";
    }
  }
  @wire(getRecord, {
    recordId: "$recordId",
    fields: [WORKORDER_STATUS]
  })
  wiredStatus({ error, data }) {
    if (!error && data) {
      let status = getFieldValue(data, WORKORDER_STATUS);
      this.isDisabledForStatus = status && /^completed/i.test(status);
    } else {
      this.isDisabledForStatus = true;
    }
  }

  // https://developer.salesforce.com/docs/component-library/documentation/en/lwc/reference_decorators

  inputUpdate(event) {
    this.outgoingMessage = event.target.value;
  }

  keyEvent(component, event, helper) {
    // On return / enter.
    if (component.which == 13) {
      this.submitCurrentMessage();
    }
  }

  get inputFieldHint() {
    if (this.isDisabledForStatus)
      return "Work order is complete, messaging is disabled.";
    else if (this.isDisabledForMissingAccount)
      return "Installer does not have Contract Pro messaging enabled.";
    return "Type a new message";
  }

  get isMessagingDisabled() {
    return this.isDisabledForStatus || this.isDisabledForMissingAccount;
  }

  clearInputField() {
    const inputField = this.template.querySelector(
      'lightning-input[data-id="message"]'
    );
    inputField.value = null;
  }

  submitCurrentMessage() {
    if (!this.outgoingMessage) return;
    this.clearInputField();
    let localMessage = {
      sender_message_id: nanoid(),
      message_text: this.outgoingMessage,
      display_name: this.userName,
      sent_by_id: USER_ID,
      is_owner: true,
      server_timestamp: this.formatDateTime(new Date()), // TODO, this is not the server timestamp
      has_error: false
    };
    this.needsScroll = true;
    this.localMessages.push(localMessage);
    this.dispatchLocalMessage(localMessage);
    this.outgoingMessage = "";
  }

  async dispatchLocalMessage(localMessage) {
    try {
      let result = await submitMessage({
        workOrderId: this.recordId,
        senderMessageId: localMessage.sender_message_id,
        message: localMessage.message_text
      });

      let localIndex = this.localMessages.findIndex(
        (m) => m.sender_message_id === localMessage.sender_message_id
      );

      if (!result.success) {
        this.localMessages[localIndex].has_error = true;
        this.localMessages[localIndex].error = result.error;
        return;
      }

      this.needsScroll = this.isAtBottom;
      this.localMessages.splice(localIndex, 1);
      this.formatMessages(result.messages);
    } catch (error) {
      let localIndex = this.localMessages.findIndex(
        (m) => m.sender_message_id === localMessage.sender_message_id
      );
      this.localMessages[localIndex].has_error = true;
      this.localMessages[localIndex].error = "Failed to send message.";
      this.error = error;
      console.log(error);
    }
  }

  formatDateTime(input) {
    let datetime = new Date(input);
    const dateFormat = {
      weekday: "short",
      year: "numeric",
      month: "short",
      day: "numeric",
      hour: "numeric",
      minute: "numeric"
      /* timeZone: 'UTC' */
    };
    return datetime.toLocaleDateString("en-US", dateFormat);
  }

  formatMessages(messages) {
    messages.forEach((m) => {
      m.server_timestamp = this.formatDateTime(m.server_timestamp);

      let listClassPrefix = "slds-chat-listitem slds-chat-listitem_";
      let listClass = (listClassPrefix += m.is_owner ? "outbound" : "inbound");
      m.bubble_list_class = listClass;

      let chatClassPrefix = "slds-chat-message__text slds-chat-message__text_";

      if (m.sender_type === 0) {
        m.bubble_chat_class = chatClassPrefix += "inbound idms-installer";
      }

      if (m.sender_type === 1 && !m.is_owner) {
        m.bubble_chat_class = chatClassPrefix += "inbound idms-fms";
      }

      if (m.sender_type === 1 && m.is_owner) {
        m.bubble_chat_class = chatClassPrefix += "outbound-agent idms-owner";
      }
    });
    this.messages = messages;
  }

  get shouldShowEmptyMessage() {
    return !this.isLoading && this.messages.length === 0;
  }

  get messageBodyHint() {
    console.log("MESSAGE BODY HINT");
    if (this.isDisabledForStatus) {
      console.log("IS DISABLED FOR STATUS");
      return "There are no messages in this conversation. The work order is complete.";
    } else if (this.shouldShowEmptyMessage) {
      console.log("SHOULD SHOW EMPTY MESSAGE");
      return "No messages yet, start the conversation below.";
    }
    return "-";
  }

  async getMessagesFromServer() {
    try {
      let result = await getMessages({ recordId: this.recordId });
      if (this.messages.length === 0) {
        this.isAtBottom = true;
      } else {
        this.emptyMessages = false;
      }
      this.formatMessages(result.messages);
      this.isLoading = false;
      if (result.success) {
        this.syncFailureCount = 0;
      } else {
        this.syncFailureCount++;
      }
    } catch (error) {
      console.log(error);
      this.syncFailureCount++;
    }
  }

  get connectionIconClass() {
    return this.syncFailureCount < this.syncFailureMax
      ? "blue-icon"
      : "offline-icon";
  }
  get showConnectionAlert() {
    return this.syncFailureCount >= this.syncFailureMax;
  }

  async checkInstallerAccount() {
    try {
      let result = await hasInstallerAccount({ workOrderId: this.recordId });
      console.log("HAS INSTALLER ACCOUNT RESULT: " + result);
      this.isDisabledForMissingAccount = !result;
    } catch (error) {
      console.log(error);
    }
  }

  connectedCallback() {
    this.isLoading = true;
    this.isDisabledForStatus = false;
    this.checkInstallerAccount();
    this.getMessagesFromServer(); // Fire immediately on init load.
    // Poll message server.
    setInterval(
      function () {
        this.getMessagesFromServer();
      }.bind(this),
      this.syncTime
    );
  }

  retrySend(event) {
    const senderMsgId = event.currentTarget.dataset.sender_message_id;
    let localIndex = this.localMessages.findIndex(
      (m) => m.sender_message_id === senderMsgId
    );
    this.dispatchLocalMessage(this.localMessages[localIndex]);
  }

  renderedCallback() {
    const chatArea = this.template.querySelector(".idms-chat-area");
    if (this.isAtBottom || this.needsScroll) {
      this.needsScroll = false;
      chatArea.scrollTop = chatArea.scrollHeight;
    }
  }
}