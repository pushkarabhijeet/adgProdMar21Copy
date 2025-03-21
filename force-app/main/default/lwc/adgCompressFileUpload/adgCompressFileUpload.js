import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import uploadFile from '@salesforce/apex/FileUploaderClass.uploadFile';
import compressionlevel from '@salesforce/label/c.ImageCompression';

export default class AdgPicUploader extends LightningElement {
    @api recordId;
    @api prefix;
    @api label;
    fileData;
    successFileNames;
    errFileNames;
    errCount = 0;
    successCount = 0;
    TotalCount = 0;

    get acceptedFormats() {
        return ['.png', '.jpg', '.jpeg'];
    }

    openfileUpload(event){
        this.TotalCount = event.target.files.length;
        this.errCount = 0;
        this.successCount = 0;
        this.successFileNames = '';
        this.errFileNames = '';
        if (this.TotalCount > 10){
            this.toast('Can only upload 10 pictures at a time', 'error');
        } else {
            this.toast('Upload in progress. Confirmation will be displayed when complete', 'info');
            for (const file of event.target.files){
                //If File is more than 5 MB, 70% compression added to set compression level (.4*.7 => .28% of original pic)
                let compress = (file.size>(5*1024*1024)) ? Number(compressionlevel)*0.7 : (file.size>(7*100*1000)) ? Number(compressionlevel) : 1;
                let img = new Image();
                img.onload = () => {
                    let canvas = document.createElement('canvas');
                    canvas.width = img.width;
                    canvas.height = img.height;
                    let ctx = canvas.getContext("2d");
                    ctx.drawImage(img, 0, 0, img.width, img.height);
                    let compressedImage = canvas.toDataURL('image/jpeg', compress);
                    let base64 = compressedImage.split(',')[1];
                    this.fileData = {
                        'filename': this.prefix + file.name,
                        'base64': base64,
                        'recordId': this.recordId
                    }
                    this.upload2Srvr();
                }
                img.src = URL.createObjectURL(file);
            }
        }
    }

    upload2Srvr(){
        const {base64, filename, recordId} = this.fileData;
        uploadFile({ base64, filename, recordId }).then(() => {
            if (this.successCount <1){
                this.successFileNames =  this.prefix + filename;
            } else {
                this.successFileNames += ', ' + this.prefix + filename;
            }
            this.fileData = null;
            this.successCount++;
        })
        .catch(error => {
            console.log("error Uploading Files = " + JSON.stringify(error));
            if (this.errCount < 1) {
                this.errFileNames = filename;
            } else {
                this.errFileNames += ', ' + filename;
            }
            this.errCount++;
            this.fileData = null;
        })
        .finally(() => {
            if (this.TotalCount == (this.successCount + this.errCount)){
                this.updateRecordView();
                if (this.TotalCount == this.successCount){
                    let title = this.successFileNames + ' uploaded successfully!!';
                    this.toast(title, 'success');
                } else{
                    if (this.successCount > 0){
                        let title = this.successFileNames + ' uploaded successfully!!';
                        this.toast(title, 'success');
                    }
                    let errtitle = 'Total ' + this.errCount + ' pictures with names '  + this.errFileNames + ' could not be uploaded. Try again in sometime!!';
                    this.toast(errtitle, 'error');
                }
            }
        });
    }

    toast(title, variant){
        const toastEvent = new ShowToastEvent({
            title: title, 
            variant: variant,
            mode: "dismissable"
        })
        this.dispatchEvent(toastEvent)
    }

    updateRecordView() {
        setTimeout(() => {
            eval("$A.get('e.force:refreshView').fire();");
        }, 1000); 
    }
}