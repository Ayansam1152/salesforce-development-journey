public with sharing class PaymentTransactionTriggerHandler extends TriggerHandler {
    
    public override void afterInsert() {
        // Call the method to create a new Payment Transaction record
        PaymentTransactionTriggerHandlerService.handlePaymentTransaction(Trigger.new);
    }

    public override void afterDelete(){
        PaymentTransactionTriggerHandlerService.handlePaymentTransaction(Trigger.old);
    }
}