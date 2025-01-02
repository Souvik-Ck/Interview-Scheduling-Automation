/**
* @Company           : Cloudkaptan
* @description       : Schedulable class to run Job Application Status Update Batch job
* @author            : Souvik Sen
* @group             :
* @last modified on  : 01-02-2025
* @last modified by  : Souvik Sen
* Modifications Log
**/
 
public with sharing class JobApplicationStatusUpdateScheduler implements Schedulable {
    /**
    * @description Executes the Job Application Status Update Batch job.
    * @author Souvik Sen | 02-01-2025
    * @param sc
    **/
    public void execute(SchedulableContext sc) {
        // Run the batch job
        JobApplicationStatusUpdateBatch batchJob = new JobApplicationStatusUpdateBatch();
        Database.executeBatch(batchJob, AssignmentsConstants.BATCH_SIZE);  // Batch size of 200
    }
 
    /**
    * @description Convenience method to schedule the job
    * @author Souvik Sen | 02-01-2025
    **/
    public static void scheduleJob() {
        // Schedule to run daily at midnight
        String cronExpression = AssignmentsConstants.CRON_EXPRESSION;
        System.schedule(AssignmentsConstants.JOB_UPDATE_NOTIFICATION, cronExpression, new JobApplicationStatusUpdateScheduler());
    }
}
 
