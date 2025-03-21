/**
 * Created by MacBookPro on 6/12/20.
 */

import { LightningElement, api, track, wire } from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';

import { getRecord } from 'lightning/uiRecordApi';

import doCustomQcFileName from '@salesforce/apex/SG_ContentDocumentHelper.doCustomQcFileName';
import setHiddenPictureFieldForQC from '@salesforce/apex/SG_ContentDocumentHelper.setHiddenPictureFieldForQC';

const FIELDS = [
    'Quality_Control__c.Name',
    'Quality_Control__c.Id',
    'Quality_Control__c.RecordTypeId',
    'Quality_Control__c.Picture_House_and_Perimeter_Clean__c',
];

export default class RecordEditFormDynamicContact extends LightningElement {
    @api recordId;
    @api objectApiName;

    @track spinner = false;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
          qc;

       get name() {
           return this.qc.data.fields.Name.value;
       }


    /// File upload
        get acceptedFormats() {
            return ['.pdf', '.png','.jpg','.jpeg', '.gif', '.mov', '.mp4'];
        }
        handleUploadFinished_Garage(event) {
            // Get the list of uploaded files


            let hiddenPicField = 'Picture_House_and_Perimeter_Clean__c';
            let prefix = 'VinylInstall_Garage_';
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

            console.log('---> hidden pic field: ' + hiddenPicField);
            console.log('---> recordId: ' + this.qc.data.fields.Id.value );

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