public with sharing class ContactTriggerHandler extends TriggerHandler {
    
    public override void afterInsert()
    {
        List<Contact> contacts = (List<Contact>)Trigger.new;
        ContactTriggerHandlerService.processContact(contacts);
    }
    
    public override void afterUpdate()
    {
        System.debug('I am from after Update Contact');
        List<Contact> contacts = (List<Contact>)Trigger.new;
        Map<Id,Contact> oldContactMap = (Map<Id,Contact>) Trigger.oldMap;
        List<Contact> contactNeedToUpdate = new List<Contact>();
        
        for(Contact  con : contacts)
        {
            String oldEmail = oldContactMap.get(con.Id).Email;
            String newEmail = con.Email;
            
            if(oldEmail != newEmail)
            {
                contactNeedToUpdate.add(con);
            }
        }
        
        ContactTriggerHandlerService.processContact(contactNeedToUpdate);
    }
}