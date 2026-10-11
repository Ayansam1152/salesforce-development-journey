import { LightningElement, wire } from 'lwc';

// Import message service features required for subscribing and the message channel
import {
    subscribe,
    unsubscribe,
    APPLICATION_SCOPE,
    MessageContext,
} from "lightning/messageService";
import carSelection from "@salesforce/messageChannel/carSelection__c";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import NAME_FIELD from "@salesforce/schema/Car__c.Name";
import MODEL_FIELD from "@salesforce/schema/Car__c.Model__c";
import CAR_FAMILY_FIELD from "@salesforce/schema/Car__c.Car_Family__c";
import SEATS_FIELD from "@salesforce/schema/Car__c.Number_of_Seats__c";
import TRANSMISSION_FIELD from "@salesforce/schema/Car__c.Transmission_Type__c";
import FUEL_TYPE_FIELD from "@salesforce/schema/Car__c.Fuel_Type__c";
import RENTAL_RATE_FIELD from "@salesforce/schema/Car__c.Rental_Rate_Per_Day__c";
import DESCRIPTION_FIELD from "@salesforce/schema/Car__c.Car_Description__c";
import BookCarModal from 'c/bookCarModal';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";
import BOOKING_OBJECT from '@salesforce/schema/Booking__c';

const FIELDS = [
    NAME_FIELD,
    MODEL_FIELD,
    CAR_FAMILY_FIELD,
    SEATS_FIELD,
    TRANSMISSION_FIELD,
    FUEL_TYPE_FIELD,
    RENTAL_RATE_FIELD,
    DESCRIPTION_FIELD
];

export default class CarCard extends NavigationMixin(LightningElement) {
    subscription = null;
    recordId;
    productName;
    modelField;
    carFamilyField;
    seatingCapacityBadge;
    transmissionBadge;
    fuelTypeBadge;
    rentalRateBadge;
    descriptionBadge;

    hasData = false;

    @wire(MessageContext)
    messageContext;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wireRecord({ error, data }) {
        if (data) {
            console.log('Getting response from record api');
            this.productName = getFieldValue(data, NAME_FIELD);
            this.modelField = getFieldValue(data, MODEL_FIELD);
            this.carFamilyField = getFieldValue(data, CAR_FAMILY_FIELD);

            const seatingCapacity = getFieldValue(data, SEATS_FIELD);
            this.seatingCapacityBadge = seatingCapacity + 'Seats';

            const transmission = getFieldValue(data, TRANSMISSION_FIELD);
            this.transmissionBadge = transmission ? transmission : 'NA';

            const fuelType = getFieldValue(data, FUEL_TYPE_FIELD);
            this.fuelTypeBadge = fuelType ? fuelType : 'NA';

            const rentalRate = getFieldValue(data, RENTAL_RATE_FIELD);
            this.rentalRateBadge = '₹' + rentalRate + '/day';

            this.descriptionBadge = getFieldValue(data, DESCRIPTION_FIELD);

            console.log('Now Data load success');
            this.hasData = true;
        }
        else {
            console.log(error);
        }
    }

    // Encapsulate logic for Lightning message service subscribe and unsubsubscribe
    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                carSelection,
                (message) => this.handleMessage(message),
                { scope: APPLICATION_SCOPE },
            );
        }
    }

    unsubscribeToMessageChannel() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    // Handler for message received by component
    handleMessage(message) {
        this.recordId = message.recordId;
        this.hasData = false;
        console.log('Calling from subscriber method', message.recordId);
    }


    // Standard lifecycle hooks used to subscribe and unsubsubscribe to the message channel
    connectedCallback() {
        this.subscribeToMessageChannel();
    }

    disconnectedCallback() {
        this.unsubscribeToMessageChannel();
    }

    handleBookNow(event) {
        BookCarModal.open({
            carId: this.recordId,
            size: 'medium'
        }).then((result) => {
            if (result && result.output === 'success') {
                // show success toast
                this.showToast('Success', 'Booking Created Successfully', 'success');
                let bookingId = result.bookingId;

                let bookingPageRef = {
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: bookingId,
                        objectApiName: BOOKING_OBJECT.objectApiName,
                        actionName: 'view'
                    }
                }

                this[NavigationMixin.Navigate](bookingPageRef);

            }
        });
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