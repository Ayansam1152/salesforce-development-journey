import { LightningElement, wire } from 'lwc';
// Import message service features required for subscribing and the message channel
import {
    publish,
    subscribe,
    unsubscribe,
    APPLICATION_SCOPE,
    MessageContext,
} from "lightning/messageService";
import carFilter from "@salesforce/messageChannel/carFilter__c";
import carSelection from "@salesforce/messageChannel/carSelection__c";
import getCars from '@salesforce/apex/CarTileListController.getCars';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";
import BOOKING_OBJECT from '@salesforce/schema/Booking__c';
import BookCarModal from 'c/bookCarModal';
import EstimateCarBookingModal from 'c/estimateCarBookingModal';

export default class CarTileList extends NavigationMixin(LightningElement) {
    subscription = null;
    filters;
    showInitialMessage = true;

    @wire(MessageContext)
    messageContext;

    @wire(getCars, {
        filter: '$filters'
    }) cars;

    // Standard lifecycle hooks used to subscribe and unsubsubscribe to the message channel
    connectedCallback() {
        this.subscribeToMessageChannel();
    }

    disconnectedCallback() {
        this.unsubscribeToMessageChannel();
    }

    // Encapsulate logic for Lightning message service subscribe and unsubsubscribe
    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                carFilter,
                (message) => this.handleMessage(message),
                { scope: APPLICATION_SCOPE },
            );
        }
    }

    unsubscribeToMessageChannel() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    handleMessage(message) {
        console.log('message ', message);
        this.filters = { ...message.setCarFilter.filters };
        this.showInitialMessage = false;
    }

    get isRecordFound() {
        return this.cars.data && this.cars.data.length > 0;
    }

    handleCarSelect(event) {
        const payload = { recordId: event.detail };
        publish(this.messageContext, carSelection, payload);
        console.log('RecordId: ', event.detail);
        console.log('publish car selection successfully :) ', payload);
    }

    handleEstimateBooking(event) {
        EstimateCarBookingModal.open({
            carId: event.detail,
            size: 'medium'
        });
    }

    handleBookNow(event) {
        console.log('bookNow clicked', JSON.stringify(event.detail));
        BookCarModal.open({
            carId: event.detail,
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