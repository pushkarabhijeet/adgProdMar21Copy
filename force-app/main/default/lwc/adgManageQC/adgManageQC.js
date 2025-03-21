import { LightningElement, wire } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import COMMUNITY_OBJ from '@salesforce/schema/Community__c';
import ENTITY_FIELD from '@salesforce/schema/Community__c.Entity__c';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import submitBatch from '@salesforce/apex/ADG_ManageQC.submitBatch';

const fields = [
    { label: 'QC Build Sheet', value: 'QC_Build_Sheet__c' },
    { label: 'QC Carpet Install', value: 'QC_Carpet_Install__c' },
    { label: 'QC Countertops Install', value: 'QC_Countertops_Install__c' },
    { label: 'QC Fine Tune Checklist', value: 'QC_Fine_Tune_Checklist__c' },
    { label: 'QC Floor Wall Tile Install', value: 'QC_Floor_Wall_Tile_Install__c' },
    { label: 'QC LVT Install', value: 'QC_LVT_Install__c' },
    { label: 'QC Product Inspection', value: 'QC_Product_Inspection__c' },
    { label: 'QC Tile Backsplash Install', value: 'QC_Tile_Backsplash_Install__c' },
    { label: 'QC Vinyl Install', value: 'QC_Vinyl_Install__c' },
    { label: 'QC Wood Install', value: 'QC_Wood_Install__c' }
];

const today = new Date();

export default class AdgManageQC extends LightningElement {
    @wire(getObjectInfo, { objectApiName: COMMUNITY_OBJ })
    objectInfo;

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: ENTITY_FIELD })
    TypePicklistValues;

    fields = fields;

    entitySelected; qcField; qcLabel; processPath; error;
    datestr = today.toISOString();

    validateFields() {
        this.template.querySelectorAll('lightning-combobox').forEach(element => {
            element.reportValidity();
        })
    }

    showToast() {
        const event = new ShowToastEvent({
            title: 'Success',
            message: 'Opearion sucessful',
            variant: 'success',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }

    handleChange(event) {
        if (event.target.name === 'entity') {
            this.entitySelected = event.target.value;
        }
        else if (event.target.name === 'qcField') {
            this.qcField = event.target.value;
            this.qcLabel = event.target.options.find(opt => opt.value === event.detail.value).label;
        }
        else if (event.target.name === 'dateInput') {
            console.log(event.target.value);
            this.datestr = event.target.value;
        }
    }

    resetForm() {
        this.entitySelected = undefined;
        this.qcField = undefined;
        this.qcLabel = undefined;
        this.datestr = undefined;
    }

    processAction(event) {
        let buttonClickd = event.target.name;
        console.log(this.processPath);
        this.validateFields();
        if (this.entitySelected != undefined && this.qcField != undefined) {
            console.log(this.datestr);
            this.submitRequest(buttonClickd);
            this.resetForm();
        }
    }

    submitRequest(buttonClickd) {
        submitBatch({
            strEntity: this.entitySelected,
            strFieldName: this.qcField,
            strFieldLabel: this.qcLabel,
            strButtonClk: buttonClickd,
            qcCreatedDate: this.datestr
        })
            .then((result) => {
                this.showToast();
                this.error = undefined;

            })
            .catch((error) => {
                this.error = error;
            });
    }
}