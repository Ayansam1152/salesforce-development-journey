import { LightningElement, wire } from 'lwc';
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import Pickup_Location from "@salesforce/schema/Car__c.PickupLocation__c";
import TransmissionType from "@salesforce/schema/Car__c.Transmission_Type__c";
import FuelType from "@salesforce/schema/Car__c.Fuel_Type__c";
// Import message service features required for publishing and the message channel
import { publish, MessageContext } from "lightning/messageService";
import carFilter from "@salesforce/messageChannel/carFilter__c";
const DELAY = 350;

export default class CarFilter extends LightningElement {

  filters = {
    searchKey: "",
    pickupLocation: 'Delhi',
    startDate: null,
    endDate: null,
    maxSeats: 8,
    maxRentalRate: 10000,
    minRating: 0,
    transmissionType: [],
    fuelType: []
  };

  delayTimeOut;

  @wire(MessageContext)
  messageContext;

  @wire(getPicklistValues, { recordTypeId: "012000000000000AAA", fieldApiName: Pickup_Location })
  pickupLocationValues;
  @wire(getPicklistValues, { recordTypeId: "012000000000000AAA", fieldApiName: TransmissionType })
  transmissionTypeValues;
  @wire(getPicklistValues, { recordTypeId: "012000000000000AAA", fieldApiName: FuelType })
  fuelTypeValues;

  handleSearchChange(event) {
    this.filters.searchKey = event.target.value;
    this.publishFilter();
  }

  handleLocationChange(event) {
    this.filters.pickupLocation = event.target.value;
    this.publishFilter();
  }

  handleStartDateChange(event) {
    this.filters.startDate = event.target.value;
    this.publishFilter();
  }

  handleEndDateChange(event) {
    this.filters.endDate = event.target.value;
    this.publishFilter();
  }

  handleMaxSeatChange(event) {
    this.filters.maxSeats = event.target.value;
    this.publishFilter();
  }

  handleMaxRentalRateChange(event) {
    this.filters.maxRentalRate = event.target.value;
    this.publishFilter();
  }

  handleMinRatingChange(event) {
    this.filters.minRating = event.target.value;
    this.publishFilter();
  }

  handleCheckboxChange(event) {
    const value = event.target.dataset.value;
    const name = event.target.name;

    if (name === 'transmissionType') {
      if (event.target.checked) {
        if (!this.filters.transmissionType.includes(value)) {
          this.filters.transmissionType.push(value);
        }
      }
      else {
        this.filters.transmissionType = this.filters.transmissionType.filter((item) =>
          item !== value
        );
      }
    }

    if (name === 'fuelType') {
      if (event.target.checked) {
        if (!this.filters.fuelType.includes(value)) {
          this.filters.fuelType.push(value);
        }
      }
      else {
        this.filters.fuelType = this.filters.fuelType.filter((item) =>
          item !== value
        );
      }
    }

    this.publishFilter();
  }

  validateFilter() {
    let isValid = true;
    const startDate = this.template.querySelector('.startDateClass');
    const endDate = this.template.querySelector('.endDateClass');

    startDate.setCustomValidity("");
    endDate.setCustomValidity("");

    if (!this.filters.startDate) {
      startDate.setCustomValidity("Start date is required");
      isValid = false;
    }

    if (!this.filters.endDate) {
      endDate.setCustomValidity("End date is required");
      isValid = false;
    }

    if (this.filters.startDate && this.filters.endDate) {
      if (this.filters.startDate > this.filters.endDate) {
        startDate.setCustomValidity("Start date should be before end date");
        isValid = false;
      }
    }

    startDate.reportValidity();
    endDate.reportValidity();

    return isValid;
  }

  publishFilter() {
    console.log('Car filter change', JSON.stringify(this.filters));
    if (this.validateFilter()) {
      clearTimeout(this.delayTimeOut);
      this.delayTimeOut = setTimeout(() => {
        // publish the message to the channel
        const payload = {
          setCarFilter: {
            filters: this.filters
          }
        };

        publish(this.messageContext, carFilter, payload);

        console.log("payload", JSON.stringify(payload));
        console.log("Filter published successfully");
      }, DELAY);
    }
  }

}