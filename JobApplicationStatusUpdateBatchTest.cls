/**
 * @description       : test class for creating job application status batch update
 * @author            : Souvik Sen
 * @group             : 
 * @last modified on  : 01-02-2025
 * @last modified by  : Souvik Sen
**/
@isTest
private class JobApplicationStatusUpdateBatchTest {
    @testSetup
    static void setupTestData() {
        User testUser = UserCreationTestHelper.createDefaultTestUser();
        System.runAs(testUser) {

            // Create test job applications with various statuses and dates
            List<Job_Application__c> testJobApplications = new List<Job_Application__c>();
            
            // Inactive Job Application Test
            Job_Application__c inactiveJobApplication = new Job_Application__c(
                Status__c = AssignmentsConstants.STATUS_APPLIED,
                Job_Activity_Date__c = System.today().addDays(AssignmentsConstants.INACTIVE_DAYS_THRESHOLD)
            );
            testJobApplications.add(inactiveJobApplication);
            
            // Not Selected After Interview Test
            Job_Application__c notSelectedJobApplication = new Job_Application__c(
                Status__c = AssignmentsConstants.STATUS_INTERVIEWED,
                Job_Interview_Date__c = System.today().addDays(AssignmentsConstants.NOT_SELECTED_DAYS_THRESHOLD)
            );
            testJobApplications.add(notSelectedJobApplication);
            
            // Withdrawn Job Application Test
            Job_Application__c withdrawnJobApplication = new Job_Application__c(
                Status__c = AssignmentsConstants.STATUS_APPLIED,
                Candidate_No_Longer_Interested__c = true
            );
            testJobApplications.add(withdrawnJobApplication);
            
            // Active Job Application (should not be updated)
            Job_Application__c activeJobApplication = new Job_Application__c(
                Status__c = AssignmentsConstants.STATUS_APPLIED,
                Job_Activity_Date__c = System.today().addDays(AssignmentsConstants.NOT_SELECTED_DAYS_THRESHOLD)
            );
            testJobApplications.add(activeJobApplication);
            
            insert testJobApplications;
        }
    }
    
    /**
    * @description Verifies the batch job correctly updates job application statuses based on conditions.
    * @author Souvik Sen | 02-01-2025 
    **/
    @isTest
    static void testJobApplicationStatusUpdateBatch() {
        User testUser = UserCreationTestHelper.createDefaultTestUser();
        System.runAs(testUser) {
            Test.startTest();
            JobApplicationStatusUpdateBatch batchJob = new JobApplicationStatusUpdateBatch();
            Database.executeBatch(batchJob);
            Test.stopTest();
            
            // Verify updates
            List<Job_Application__c> updatedJobApplications = [
                SELECT Id, Status__c
                FROM Job_Application__c
                WHERE Status__c IN (:AssignmentsConstants.STATUS_INACTIVE, :AssignmentsConstants.STATUS_NOT_SELECTED, :AssignmentsConstants.STATUS_WITHDRAWN)
            ];
            
            System.assertEquals(3, updatedJobApplications.size(),
            AssignmentsConstants.EXPECTED_JOB_APPLICATIONS_MESSAGE);
        }
    }
    
    /**
    * @description Verifies the scheduler job is successfully scheduled to run daily for updating job application statuses.
    * @author Souvik Sen | 02-01-2025 
    **/
    @isTest
    static void testScheduler() {
        User testUser = UserCreationTestHelper.createDefaultTestUser();
        System.runAs(testUser) {
            Test.startTest();
            JobApplicationStatusUpdateScheduler.scheduleJob();
            Test.stopTest();
            
            // Verify job is scheduled
            List<CronTrigger> scheduledJobs = [
                SELECT Id
                FROM CronTrigger
                WHERE CronJobDetail.Name = :AssignmentsConstants.DAILY_JOB_NAME
            ];
            
            System.assertEquals(1, scheduledJobs.size(), AssignmentsConstants.EXPECTED_JOB_SCHEDULE_MESSAGE);
        }
    }
}
