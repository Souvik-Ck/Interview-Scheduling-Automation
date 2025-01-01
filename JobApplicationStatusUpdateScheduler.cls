/**
* @Company           : Cloudkaptan
* @description       : Schedulable class to run Job Application Status Update Batch job
* @author            : Souvik Sen
* @group             :
* @last modified on  : 01-01-2025
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
* Modifications Log
**/
 
public with sharing class JobApplicationStatusUpdateScheduler implements Schedulable {
    public void execute(SchedulableContext SC) {
        // Run the batch job
        JobApplicationStatusUpdateBatch batchJob = new JobApplicationStatusUpdateBatch();
        Database.executeBatch(batchJob, 200);  // Batch size of 200
    }
 
    /**
     * Convenience method to schedule the job
     */
    public static void scheduleJob() {
        // Schedule to run daily at midnight
        String cronExpression = '0 0 0 * * ?';
        System.schedule('Daily Job Application Status Update', cronExpression, new JobApplicationStatusUpdateScheduler());
    }
}
 
