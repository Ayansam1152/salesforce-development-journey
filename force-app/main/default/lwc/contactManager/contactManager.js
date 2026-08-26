import { LightningElement } from 'lwc';

export default class ContactManager extends LightningElement {
    searchTextFromChild1;

    handleSearchValue(event)
    {
        this.searchTextFromChild1 = event.detail;
    }

}