/**
 * Custom Javascript button webservice class. Run now button triggers this class from Migration job page layout
 * @author Mert YALTI
 * @date 13/05/2017
 * @version 1.0
 */
global class RunWebService {
	/**
	 * Triggers run migration job class.
	 * Simply this method starts the migration.
	 * @param  jobId Job id to run
	 * @return       String message
	 */
	webservice static String run(Id jobId) {
		runNow(jobId, UserInfo.getSessionId());
		String trackingURL = '/apex/MigrateTHIS__ResultTracking?Id=' + jobId + '&startDatetime=' + Datetime.now();
		return 'Migration request is succesfully queued!!,,,,,'+trackingURL;
	}
	/**
	 * Starts the migration
	 * @param jobId     Job id to run
	 * @param SessionId Running user session Id
	 */
	@Future(callout = true)
	private static void runNow(Id jobId, String SessionId) {
		Migration_Job__c mj = [SELECT Id,Name, Org_Credential__c , Base_Object_Migration_Rule__c, List_View_Id__c,
		                       Notification_Email_Address__c, Send_Notification_Email_On_Complete__c
		                       FROM Migration_Job__c
		                       WHERE Id = : jobId LIMIT 1];
		RunMigrationJob rm = new RunMigrationJob(mj);
		rm.Run(mj, SessionId);
	}
}