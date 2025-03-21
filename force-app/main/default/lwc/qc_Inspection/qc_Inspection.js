/**
 * Created on 6/30/20.
 */

import { LightningElement, api, track, wire } from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';

import doCustomQcFileName from '@salesforce/apex/SG_ContentDocumentHelper.doCustomQcFileName';

import { getRecord } from 'lightning/uiRecordApi';
import setHiddenPictureFieldForQC from '@salesforce/apex/SG_ContentDocumentHelper.setHiddenPictureFieldForQC';

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
];

export default class QcInspection extends LightningElement {

    @api recordId;
        @api objectApiName;
        @track isRenameSuccess;
        @track error;
        @track spinner = false;
        @track selectedType;
        @track hasCase;
        @track showCaseCreation;

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
                }
            }
         get isTypePendingFinish() {
             return this.selectedType === 'QC Complete/Pending Finish';
         }

         getHasCase()
         {
            return this.hasCase == true;
         }

         getShowCaseCreation()
         {
             return this.isTypePendingFinish == true && this.hasCase == false;
         }

         handleTypeChange(event) {
             this.selectedType = event.target.value;
             this.showCaseCreation = this.isTypePendingFinish == true && this.hasCase == false;
         }

        // QC Handlers
         handleSubmit(event) {
                console.log('onsubmit event recordEditForm'+ event.detail.fields);
                this.spinner = true;
               //firing an child method
                   //this.template.querySelector("c-child-web-component").submit();
                   var allchildcmp=this.template.querySelectorAll("c-submit-qc-case");
                       allchildcmp.forEach(function(element){
                           element.submitClick();
                       },this);
          }  

        /// File upload
            get acceptedFormats() {
                return ['.pdf', '.png','.jpg','.jpeg'];
            }
            handleUploadFinished_HousePaint(event) {
                // Get the list of uploaded files

                let prefix = 'JobStart_HousePainted_';
                let hiddenPicField = 'Picture_House_Painted__c';

                const uploadedFiles = event.detail.files;
                let uploadedFileNames = '';
                let uploadedFileIds = '';
                let sep = '';

                for(let i = 0; i < uploadedFiles.length; i++) {

                    console.log('---> file Id: ' + uploadedFiles[i].documentId );
                    console.log('---> file name: ' + uploadedFiles[i].name );
                    uploadedFileNames += prefix + uploadedFiles[i].name + ', ';
                    uploadedFileIds += sep + uploadedFiles[i].documentId + ', ';
                    sep = ', ';
                }
                console.log('---> uploadedFileIds: ' + uploadedFileIds );
                console.log('---> prefix: ' + prefix );

                 setHiddenPictureFieldForQC({'recordId':this.qc.data.fields.Id.value,'fieldName':hiddenPicField, 'fieldValue':uploadedFileNames})
                    .then(result => {
                        this.isRenameSuccess = result;
                        console.log('---> is succes: ' + result );
                    })
                    .catch(error => {
                        this.error = error;
                        console.log('---> is error: ' + error);
                    });

                doCustomQcFileName({'fileIds':uploadedFileIds,'prefix':prefix})
                    .then(result => {
                        this.isRenameSuccess = result;
                        console.log('---> is succes: ' + result );
                    })
                    .catch(error => {
                        this.error = error;
                        console.log('---> is error: ' + error);
                    });
                    console.log('---> after doCustomQCFileName');


                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: uploadedFiles.length + ' Files uploaded Successfully: ' + uploadedFileNames,
                        variant: 'success',
                    }),
                );
            }

         /// end File Upload

         handleSave() {
             this.spinner = true;
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