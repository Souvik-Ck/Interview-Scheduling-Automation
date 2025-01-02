/**
 * @Company           : Cloudkaptan Consultancy Services Pvt. Ltd.
 * @description       : Utility class to create test users for various testing scenarios. 
 * @author            : Souvik Sen
 * @group             : 
 * @testclass         : 
 * @last modified on  : 01-02-2025
 * @last modified by  : Souvik Sen
 * Modifications Log
 * Ver   Date         Author            Modification
 * 1.0   04-12-2024   Souvik Sen   Initial Version
**/
@IsTest
public class UserCreationTestHelper {

    /**
    * @description       : Creates and inserts a test user with the specified profile.
    * @param profileName : The name of the profile for the user (optional).
    * @return            : User record created for testing purposes.
    **/
    public static User createTestUser(String profileName) {
        
        // If profileName is not provided, default to 'Standard User'
        String resolvedProfileName = profileName != null ? profileName : 'Standard User';
        
        // Fetch the profile with the specified name
        Profile userProfile = [SELECT Id FROM Profile WHERE Name = :resolvedProfileName LIMIT 1];
        
        // Create and insert the user
        User newUser = new User(
            Alias = 'testuser',
            Email = 'testuser@example.com',
            Username = 'testuser' + System.currentTimeMillis() + '@example.com',
            ProfileId = userProfile.Id,
            FirstName = 'Test',
            LastName = 'User',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            UserRoleId = null
        );
        insert newUser;
        return newUser;
    }
    
    /**
    * @description       : Creates a test user with the 'Standard User' profile.
    * @return            : User record created for testing purposes.
    **/
    public static User createDefaultTestUser() {
        return createTestUser(null);
    }
}
