import { api, LightningElement, track } from 'lwc';
import getContacts from '@salesforce/apex/ContactClass.getContacts';

export default class ContactList extends LightningElement {
    _searchText;
    searchResults;
    error;
    showMessage = 'Enter any contact name';
    isEmptySearchOrResultNone = true;
    isLoading = false;

    @api set searchTextFromParent(value)
    {
        this._searchText = value ? value : '';

        if(this._searchText === '')
        {
            this.isEmptySearchOrResultNone = true;
            this.showMessage = 'Please enter contact name!!!';
            return;
        }
        
            this.isLoading = true;
            this.fetchDataActively(this._searchText);
            // this.isEmptySearchOrResultNone = this.searchResults?.length == 0 ? false : true;
            console.log("contactList: from api "+this.searchResults);

            if(this.searchResults && this.searchResults.length > 0)
            {
                this.showMessage = '';
                this.isEmptySearchOrResultNone = false;
            }
            else
            {
                this.showMessage = "No Contact found!";
                this.isEmptySearchOrResultNone = true;
            }
            // if(!this.isEmptySearchOrResultNone)
            // {
            //     this.showMessage = "No Contact found!";
            // }
            // this.isLoading = false;
        
    }

    get searchTextFromParent()
    {
        return this._searchText;
    }

    fetchDataActively(searchKey)
    {
        console.log("Contact Key : "+searchKey);
       return getContacts({contactName:searchKey})
        .then((result) =>{
            this.searchResults = result;
            this.error = undefined;
        })
        .catch((error) =>{
            this.searchResults = undefined;
            this.error = error;
        })
        .finally(()=>{
            this.isLoading = false;
        });
    }

}