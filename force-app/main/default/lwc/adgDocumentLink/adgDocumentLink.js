import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue, getRecordNotifyChange, updateRecord } from 'lightning/uiRecordApi';
import { CurrentPageReference } from 'lightning/navigation';
import refreshDocumentsLink from "@salesforce/apex/ADG_JobPathUtils.refreshDocumentsLink";
import ASSET_ID from '@salesforce/schema/Asset.Asset_Id_18__c';
import JOB_PATH from '@salesforce/schema/Asset.ADG_JobPath__c';
import ENTITY_PATH from '@salesforce/schema/Asset.ADG_EntityPath__c';
const FIELDS = [ASSET_ID, JOB_PATH, ENTITY_PATH];

export default class DocLinkHeader extends LightningElement {

    @api recordId;

    assetId;
    jobPath;
    entityPath;
    connectedRefresh = false;
    isRefreshing = false;

    @wire(getRecord, {recordId: '$recordId', fields: FIELDS})
    wiredAsset({ error, data }) {
        if (!error && data) {
            this.assetId = getFieldValue(data, ASSET_ID);
            this.jobPath = getFieldValue(data, JOB_PATH);
            this.entityPath = getFieldValue(data, ENTITY_PATH);
        } else {
            this.assetId = null;
            this.jobPath = null;
            this.entityPath = null;
        }
    }

    @wire(CurrentPageReference)
    wiredPageRef() {
        if (this.connectedRefresh) {
            this.refresh();
        }
    }
    
    get isLoading() {
        return this.assetId === null;
    }

    get hasDocumentsLink() {
        return Boolean(this.entityPath || this.jobPath);
    }

    get documentsLink() {
        return (
            "https://ricochet.adgus.net/redirect/?"
            + "jobsite_id="
            + this.assetId
            + "&url=nextcloud%3A//open-file/%3Fuser%3D"
            + 'not-used'
            + "%26path%3D"
            + this.jobPath
            + "/."
            + "%26link%3Dhttps%3A//cloud.adgus.net%26entity_path="
            + this.entityPath
        );
    }

    async refresh() {
        this.isRefreshing = true;
        try {
            let result = await refreshDocumentsLink({ assetId: this.recordId });
            this.entityPath = result.entityPath;
            this.jobPath = result.jobPath;
            if (result.isAssetUpdated) {
                getRecordNotifyChange([{recordId: this.recordId}]);
            }
        } catch (error) {
            // TODO: display error or extra info about failed link
            console.log(error);
        }
        finally {
            this.isRefreshing = false;
        }
    }

    connectedCallback() {
        this.refresh();
        this.connectedRefresh = true;
    }
}