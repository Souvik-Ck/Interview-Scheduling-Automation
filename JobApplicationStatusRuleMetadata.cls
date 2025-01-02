/**
 * @description       : 
 * @author            : Souvik Sen
 * @group             : 
 * @last modified on  : 01-02-2025
 * @last modified by  : Souvik Sen
**/

public with sharing class JobApplicationStatusRuleMetadata {
    public String ruleName;
    public Integer daysSinceLastActivity;
    public Integer daysSinceInterview;
    public String currentStatus;
    public Boolean candidateNoLongerInterested;
    public String newStatus;
    public Boolean isActive;
 
    /**
     * Retrieves all active status update rules
     * @return List of active JobApplicationStatusRuleMetadata
     */
    public static List<JobApplicationStatusRuleMetadata> getActiveRules() {
        List<JobApplicationStatusRuleMetadata> activeRules = new List<JobApplicationStatusRuleMetadata>();
        
        // Retrieve active rules from Custom Metadata Type
        for (Rule__mdt rule :
            [SELECT
                RuleName__c,
                NewStatus__c,
                DaysSinceLastActivity__c,
                DaysSinceInterview__c,
                CurrentStatus__c,
                Candidate_no_longer_interested__c,
                Active__c
            FROM Rule__mdt
            WHERE Active__c = true
            WITH SYSTEM_MODE]) {
            
            JobApplicationStatusRuleMetadata ruleMetadata = new JobApplicationStatusRuleMetadata();
            ruleMetadata.ruleName = rule.RuleName__c;
            ruleMetadata.daysSinceLastActivity = rule.DaysSinceLastActivity__c != null
                ? Integer.valueOf(rule.DaysSinceLastActivity__c) : null;
            ruleMetadata.daysSinceInterview = rule.DaysSinceInterview__c != null
                ? Integer.valueOf(rule.DaysSinceInterview__c) : null;
            ruleMetadata.currentStatus = rule.CurrentStatus__c;
            ruleMetadata.candidateNoLongerInterested = rule.Candidate_no_longer_interested__c;
            ruleMetadata.newStatus = rule.NewStatus__c;
            ruleMetadata.isActive = rule.Active__c;
            
            activeRules.add(ruleMetadata);
        }
        
        return activeRules;
    }
}
