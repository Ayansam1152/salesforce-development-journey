public with sharing class LogCleanupBatchProcess Implements Database.Batchable<SObject>, Database.Stateful{
    
    private Integer totalRecordProcessed = 0;
    private Integer TotalSuccessfullyRecordDeleted = 0;
    private Integer TotalFailureRecords = 0;
    private String notificationEmail;
    private Integer logCleanupRetentionDays;
    
    public LogCleanupBatchProcess()
    {
        lodConfiguration();
    }
    
    private void lodConfiguration()
    {
        System_Threshold__mdt logRetentionDaysMdt = System_Threshold__mdt.getInstance('Log_Retention_Period');
        logCleanupRetentionDays = logRetentionDaysMdt != null ? Integer.valueOf(logRetentionDaysMdt.value__c) : 7;
        
        System_Threshold__mdt notificationEmailMdt = System_Threshold__mdt.getInstance('Notification_Email');
        notificationEmail = notificationEmailMdt.Value__c;
        
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC)
    {
        
        DateTime cutoffDateTime = System.now().addDays(-logCleanupRetentionDays);
        
        String query = 'Select Id from LogEvent__c Where CreatedDate < :cutoffDateTime';
        
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<LogEvent__c> scope)
    {
        if(scope == null || scope.isEmpty()) return;
        
        totalRecordProcessed+= scope.size();
        
        Database.DeleteResult[] results = Database.delete(scope, false);
        Log logger;
        for(Database.DeleteResult deleteRecord : results)
        {
            if(deleteRecord.isSuccess())
            {
                TotalSuccessfullyRecordDeleted++;
            }
            else {
                TotalFailureRecords++;
                logger.add('Record deletion failed '+ String.join(deleteRecord.getErrors(), ', '));
            }
        }
        
        logger.publish();
    }
    
    public void finish(Database.BatchableContext bc)
    {
        String subject = 'Log Cleanup Batch Process Summary ' + DateTime.now().format('dd, MM, yyyy HH:mm:ss');
        String body = 'Log cleanup batch job completed\n\n'+
            'Records Processed: '+totalRecordProcessed+'\n'+
            'Record deleted successfully: '+TotalSuccessfullyRecordDeleted+'\n'+
            'Record deletion failed: '+ TotalFailureRecords+'\n'+
            'This is an automated report from Car on Rental System';
        // need to send email
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        String[] toAddresses = new String[] {notificationEmail};
        
        mail.setToAddresses(toAddresses);
        
        mail.setSenderDisplayName('Car Rental Management');
        
        mail.setSubject(subject);
        
        // Specify the text content of the email.
        mail.setPlainTextBody(body);
        
        // Send the email you have created.
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}