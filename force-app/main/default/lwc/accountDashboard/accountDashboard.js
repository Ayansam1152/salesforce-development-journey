import { LightningElement } from 'lwc';

export default class AccountDashboard extends LightningElement {
    childFilterValue;
    selectedAccountId = '';
    isAccountIdEmpty = true;

    handleFilterValue(event)
    {
        this.childFilterValue = event.detail;
    }

    handleSelectAccount(event)
    {
        this.isAccountIdEmpty = false;
        this.selectedAccountId = event.detail;
    }

    handleResetFilter(event)
    {
        this.childFilterValue = event.detail;
    }
}