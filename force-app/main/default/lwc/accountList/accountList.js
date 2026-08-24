import { api, LightningElement, wire } from 'lwc';

export default class AccountList extends LightningElement {
    _accountFilter;

    //@api accountFilter;

    @api
    get accountFilter()
    {
        return this._accountFilter;
    }

    set accountFilter(value)
    {
        this._accountFilter = value ? value.toLowerCase() : '';

        this.filterAccounts();
    }

    accounts = [
        { id: '1', name: 'Acme Corporation', industry: 'Technology' },
        { id: '2', name: 'Global Industries', industry: 'Finance' },
        { id: '3', name: 'Salesforce', industry: 'Technology' },
        { id: '4', name: 'Microsoft', industry: 'Technology' },
        { id: '5', name: 'JPMorgan', industry: 'Finance' }
    ]

    filteredAccounts = [...this.accounts];

    filterAccounts()
    {
        if(!this._accountFilter || this._accountFilter.includes("all"))
        {
            this.filteredAccounts = [...this.accounts];
        }
        else
        {
            this.filteredAccounts = this.accounts.filter(acc => 
                acc.industry.toLowerCase().includes(this._accountFilter)
            );
        }
    }

    handleAccountSelect(event)
    {
       
        const accountEvent = new CustomEvent("selectaccountevent", {detail:  event.currentTarget.dataset.id});

        this.dispatchEvent(accountEvent);
    }

}