/**
 * @author Mert YALTI
 * @date 13/05/2017
 * @version 1.0
 */
public with sharing class ResultTrackingController {
    public Migration_Job__c migrationJob;
    public Map<String, operationWrapper> operations {get; set;}
    public Datetime startTime {get; set;}
    public String batchJobId {get; set;}
    public Integer processCounter {get; set;}
    /**
     * Constructor method
     * Initializes first operation
     */
    public ResultTrackingController(ApexPages.StandardController stdController) {
        migrationJob = (Migration_Job__c)stdController.getRecord();
        processCounter = 0;
        operations = new Map<String, operationWrapper>();
        batchJobId = [SELECT Id FROM ApexClass WHERE Name = 'BatchCallout' LIMIT 1].id;
        String jobId = migrationJob.ID;
        try {
            startTime = Datetime.valueOf(ApexPages.currentPage().getParameters().get('startDatetime'));
        } catch (Exception ex) {
        }
    }

    /**
     * Gets scheduled apex jobs and their related batch apex jobs to show them in the tracking page.
     * @return PageReference
     */
    public PageReference track() {
        Set<Id> jobIds = new Set<Id>();
        List<CronTrigger> cron = new List<CronTrigger>([SELECT Id, StartTime, EndTime, OwnerId, PreviousFireTime, CronExpression, CronJobDetail.Name , CronJobDetail.JobType, State  FROM CronTrigger
                WHERE (CronJobDetail.JobType = '7' AND CronJobDetail.Name LIKE 'Migration%-%')]);
        if (!cron.isEmpty()) {
            for (CronTrigger ct : cron) {
                if (!operations.containsKey(ct.CronJobDetail.Name)) {
                    processCounter++;
                    for (String k : operations.keySet()) {
                        operationWrapper temp = operations.get(k);
                        temp.State = 'Completed';
                        operations.put(ct.CronJobDetail.Name, temp);
                    }
                    operations.put(ct.CronJobDetail.Name, new operationWrapper(ct.CronJobDetail.Name, 'ScheduledApex', ct.StartTime, ct.EndTime, 'Scheduled'));
                }
                jobIds.add(ct.Id);
            }
        } 
        return null;
    }
    /**
     * Operation wrapper
     */
    public class operationWrapper {
        public String jobName {get; set;}
        public String Type {get; set;}
        public Datetime StartTime {get; set;}
        public Datetime EndTime {get; set;}
        public String State {get; set;}
        /**
         * Constructor
         * @param  jobName   Migration job name
         * @param  Type      Job type (Scheduled Apex or Batch Apex)
         * @param  StartTime Job start time
         * @param  EndTime   Job completion time
         * @param  State     Last know state of the job
         */
        public operationWrapper(String jobName, String Type, Datetime StartTime, Datetime EndTime, String State) {
            this.jobName = jobName;
            this.Type = Type;
            this.StartTime = StartTime;
            this.EndTime = EndTime;
            this.State = State;
        }
    }
}