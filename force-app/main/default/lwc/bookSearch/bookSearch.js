import { LightningElement} from 'lwc';
import searchBooks from '@salesforce/apex/BookSearchController.searchBooks';

export default class BookSearch extends LightningElement {
    enteredText;
    searchText;
    error;
    isLoading = false;
    searchResults = [];
    showMessage = 'Please Enter book Name'
    isEmptyOrNoResult = true;

    handleChange(event)
    {
        this.enteredText = event.target.value;
    }

    handleSearchClick()
    {
        this.isEmptyOrNoResult = false;

        this.searchText = this.enteredText;

        if(!this.searchText || this.searchText === '')
        {
            this.showMessage = 'Please Enter book Name';
            this.isEmptyOrNoResult = true;
            return;
        }

        this.isLoading = true;
        // call the apex class
        searchBooks({bookName:this.searchText})
        .then((result) =>{
            this.searchResults = result;
            this.error = undefined;

            if(this.searchResults.length == 0)
            {
                this.showMessage = 'No book found!';
                this.isEmptyOrNoResult = true;
            }
        })
        .catch((error) =>{
            this.searchResults = undefined;
            this.error = error;

            this.showMessage = this.error;
        })
        .finally(() =>{
            this.isLoading = false;
            //this.isEmptyOrNoResult = false;
        });
    }
}