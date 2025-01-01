/**
* Batch Apex class to update Job Application statuses based on configured rules
* @author Souvik Sen
* @date 2024-11-27
*/
public with sharing class JobApplicationStatusUpdateBatch implements Database.Batchable<Job_Application__c>, Database.Stateful {
    // Batch execution statistics
    private Integer recordsProcessed = 0;
    private Integer recordsUpdated = 0;
 
    public List<Job_Application__c> start(Database.BatchableContext BC) {
        // Retrieve active rules
        List<JobApplicationStatusRuleMetadata> activeRules = JobApplicationStatusRuleMetadata.getActiveRules();
        
        // Dynamic query to retrieve job applications based on rules
        Set<String> currentStatuses = new Set<String>();
        for (JobApplicationStatusRuleMetadata rule : activeRules) {
            currentStatuses.add(rule.currentStatus);
        }
 
        List<Job_Application__c> jobApplicationsToProcess = [
            SELECT Id,
                   Status__c,
                   Job_Activity_Date__c,
                   Job_Interview_Date__c,
                   Candidate_No_Longer_Interested__c
            FROM Job_Application__c
            WHERE Status__c IN :currentStatuses
        ];
        
        return jobApplicationsToProcess;
    }
 
    public void execute(Database.BatchableContext BC, List<Job_Application__c> scope) {
        List<Job_Application__c> jobApplicationsToUpdate = new List<Job_Application__c>();
        List<JobApplicationStatusRuleMetadata> activeRules = JobApplicationStatusRuleMetadata.getActiveRules();
 
        for (Job_Application__c jobApplication : scope) {
            for (JobApplicationStatusRuleMetadata rule : activeRules) {
                Boolean shouldUpdate = false;
 
                // Inactive Job Application Rule
                if (rule.daysSinceLastActivity != null &&
                    jobApplication.Job_Activity_Date__c != null &&
                    jobApplication.Status__c == rule.currentStatus) {
                    Integer daysSinceLastActivity = jobApplication.Job_Activity_Date__c.daysBetween(System.today());
                    shouldUpdate = daysSinceLastActivity >= rule.daysSinceLastActivity;
                }
 
                // Not Selected After Interview Rule
                if (rule.daysSinceInterview != null &&
                    jobApplication.Job_Interview_Date__c != null &&
                    jobApplication.Status__c == rule.currentStatus) {
                    Integer daysSinceInterview = jobApplication.Job_Interview_Date__c.daysBetween(System.today());
                    shouldUpdate = daysSinceInterview >= rule.daysSinceInterview;
                }
 
                // Withdrawn Rule
                if (rule.candidateNoLongerInterested &&
                    jobApplication.Candidate_No_Longer_Interested__c &&
                    jobApplication.Status__c == rule.currentStatus) {
                    shouldUpdate = true;
                }
 
                // Update job application if rule conditions are met
                if (shouldUpdate) {
                    jobApplication.Status__c = rule.newStatus;
                    jobApplicationsToUpdate.add(jobApplication);
                    recordsUpdated++;
                    break;  // Apply only the first matching rule
                }
            }
            recordsProcessed++;
        }
 
        // Perform updates with partial success
        if (!jobApplicationsToUpdate.isEmpty()) {
            List<Database.SaveResult> saveResults = Database.update(jobApplicationsToUpdate, false);
            
            // Log any errors during update
            for (Database.SaveResult result : saveResults) {
                if (!result.isSuccess()) {
                    for (Database.Error error : result.getErrors()) {
                        System.debug('Error updating job application: ' + error.getMessage());
                    }
                }
            }
        }
    }
 
    public void finish(Database.BatchableContext BC) {
        // Optional: Send email or log summary
        System.debug('Batch Job Summary:');
        System.debug('Total Records Processed: ' + recordsProcessed);
        System.debug('Total Records Updated: ' + recordsUpdated);
    }
}
