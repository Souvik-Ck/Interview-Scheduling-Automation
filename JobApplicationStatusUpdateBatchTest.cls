/**
* Test class for Job Application Status Update Batch and related components
* @author AbhibhabMitra
* @date 2024-11-27
*/
@isTest
private class JobApplicationStatusUpdateBatchTest {
    @testSetup
    static void setupTestData() {
        // Create test job applications with various statuses and dates
        List<Job_Application__c> testJobApplications = new List<Job_Application__c>();
        
        // Inactive Job Application Test
        Job_Application__c inactiveJobApplication = new Job_Application__c(
            Status__c = 'Applied',
            Job_Activity_Date__c = System.today().addDays(-31)
        );
        testJobApplications.add(inactiveJobApplication);
        
        // Not Selected After Interview Test
        Job_Application__c notSelectedJobApplication = new Job_Application__c(
            Status__c = 'Interviewed',
            Job_Interview_Date__c = System.today().addDays(-15)
        );
        testJobApplications.add(notSelectedJobApplication);
        
        // Withdrawn Job Application Test
        Job_Application__c withdrawnJobApplication = new Job_Application__c(
            Status__c = 'Applied',
            Candidate_No_Longer_Interested__c = true
        );
        testJobApplications.add(withdrawnJobApplication);
        
        // Active Job Application (should not be updated)
        Job_Application__c activeJobApplication = new Job_Application__c(
            Status__c = 'Applied',
            Job_Activity_Date__c = System.today().addDays(-15)
        );
        testJobApplications.add(activeJobApplication);
        
        insert testJobApplications;
    }
    
    @isTest
    static void testJobApplicationStatusUpdateBatch() {
        Test.startTest();
        JobApplicationStatusUpdateBatch batchJob = new JobApplicationStatusUpdateBatch();
        Database.executeBatch(batchJob);
        Test.stopTest();
        
        // Verify updates
        List<Job_Application__c> updatedJobApplications = [
            SELECT Id, Status__c
            FROM Job_Application__c
            WHERE Status__c IN ('Inactive', 'Not Selected', 'Withdrawn')
        ];
        
        System.assertEquals(3, updatedJobApplications.size(),
            'Expected 3 job applications to have their status updated');
    }
    
    @isTest
    static void testScheduler() {
        Test.startTest();
        JobApplicationStatusUpdateScheduler.scheduleJob();
        Test.stopTest();
        
        // Verify job is scheduled
        List<CronTrigger> scheduledJobs = [
            SELECT Id
            FROM CronTrigger
            WHERE CronJobDetail.Name = 'Daily Job Application Status Update'
        ];
        
        System.assertEquals(1, scheduledJobs.size(),
            'Expected the job to be scheduled');
    }
}
 
