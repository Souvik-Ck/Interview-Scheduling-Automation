/**
 * @Company           : Cloudkaptan Consultancy Services Pvt. Ltd.
 * @description       : Batch Apex class for update Job Application statuses based on configured rules
 * @author            : Souvik Sen
 * @testclass         : 
 * @last modified on  : 01-02-2025
 * @last modified by  : Souvik Sen
 * Modifications Log
 * Ver   Date         Author            Modification
 * 1.0   12-18-2024   Souvik Sen   Initial Version
**/
public with sharing class JobApplicationStatusUpdateBatch implements Database.Batchable<Job_Application__c>, Database.Stateful {
    
    // Batch execution statistics
    private Integer recordsProcessed = 0;
    private Integer recordsUpdated = 0;
 
    /**
    * @description Retrieves job applications that match the statuses defined in the active rules.
    * @author Souvik Sen | 12-18-2024 
    * @param bc 
    * @return List<Job_Application__c> 
    **/
    public List<Job_Application__c> start(Database.BatchableContext bc) {

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
 
    /**
     * @description Processes a batch of job applications, evaluates conditions from rules, and updates their statuses accordingly.
     * @param       bc Database.BatchableContext - Provides runtime context about the batch job.
     * @param       scope List<Job_Application__c> - A batch of job applications to process.
     **/
    public void execute(Database.BatchableContext bc, List<Job_Application__c> scope) {
        List<Job_Application__c> jobApplicationsToUpdate = new List<Job_Application__c>();
        List<JobApplicationStatusRuleMetadata> activeRules = JobApplicationStatusRuleMetadata.getActiveRules();

        for (Job_Application__c jobApplication : scope) {
            processJobApplication(jobApplication, activeRules, jobApplicationsToUpdate);
            recordsProcessed++;
        }

        // Perform the update if there are changes
        if (!jobApplicationsToUpdate.isEmpty()) {
            update jobApplicationsToUpdate;
        }
    }

    /**
     * @description Processes an individual job application by evaluating rules and determining if it needs an update.
     * @param       jobApplication Job_Application__c - The job application to process.
     * @param       activeRules List<JobApplicationStatusRuleMetadata> - The list of active rules.
     * @param       jobApplicationsToUpdate List<Job_Application__c> - The list of job applications to be updated.
     **/
    private void processJobApplication(
        Job_Application__c jobApplication,
        List<JobApplicationStatusRuleMetadata> activeRules,
        List<Job_Application__c> jobApplicationsToUpdate
    ) {
        for (JobApplicationStatusRuleMetadata rule : activeRules) {
            if (evaluateRule(jobApplication, rule)) {
                jobApplication.Status__c = rule.newStatus;
                jobApplicationsToUpdate.add(jobApplication);
                recordsUpdated++;
                break; // Apply only the first matching rule
            }
        }
    }

    /**
     * @description Evaluates a job application against a single rule to determine if it should be updated.
     * @param       jobApplication Job_Application__c - The job application to evaluate.
     * @param       rule JobApplicationStatusRuleMetadata - The rule to evaluate against.
     * @return      Boolean - True if the job application meets the rule's criteria, false otherwise.
     **/
    private Boolean evaluateRule(Job_Application__c jobApplication, JobApplicationStatusRuleMetadata rule) {
        return meetsLastActivityRule(jobApplication, rule) ||
            meetsInterviewRule(jobApplication, rule) ||
            meetsWithdrawalRule(jobApplication, rule);
    }

    /**
     * @description Checks if the job application meets the "Last Activity" rule criteria.
     * @param       jobApplication Job_Application__c - The job application to evaluate.
     * @param       rule JobApplicationStatusRuleMetadata - The rule to evaluate against.
     * @return      Boolean - True if the job application meets the "Last Activity" criteria, false otherwise.
     **/
    private Boolean meetsLastActivityRule(Job_Application__c jobApplication, JobApplicationStatusRuleMetadata rule) {
        if (rule.daysSinceLastActivity != null &&
            jobApplication.Job_Activity_Date__c != null &&
            jobApplication.Status__c == rule.currentStatus) {
            Integer daysSinceLastActivity = jobApplication.Job_Activity_Date__c.daysBetween(System.today());
            return daysSinceLastActivity >= rule.daysSinceLastActivity;
        }
        return false;
    }

    /**
     * @description Checks if the job application meets the "Interview" rule criteria.
     * @param       jobApplication Job_Application__c - The job application to evaluate.
     * @param       rule JobApplicationStatusRuleMetadata - The rule to evaluate against.
     * @return      Boolean - True if the job application meets the "Interview" criteria, false otherwise.
     **/
    private Boolean meetsInterviewRule(Job_Application__c jobApplication, JobApplicationStatusRuleMetadata rule) {
        if (rule.daysSinceInterview != null &&
            jobApplication.Job_Interview_Date__c != null &&
            jobApplication.Status__c == rule.currentStatus) {
            Integer daysSinceInterview = jobApplication.Job_Interview_Date__c.daysBetween(System.today());
            return daysSinceInterview >= rule.daysSinceInterview;
        }
        return false;
    }

    /**
     * @description Checks if the job application meets the "Withdrawal" rule criteria.
     * @param       jobApplication Job_Application__c - The job application to evaluate.
     * @param       rule JobApplicationStatusRuleMetadata - The rule to evaluate against.
     * @return      Boolean - True if the job application meets the "Withdrawal" criteria, false otherwise.
     **/
    private Boolean meetsWithdrawalRule(Job_Application__c jobApplication, JobApplicationStatusRuleMetadata rule) {
        return rule.candidateNoLongerInterested &&
            jobApplication.Candidate_No_Longer_Interested__c &&
            jobApplication.Status__c == rule.currentStatus;
    }

   /**
     * @description finish method 
     * @param       jobApplication Job_Application__c - The job application to evaluate.
     * @param       rule JobApplicationStatusRuleMetadata - The rule to evaluate against.
     * @return      Boolean - True if the job application meets the "Withdrawal" criteria, false otherwise.     
     **/
    public void finish(Database.BatchableContext bc) {
        // Optional: Send email or log summary
        System.debug('Batch Job Summary:');
        System.debug('Total Records Processed: ' + recordsProcessed);
        System.debug('Total Records Updated: ' + recordsUpdated);
    }
}
