import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
//import setHiddenPictureFieldForQC from '@salesforce/apex/SG_ContentDocumentHelper.setHiddenPictureFieldForQC';
import doCustomQcFileName from '@salesforce/apex/SG_ContentDocumentHelper.doCustomQcFileName';

export default class AdgFileUploader extends LightningElement {
    //@api prefix;
    //@api hiddenPicField;
    @api recordId;;
    @api label;
    @track record;
    @track error;
    @api prefix;

    get acceptedFormats() {
        return ['.pdf', '.png', '.jpg', '.jpeg'];
    }

    /*
    @wire(getRecord, { recordId: '$recordId', fields: ['Quality_Control__c.Name'] })
    wiredQC({ error, data }) {
        if (data) {
            this.record = data;
            console.log('data.recordTypeInfo ', data.recordTypeInfo.name);
            this.prefix = data.recordTypeInfo.name + '_';
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.record = undefined;
        }
    }
    */
    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        let uploadedFileNames = '';
        let uploadedFileIds = '';
        let sep = '';
        for (let i = 0; i < uploadedFiles.length; i++) {
            uploadedFileNames += this.prefix + uploadedFiles[i].name + ', ';
            uploadedFileIds += sep + uploadedFiles[i].documentId + ', ';
            sep = ', ';
        }

        /*setHiddenPictureFieldForQC({ 'recordId': this.recordId, 'fieldName': this.hiddenPicField, 'fieldValue': uploadedFileNames })
            .then(result => {
                this.isRenameSuccess = result;
                console.log('setHiddenPictureFieldForQC---> is succes: ' + result);
            })
            .catch(error => {
                this.error = error;
                console.log('setHiddenPictureFieldForQC---> is error: ' + error);
            });
            */
        doCustomQcFileName({ 'fileIds': uploadedFileIds, 'prefix': this.prefix })
            .then(result => {
                this.isRenameSuccess = result;
                console.log('doCustomQcFileName---> is succes: ' + result);
            })
            .catch(error => {
                this.error = error;
                console.log('doCustomQcFileName---> is error: ' + error);
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
}