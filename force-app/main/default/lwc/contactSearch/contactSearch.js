import { LightningElement } from 'lwc';

export default class ContactSearch extends LightningElement {
    searchText;

    handleChange(event)
    {
        this.searchText = event.target.value;
    }

    handleSearchClick(event)
    {
        const searchEvent = new CustomEvent("searchtextevent", {detail:this.searchText});
        this.dispatchEvent(searchEvent);
    }
}