/**
 * Created by MacBookPro on 6/12/20.
 */
import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';
//import doCustomQcFileName from '@salesforce/apex/SG_ContentDocumentHelper.doCustomQcFileName';
import { getRecord } from 'lightning/uiRecordApi';
//import setHiddenPictureFieldForQC from '@salesforce/apex/SG_ContentDocumentHelper.setHiddenPictureFieldForQC';
const FIELDS = [
    'Quality_Control__c.Name',
    'Quality_Control__c.Id',
    'Quality_Control__c.RecordTypeId',
    'Quality_Control__c.Work_Order__c',
    'Quality_Control__c.Status__c',
    'Quality_Control__c.Has_Case__c',
    'Quality_Control__c.House_Unit__c',
    'Quality_Control__c.House_Name__c',
    'Quality_Control__c.AccountId__c',
    'Quality_Control__c.House_Unit__r.Name',
    'Quality_Control__c.House_Unit__r.Floor_plan_matches_actual_site__c',
];
export default class QcPrewalk extends LightningElement {
    @api recordId;
    @api objectApiName;
    @track isRenameSuccess;
    @track error;
    @track spinner = false;
    @track selectedType;
    @track hasCase;
    @track showCaseCreation;
    showmoreq = false;
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS }) qc;
    handleLoad(event) {
        if (!this.initDone) {
            this.selectedType = event.detail.records[this.recordId].fields.Status__c.value;
            this.hasCase = event.detail.records[this.recordId].fields.Has_Case__c.value;
            this.showCaseCreation = this.isTypePendingFinish == true && this.hasCase == false;
            this.initDone = true;
            this.houseName = this.qc.data.fields.House_Name__c.value;
            this.accountId = this.qc.data.fields.AccountId__c.value;
            this.houseId = this.qc.data.fields.House_Unit__c.value;
            this.woId = this.qc.data.fields.Work_Order__c.value;
            this.showmoreq = (this.qc.data.fields.Floor_plan_matches_actual_site__c.value === "No") ? true : false;
        }
    }
    get isTypePendingFinish() {
        return this.selectedType === 'QC Complete/Pending Finish';
    }

    getHasCase() {
        return this.hasCase == true;
    }

    getShowCaseCreation() {
        return this.isTypePendingFinish == true && this.hasCase == false;
    }

    handleTypeChange(event) {
        this.selectedType = event.target.value;
        this.showCaseCreation = this.isTypePendingFinish == true && this.hasCase == false;
    }

    rendermoreq(event) {
        this.showmoreq = (event.target.value === "No") ? true : false;
        /*
        if (event.target.value === "No")
            this.showmoreq = true;
        else
            this.showmoreq = false;
            */
    }

    // QC Handlers
    handleSubmit(event) {
        console.log('onsubmit event recordEditForm' + event.detail.fields);
        this.spinner = true;
        //firing an child method
        //this.template.querySelector("c-child-web-component").submit();
        var allchildcmp = this.template.querySelectorAll("c-submit-qc-case");
        allchildcmp.forEach(function (element) {
            element.submitClick();
        }, this);
    }

    get name() {
        return this.qc.data.fields.Name.value;
    }

    changeHandler(event) {
        console.log('---> changeHandler');
        // const maths = new MathsClass();
        //      let product = maths.multiply(5, 10);
        //this.greeting = product;
    }

    handleSuccess(event) {
        console.log('---> success');
        const showSuccess = new ShowToastEvent({
            title: 'Success',
            message: 'Record Saved',
            variant: 'Success',
        });
        this.dispatchEvent(showSuccess);
        this.spinner = false;
    }
    handleError() {
        console.log('---> error during save');
        const showError = new ShowToastEvent({
            title: 'Error',
            message: 'Errors found during save',
            variant: 'error',
        });
        this.dispatchEvent(showError);
        this.spinner = false;
    }

}