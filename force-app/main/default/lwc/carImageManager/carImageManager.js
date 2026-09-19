import { api, LightningElement, wire} from 'lwc';
import createFile from '@salesforce/apex/CarImageController.createFile';
import getCarImages from '@salesforce/apex/CarImageController.getCarImages';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { refreshApex } from "@salesforce/apex";

export default class CarImageManager extends LightningElement {
    isPrimaryChecked = true;
    @api recordId;

    @wire(getCarImages, {
        carId:'$recordId'
    })
    carImages;

    get hasProductImages()
    {
        
        let hasImagePresent = false;
        
        if(this.carImages.data && this.carImages.data.length > 0)
        {
            hasImagePresent = true;
        }
        console.log("car images "+ hasImagePresent);
        return hasImagePresent;

        /*
       const hasImages = !!(this.carImages?.data && this.carImages.data.length > 0);
        console.log("car images present: " + hasImages);
        return hasImages;
        */
    }
    
    handlePrimaryImage(event)
    {
        this.isPrimaryChecked = event.target.checked;
    }

    async handleUploadFinished(event)
    {
        // Get the list of uploaded files
        const uploadedFiles = event.detail.files;
        const carFile = uploadedFiles[0];
        let documentId = carFile.documentId;

        try {
             await createFile({
            documentId:documentId,
            recordId: this.recordId,
            isPrimaryImage: this.isPrimaryChecked
            });

            this.showToast('Success','Image Upload Successfully','success');
            await refreshApex(this.carImages);
            await notifyRecordUpdateAvailable([{recordId: this.recordId}]);

        } catch (error) {
            showToast('Error','Image Upload failed','error');
        }
    }

    showToast(title, message, variant) {
    const event = new ShowToastEvent({
      title: title,
      message:
        message,
        variant: variant
    });
    this.dispatchEvent(event);
  }
}