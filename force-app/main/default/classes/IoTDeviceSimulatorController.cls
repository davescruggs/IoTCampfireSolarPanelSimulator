public class IoTDeviceSimulatorController {

    @AuraEnabled
    public static String getSessionId() {
        return UserInfo.getSessionId();
    }
    
    @AuraEnabled
    public static List<String> getEventFields(String eventName) {
        System.debug('Event name ' + eventName);
        eventName = eventName.left(eventName.length()-3);
     
        
        List<FieldDefinition> fieldList = [Select DeveloperName, DataType, FieldDefinition.Publisher.isSalesforce From FieldDefinition where EntityDefinition.DeveloperName=: eventName ];
        System.debug(fieldList);
        
        List<String> fieldNames = new List<String>();
        for(FieldDefinition item: fieldList) {
            String name = item.DeveloperName ;
            Boolean isSalesforce =  item.Publisher.IsSalesforce;
            
            if(!isSalesforce && !item.DataType.contains('Lookup')) {
                fieldNames.add(name);
            }
        }
        
        return fieldNames;
    }


    @AuraEnabled
    public static String publishEvent(sObject eventValue) {
     	System.debug('Publishing Event  ' + eventValue);
        List<sObject> eventList = new List<sObject>();
        eventList.add(eventValue);
        
       List<Database.SaveResult> results = EventBus.publish(eventList);
        
        // Inspect publishing results
        Boolean failure = false;
        for (Database.SaveResult result : results) {
            if (!result.isSuccess()) {
                failure = true;
                for (Database.Error error : result.getErrors()) {
                    System.debug('Error returned: ' +  error.getStatusCode() +' - '+  error.getMessage());
                }
            }
        }

        if (failure) {
            return 'Failure';
        } else {
            return results[0].id;
        }
       
         
    }
    

    @AuraEnabled
    public static String sendEvent(
        String serialNumber,
        String errorCode,
        String model,
        Integer powerOutput,
        Integer rotationX,
        Integer rotationZ,
        String series) {

        Tracker_Event__e evt = new Tracker_Event__e();

        if (serialNumber == null)
            return ('Error - Serial Number is required');


        if (powerOutput < 0 || powerOutput > 3000) 
            return ('Error - Power Output out of range [0:3000]');
        if (rotationX < 0 || rotationX > 360)
            return ('Error - Rotation X out of range [0:360]');
        if (rotationZ < 0 || rotationZ > 90)
            return ('Error - Rotation Z out of range [0:90]');

        evt.serial_no__c  = serialNumber;
        evt.error_code__c = errorCode;
        evt.model__c = model;
        evt.power_output__c = powerOutput;
        evt.rotation_x__c = rotationX;
        evt.rotation_z__c = rotationZ;
        evt.series__c = series;
        
        Database.SaveResult sr = EventBus.publish(evt);
        
        if (sr.isSuccess()) {
            return 'Success - ' + sr.id;
        } else {
            return 'Error - ' + sr.getErrors()[0].getStatusCode() + ' - ' + sr.getErrors()[0].getMessage();
        }
        return 'success';

    }

    @AuraEnabled
    public static List<Asset> fetchSolarPanels() {
        List<Asset> solarPanels = [SELECT Id, Name, External_ID__c  FROM Asset WHERE Product_Category__c = 'Solar Panel'];
        return solarPanels;
    }
}