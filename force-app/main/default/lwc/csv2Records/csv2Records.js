import { LightningElement, track } from 'lwc';
import uploadRecords from '@salesforce/apex/massCommunityTeams.uploadCommunityMembers';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class Csv2Records extends LightningElement {
  fileName = 'No file uploaded yet.';
  @track columns = [];
  @track data = [];
  csvLabel = 'BuilderName,CommunityName,CommunityOwnerEmail,CommunityTeamMemberEmail,JobType';
  totalNumberOfRecords = 0;

  async handleFileUpload(event) {
      const files = event.detail.files;
      if (files.length > 0) {
        const file = files[0];
        this.fileName = file.name;
        await this.read(file);
      }
    }

    async read(file) {
      try {
        const result = await this.load(file);
        this.parse(result);
        //this.CSV2JSON(result);
      } catch (e) {
        this.error = e;
      }
    }

    async load(file) {
      return new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.onload = () => {
          resolve(reader.result);
        };
        reader.onerror = () => {
          reject(reader.error);
        };
        reader.readAsText(file);
      });
    }

    parse(csv) {
      //const lines = csv.trim().replace(/\r?\n\r?\n/g, '\n').split("\n");
      //const pattern = /(\r\n|\n|\r)/gm;
      //const commaRegex = /,(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)/g;
      //const quotesRegex = /^"(.*)"$/g;
      //let currentline=lines[i].trim().split(commaRegex);

      //const lines = csv.split(/\r\n|\n/); //Orig
      
      const lines = csv.trim().replace(/\r?\n\r?\n/g, '\n').split("\n");
      //const lines = csv.trim().replace(/\r?\n\r?\n/g, '\n');
      const pattern = /(\r\n|\n|\r)/gm;
      const commaRegex = /,(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)/g;
      const quotesRegex = /^"(.*)"$/g;
      //End of new
     
      const headers = lines[0].split(',');
      this.columns = headers.map((header) => {
        return { label: header, fieldName: header };
      });
      const data = [];
      lines.forEach((line, i) => {
        if (i === 0) return;
        const obj = {};
        //const currentline = line.split(','); Orig
        let currentline=lines[i].trim().split(commaRegex);

        for (let j = 0; j < headers.length; j++) {
          obj[headers[j]] = currentline[j];
          //console.log(currentline[j]);
          //console.log(currentline[j].replace(quotesRegex, "$1"));
          //const objKey = headers[j].replace(/\s+/g, '');
          //obj[objKey] = currentline[j].replace(quotesRegex, "$1");
          //obj[objKey] = currentline[j];
        }
        data.push(obj);
      });
      console.log('' + JSON.stringify(this.data));
      this.data = data;
      //this.handleInsertClick;
    }

    // This method is used to download template used for mass community teams.
    downloadTemplate() {
      let hiddenElement = document.createElement('a');
      hiddenElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(this.csvLabel);
      hiddenElement.target = '_blank';
      hiddenElement.download = 'MassCommunityTeamUploadTemplate.csv';
      hiddenElement.click();
    }

    showToast() {
      const event = new ShowToastEvent({
      title: 'Success',
      message: 'Operation successful',
      variant: 'success',
      mode: 'dismissible'
      });
      this.dispatchEvent(event);
    }

    handleInsertClick(){
      uploadRecords({
        inputCasesJSON: JSON.stringify(this.data)
      }) 
      .then((result) => {
        this.showToast();
        this.error = undefined;
        this.data=[];
      })
      .catch((error) => {
        this.error = error;
      });
      
    }

}