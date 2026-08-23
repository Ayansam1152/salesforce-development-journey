import { LightningElement } from 'lwc';

export default class UniversalSearch extends LightningElement {
    title = 'Welcome to Universal Search';
    searchText;
    isEmptySearch = true;
   emptySearchOrZeroResult = '';

    accounts = 
    [
        { id: '1', name: 'Acme Corporation' },
        { id: '2', name: 'Global Industries' },
        { id: '3', name: 'Salesforce' },
        { id: '4', name: 'Microsoft' },
        { id: '5', name: 'Sales' },
        { id: '6', name: 'AgentForce' }
    ];

    filterAccounts = [];

    handleChange(event)
    {
        this.searchText = event.target.value;
    }

    handleSearchClick()
    {
        console.log("search text "+ this.searchText);

        if(this.searchText == null || this.searchText.trim() === '')
        {
            this.isEmptySearch = true;
            this.emptySearchOrZeroResult = 'Please enter any account name!';
        }
        else
        {
            console.log("search text from else part"+ this.searchText);
            this.isEmptySearch = false;
            this.getFilterAccounts();

            if(this.filterAccounts.length === 0)
            {
                this.isEmptySearch = true;
                this.emptySearchOrZeroResult = 'No Account name found!';
            }
        }
        // filter the records
    }

    getFilterAccounts()
    {
        this.filterAccounts = this.accounts.filter((record) =>{
            return record.name && record.name.toLowerCase().includes(this.searchText.toLowerCase());
        });

        // let k = 0;

        // for (let index = 0; index < this.accounts.length; index++) {
        //     const record = this.accounts[index];

        //     if (record.name &&
        //         record.name.toLowerCase().includes(this.searchText.toLowerCase())) {
        //         this.filterAccounts[k++] = record;
        //     }
        // }

        //console.log("filter account "+this.filterAccounts);
    }

    handleClearClick()
    {
        //this.enteredText = '';
        var input = this.template.querySelector('lightning-input ');
        input.value = '';
        this.filterAccounts = []; 
        this.searchText = '';  
        this.emptySearchOrZeroResult = ''; 
        this.isEmptySearch = true;   
    }
}