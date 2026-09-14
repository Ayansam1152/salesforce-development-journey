import { LightningElement } from 'lwc';
import dataModel from '@salesforce/resourceUrl/Car_Rental_Data_Model';

export default class CarRentalDataModel extends LightningElement {
    dataModelUrl = dataModel;
}