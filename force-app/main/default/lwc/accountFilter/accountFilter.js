import { LightningElement } from 'lwc';

export default class AccountFilter extends LightningElement {
    selectedValue;

    get dropdownOptions()
    {
        return [
            {label:"All", value:"All"},
            {label:"Technology", value:"Technology"},
            {label:"Finance", value:"Finance"}
        ];
    }

    handleDropdownChange(event)
    {
        this.selectedValue = event.target.value;
    }

    handleClickFilter()
    {
        const filterEvent = new CustomEvent("filtervalue", {detail:this.selectedValue});

        this.dispatchEvent(filterEvent);
    }

    handleResetFilter(event)
    {
        // custom event parent make filter all
        const resetEvent = new CustomEvent("resetfilterevent", {detail:"All"});
        this.dispatchEvent(resetEvent);

        let input = this.template.querySelector("lightning-combobox");
        input.value = "All";
        this.selectedValue = "All";
    }
}