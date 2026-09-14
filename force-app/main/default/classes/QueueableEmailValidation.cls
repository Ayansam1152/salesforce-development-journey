public with sharing class QueueableEmailValidation implements Queueable, Database.AllowsCallouts {
    
    Set<Id> contactIds;
    
    public QueueableEmailValidation(Set<Id> ids)
    {
        this.contactIds = ids;
    }
    
    public void execute(QueueableContext context) {
        
        List<Contact> contacts = [Select Id, Email from Contact Where Id in : contactIds];
        List<Contact> contactToBeUpdated = new List<Contact>();
        for(Contact con : contacts)
        {
            System.debug('About to call external api from email validation');
            con.Email_Verified__c = validateEmail(con.email);
            
            contactToBeUpdated.add(con);
            
        }
        
        try {
            update contactToBeUpdated;
        } catch (Exception e) {
            Log logger = Log.get();
            
            logger.publish('Error occurred while validating the customer email '+e.getMessage());
            
        }
        
    }
    //https://app.abstractapi.com/api/email-reputation/tester
    private Boolean validateEmail(String email)
    {
        System_Threshold__mdt emailReputationMdt = System_Threshold__mdt.getInstance('Email_Reputation_APIKey');
        String apiKey =(String) emailReputationMdt.Value__c;
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        request.setEndpoint('callout:EmailReputationAPI/?api_key='+apiKey+'&email='+email);
        request.setMethod('GET');
        request.setHeader('Content-Type', 'application/json');
        
        Log logger = Log.get();
        
        System.debug('All set, now just hitting the external server with our request');
        try {
            HttpResponse response = http.send(request);
            
            if(response.getStatusCode() == 200)
            {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                Map<String,Object> emailDeliverability =(Map<String,Object>) responseMap.get('email_deliverability');
                
                if(emailDeliverability.get('status') == 'deliverable' && emailDeliverability.get('status_detail') == 'valid_email')
                {
                    return true;
                }
            }
            else {
                logger.add('email validation response code is not 200');
            }
            
            return false;
            
        } catch (Exception e) {
            logger.add(e.getMessage());
            
            logger.publish();
            return false;
        }
        
    }
}