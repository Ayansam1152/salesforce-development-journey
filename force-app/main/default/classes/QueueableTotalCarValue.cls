public with sharing class QueueableTotalCarValue Implements Queueable {
    List<Id> carIds;
    
    public QueueableTotalCarValue(List<Id> carIds) {
        this.carIds = carIds;
    }
    
    public void execute(QueueableContext context)
    {
        AggregateResult[] results = [Select Car__c, SUM(Total_Paid_Amount__c) from Booking__c where Status__c =:Constants.BOOKING_CLOSED_STATUS And Car__c in :carIds  Group By Car__c ];
        
        List<Car__c> carsToUpdate = new List<Car__c>();
        
        for(AggregateResult result : results){
            Id carId = (Id)result.get('Car__c');
            Decimal totalPaidAmount = (Decimal)result.get('expr0');
            
            Car__c carToUpdate = new Car__c(Id = carId,Total_Bookings_Value__c = totalPaidAmount);
            
            carsToUpdate.add(carToUpdate);
        }
        
        if(carsToUpdate.size() > 0){
            
            try
            {
                update carsToUpdate;
            }
            catch(DmlException e)
            {
                System.debug('Error updating cars: ' + e.getMessage());
                
                Log logger = Log.get();
                logger.publish('Error updating cars: ' + e.getMessage());
            }
        }
    }
    
}