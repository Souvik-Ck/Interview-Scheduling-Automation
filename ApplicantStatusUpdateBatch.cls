public class ApplicantStatusUpdateBatch implements Database.Batchable<SObject>, Schedulable {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Query all active rules from Custom Metadata
        List<ApplicantStatusRules__mdt> rules = [SELECT RuleName__c, DaysSinceLastActivity__c, DaysSinceInterview__c, CurrentStatus__c, CandidateNotInterested__c, NewStatus__c, Active__c FROM ApplicantStatusRules__mdt WHERE Active__c = true];

        // Dynamically build query based on rules
        String query = 'SELECT Id, LastModifiedDate, Interview_Date__c, Status__c, Withdrawn__c FROM Candidate__c WHERE ';
        List<String> conditions = new List<String>();

        for (ApplicantStatusRules__mdt rule : rules) {
            if (rule.DaysSinceLastActivity__c != null) {
                conditions.add('(LastModifiedDate <= LAST_N_DAYS:' + rule.DaysSinceLastActivity__c + ' AND Status__c != \'' + rule.NewStatus__c + '\')');
            }
            if (rule.DaysSinceInterview__c != null) {
                conditions.add('(Interview_Date__c <= LAST_N_DAYS:' + rule.DaysSinceInterview__c + ' AND Status__c = \'' + rule.CurrentStatus__c + '\' AND Status__c != \'' + rule.NewStatus__c + '\')');
            }
            if (rule.CandidateNotInterested__c) {
                conditions.add('(Withdrawn__c = true AND Status__c != \'' + rule.NewStatus__c + '\')');
            }
        }

        query += String.join(conditions, ' OR ');
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Candidate__c> scope) {
        List<Candidate__c> candidatesToUpdate = new List<Candidate__c>();

        List<ApplicantStatusRules__mdt> rules = [SELECT RuleName__c, DaysSinceLastActivity__c, DaysSinceInterview__c, CurrentStatus__c, CandidateNotInterested__c, NewStatus__c, Active__c FROM ApplicantStatusRules__mdt WHERE Active__c = true];

        for (Candidate__c applicant : scope) {
            for (ApplicantStatusRules__mdt rule : rules) {
                if (rule.DaysSinceLastActivity__c != null && applicant.LastModifiedDate <= System.today().addDays(-rule.DaysSinceLastActivity__c.intValue()) && applicant.Status__c != rule.NewStatus__c) {
                    applicant.Status__c = rule.NewStatus__c;
                    candidatesToUpdate.add(applicant);
                    break;
                }
                if (rule.DaysSinceInterview__c != null && applicant.Interview_Date__c != null && applicant.Interview_Date__c <= System.today().addDays(-rule.DaysSinceInterview__c.intValue()) && applicant.Status__c == rule.CurrentStatus__c && applicant.Status__c != rule.NewStatus__c) {
                    applicant.Status__c = rule.NewStatus__c;
                    candidatesToUpdate.add(applicant);
                    break;
                }
                if (rule.CandidateNotInterested__c && applicant.Withdrawn__c == true && applicant.Status__c != rule.NewStatus__c) {
                    applicant.Status__c = rule.NewStatus__c;
                    candidatesToUpdate.add(applicant);
                    break;
                }
            }
        }

        if (!candidatesToUpdate.isEmpty()) {
            try {
                update candidatesToUpdate;
            } catch (DmlException e) {
                System.debug('Error updating candidates: ' + e.getMessage());
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Batch job completed.');
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new ApplicantStatusUpdateBatch(), 200);
    }

    public static void scheduleBatch(String cronExpression) {
        ApplicantStatusUpdateBatch batch = new ApplicantStatusUpdateBatch();
        String jobName = 'ApplicantStatusUpdateJob';
        System.schedule(jobName, cronExpression, batch);
    }
}
