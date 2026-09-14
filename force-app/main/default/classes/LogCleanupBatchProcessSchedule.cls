public with sharing class LogCleanupBatchProcessSchedule implements Schedulable {
    
    public void execute(SchedulableContext sc)
    {
        LogCleanupBatchProcess batch = new LogCleanupBatchProcess();
        
        Database.executeBatch(batch, 200);
    }
    
}