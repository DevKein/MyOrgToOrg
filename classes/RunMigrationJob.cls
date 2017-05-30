public without sharing class RunMigrationJob extends AbstractRestfullService {
    public Migration_Job__c migrationJob;
    private String QUERYTEMPLATE = 'SELECT {0} FROM {1} WHERE {2} IN: whereIds';
    private String QUERYTEMPLATEMULTI = 'SELECT {0} FROM {1} WHERE {2}';
    private Map<String, Map<String, String>> sourceFields {get; set;}
    public Migration_Rule__c baseRule {get; set;}
    private String baseRuleId {get; set;}
    private String destinationOrgSetupId {get; set;}
    public Set<String> ruleIds = new Set<String>();
    public Map<Id, Migration_Rule__c> migrationRules {get; set;}
    private Map<String, Map<RelationEnum, Map<Id, Migration_Rule__c>>> relationsMap {get; set;}
    private Map<String, Map<RelationEnum, Map<Id, Migration_Rule_Relation__c>>> MRRelationsMap {get; set;}
    private Map<String, Integer> orderMap {get; set;}
    public Map<Integer, String> orderedMap {get; set;}
    private Map<Integer, String> dmlPriorityMap {get; set;}
    private Map<String, Map<String, String>> externalMappings {get; set;}
    public Map<String, Boolean> selfRelation {get; set;}
    public Map<String, Integer> chunckSizeMap {get; set;}
    public Map<String, String> sourceToTarget {get; set;}
    public Map<String, Map<String, String>> literalValues {get; set;}
    private Set<String> whereIds {get; set;}
    public Map<String, Map<Id, String>> rtMappings {get; set;}
    private Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();

    public Id initialJobId {get; set;}
    public List<Migration_Job_Rule_Hierarchy__c> hierarchies {get; set;}
    public Integer processCounter {get; set;}
    public RunMigrationJob(ApexPages.StandardController stdController) {
        if (!Test.isRunningTest()) {
            stdController.addFields(new String[] {
                                        'MigrateTHIS__Org_Credential__c',
                                        'Base_Object_Migration_Rule__c',
                                        'List_View_Id__c',
                                        'Notification_Email_Address__c',
                                        'Send_Notification_Email_On_Complete__c'
                                    });
        }
        migrationJob = (Migration_Job__c)stdController.getRecord();
        init(migrationJob);
    }
    public RunMigrationJob(Migration_Job__c mj) {
        init(mj);
    }
    public void runNow() {
        System.debug(loggingLevel.Error, '*** girdi: ');
        RunMigrationJob.runFuture(migrationJob.id, UserInfo.getSessionId());
    }
    /**
     * Starts the migration
     * @param jobId     Job id to run
     * @param SessionId Running user session Id
     */
    @Future(callout = true)
    @TestVisible private static void runFuture(Id jobId, String SessionId) {
        Migration_Job__c mj = [SELECT Id, Name, Org_Credential__c , Base_Object_Migration_Rule__c, List_View_Id__c,
                               Notification_Email_Address__c, Send_Notification_Email_On_Complete__c
                               FROM Migration_Job__c
                               WHERE Id = : jobId LIMIT 1];
        RunMigrationJob rm = new RunMigrationJob(mj);
        rm.Run(mj, SessionId);
    }
    private void init(Migration_Job__c job) {
        processCounter = 0;
        hierarchies = new List<Migration_Job_Rule_Hierarchy__c>([SELECT Id, Name, Migration_Rule__c, Sort_Order__c, Source_Object__c,
                Target_Object__c, Is_Base__c
                FROM Migration_Job_Rule_Hierarchy__c
                WHERE Migration_Job__c = : job.id Order BY Sort_Order__c ASC]);
        orderMap = new Map<String, Integer>();
        destinationOrgSetupId = job.Org_Credential__c;
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        getRuleIdsFromHierarchy(hierarchies);
        ruleSetup();
        mappingSetup();
        recordTypeSetup();
        operationSetup(migrationRules);
        orderOperations(relationsMap, baseRuleId);
        orderedMap = new Map<Integer, String>();
        for (String oid : orderMap.keySet()) {
            orderedMap.put(orderMap.get(oid), oid);
        }
    }

    public void Run(Migration_Job__c job, String SessionId) {
        whereIds = new Set<String>();
        String LVquery ;
        if (!String.isBlank(SessionId)) {
            LVquery = ListviewOperations.getListViewQuery(baseRule.Source_Object__c, job.List_View_Id__c, SessionId);
        } else {
            LVquery = ListviewOperations.getListViewQuery(baseRule.Source_Object__c, job.List_View_Id__c);
        }
        if (Test.isRunningTest()) {
            LVquery = 'SELECT Id,Name FROM Account';
        }
        for (sObject bo : database.query(LVquery)) {
            whereIds.add(String.valueOf(bo.get('Id')));
        }
        String objectName = migrationRules.get(orderedMap.get(1)).Source_Object__c;
        String queryString = QueryBuilder(objectName, whereIds);
        System.debug(loggingLevel.Error, '*** chunckSizeMap: ' + chunckSizeMap);
        initialJobId = System.schedule('Migration Data Preparation - 1 - objectName: ' + objectName, Datetime.now().addSeconds(20).format('s m H d M ? yyyy'), new ScheduleCallout(new Map<String, List<sObject>>(), false, 1, job, queryString, whereIds, orderedMap, migrationRules, MRRelationsMap, literalValues, dmlPriorityMap, selfRelation, externalMappings, sourceFields, sourceToTarget, chunckSizeMap, rtMappings) );
    }
    
    public void mappingSetup() {
        sourceFields = new Map<String, Map<String, String>>();
        externalMappings = new Map<String, Map<String, String>>();
        literalValues = new Map<String, Map<String, String>>();
        for (Migration_Rule_Mapping__c maps : [SELECT Id, Name, Source_Field__c, Source_Object__c, Migration_Type__c, Target_Field__c, Manuel_Entry_Value__c, Is_ID_Field__c
                                               FROM Migration_Rule_Mapping__c
                                               WHERE Migration_Rule__c IN: ruleIds AND Destination_Org__c = : destinationOrgSetupId]) {
            if (maps.Migration_Type__c == 'Field From Source') {
                if (sourceFields.containsKey(maps.Source_Object__c)) {
                    Map<String, String> temp = sourceFields.get(maps.Source_Object__c);
                    temp.put(maps.Source_Field__c, maps.Target_Field__c);
                    sourceFields.put(maps.Source_Object__c, temp);
                } else {
                    Map<String, String> temp = new Map<String, String>();
                    temp.put(maps.Source_Field__c, maps.Target_Field__c);
                    sourceFields.put(maps.Source_Object__c, temp);
                }
                if (externalMappings.containsKey(maps.Source_Object__c) && maps.Is_ID_Field__c) {
                    Map<String, String> temp = externalMappings.get(maps.Source_Object__c);
                    temp.put(maps.Source_Field__c, maps.Target_Field__c);
                    externalMappings.put(maps.Source_Object__c, temp);
                } else if (maps.Is_ID_Field__c) {
                    Map<String, String> temp = new Map<String, String>();
                    temp.put(maps.Source_Field__c, maps.Target_Field__c);
                    externalMappings.put(maps.Source_Object__c, temp);
                }
            } else {
                if (literalValues.containsKey(maps.Source_Object__c)) {
                    Map<String, String> temp = literalValues.get(maps.Source_Object__c);
                    temp.put(maps.Target_Field__c, maps.Manuel_Entry_Value__c);
                    literalValues.put(maps.Source_Object__c, temp);
                } else {
                    Map<String, String> temp = new Map<String, String>();
                    temp.put(maps.Target_Field__c, maps.Manuel_Entry_Value__c);
                    literalValues.put(maps.Source_Object__c, temp);
                }
            }
        }
    }
    public void recordTypeSetup() {
        rtMappings = new Map<String, Map<Id, String>>();
        Map<String, String> rtNames = new Map<String, String>();
        for (RecordType_Mapping__c rt : [SELECT Id, Migration_Rule__c, Migration_Rule__r.Source_Object__c, Org_Credential__c, Source_RecordType_Name__c, Destination_RecordType_Name__c FROM RecordType_Mapping__c WHERE Migration_Rule__c IN: ruleIds AND Org_Credential__c = : destinationOrgSetupId]) {
            rtNames.put(rt.Source_RecordType_Name__c, rt.Destination_RecordType_Name__c);
        }
        Map<String, List<RecordType>> sourceRecordTypes = RecordTypes.recordTypeMap(sourceToTarget.keySet(), rtNames.keySet());
        for (String objName : sourceRecordTypes.keySet()) {
            for (RecordType rtype : sourceRecordTypes.get(objName)) {
                if (rtMappings.containsKey(objName)) {
                    Map<Id, String> temp = rtMappings.get(objName);
                    if (rtNames.containsKey(rtype.DeveloperName)) {
                        temp.put(rtype.Id, rtNames.get(rtype.DeveloperName));
                    } else if (rtNames.containsKey(rtype.Name)) {
                        temp.put(rtype.Id, rtNames.get(rtype.Name));
                    }
                    
                    rtMappings.put(objName, temp);
                } else {
                    Map<Id, String> temp = new Map<Id, String>();
                    if (rtNames.containsKey(rtype.DeveloperName)) {
                        temp.put(rtype.Id, rtNames.get(rtype.DeveloperName));
                    } else if (rtNames.containsKey(rtype.Name)) {
                        temp.put(rtype.Id, rtNames.get(rtype.Name));
                    }
                    rtMappings.put(objName, temp);
                }
            }
        }
    }
    public void ruleSetup() {
        migrationRules = new Map<Id, Migration_Rule__c>();
        selfRelation = new Map<String, Boolean>();
        chunckSizeMap = new Map<String, Integer>();
        sourceToTarget = new Map<String, String>();
        for (Migration_Rule__c mr : [SELECT Id, Name, Source_Object__c, Target_Object__c, Source_Object_Name_Field__c, Target_Object_Name_Field__c,
                                     Source_Object_Reference_to_Target__c, Is_self_related__c, Target_Record_Type__c, Description__c, Callout_Chunk_Size__c
                                     FROM Migration_Rule__c
                                     WHERE Id IN: ruleIds]) {
            migrationRules.put(mr.id, mr);
            if (mr.id == baseRuleId) {
                baseRule = mr;
            }
            chunckSizeMap.put(mr.id, Integer.valueOf(mr.Callout_Chunk_Size__c));
            selfRelation.put(mr.Source_Object__c, mr.Is_self_related__c);
            sourceToTarget.put(mr.Source_Object__c, mr.Target_Object__c);
        }
    }
    private Integer orderNo = 1;
    private void orderOperations(Map<String, Map<RelationEnum, Map<Id, Migration_Rule__c>>> relationsMap, String criteriaRuleId) {
        if (!orderMap.containsKey(criteriaRuleId)) {
            orderMap.put(criteriaRuleId, orderNo);
        }
        if (relationsMap.containsKey(criteriaRuleId)) {
            Map<RelationEnum, Map<Id, Migration_Rule__c>> relatedRules = relationsMap.get(criteriaRuleId);
            for (RelationEnum re : relatedRules.keySet()) {
                if (re == RelationEnum.PARENT) {
                    for (Migration_Rule__c mr : relatedRules.get(re).values()) {
                        if (!orderMap.containsKey(mr.id)) {
                            orderNo++;
                            orderMap.put(mr.id, orderNo);
                            orderOperations(relationsMap, mr.id);
                        }
                    }
                }
            }
            for (RelationEnum re : relatedRules.keySet()) {
                if (re == RelationEnum.CHILD) {
                    for (Migration_Rule__c mr : relatedRules.get(re).values()) {
                        if (!orderMap.containsKey(mr.id)) {
                            orderNo++;
                            orderMap.put(mr.id, orderNo);
                            orderOperations(relationsMap, mr.id);
                        }
                    }
                }
            }
        }
    }
    private void getRuleIdsFromHierarchy(List<Migration_Job_Rule_Hierarchy__c> hierarchies) {
        if (ruleIds.isEmpty()) {
            dmlPriorityMap = new Map<Integer, String>();
            for (Migration_Job_Rule_Hierarchy__c hier : hierarchies) {
                ruleIds.add(hier.Migration_Rule__c);
                if (hier.Is_Base__c && baseRuleId == null) {
                    baseRuleId = hier.Migration_Rule__c;
                }
                dmlPriorityMap.put(Integer.valueOf(hier.Sort_Order__c), hier.Source_Object__c);
            }
        }
    }
    @TestVisible
    private List<sObject> getBaseData(String baseQuery, String listViewid) {
        List<sObject> baseDataSet = new  List<sObject>();
        ApexPages.StandardSetController baseSSC = new ApexPages.StandardSetController(Database.getQueryLocator(baseQuery));
        baseSSC.setPageSize(2000);
        baseSSC.setFilterId(listViewid);
        baseDataSet.addAll(baseSSC.getRecords());
        return baseDataSet;
    }
    @TestVisible
    private void operationSetup(Map<Id, Migration_Rule__c> migrationRules) {
        relationsMap = new Map<String, Map<RelationEnum, Map<Id, Migration_Rule__c>>>();
        MRRelationsMap = new Map<String, Map<RelationEnum, Map<Id, Migration_Rule_Relation__c>>>();
        List<Migration_Rule_Relation__c> relations = new List<Migration_Rule_Relation__c>([SELECT Detail_Migration_Rule__c, Master_Migration_Rule__c,
                Source_Relationship_Name__c, Target_Relationship_Field__c
                FROM Migration_Rule_Relation__c
                WHERE Detail_Migration_Rule__c IN: migrationRules.keySet() OR Master_Migration_Rule__c IN: migrationRules.keySet()]);
        for (Migration_Rule_Relation__c mrr : relations) {
            if (relationsMap.containsKey(mrr.Master_Migration_Rule__c) && migrationRules.containsKey(mrr.Detail_Migration_Rule__c)) {
                Map<RelationEnum, Map<Id, Migration_Rule__c>> tempMap = relationsMap.get(mrr.Master_Migration_Rule__c);
                Map<RelationEnum, Map<Id, Migration_Rule_Relation__c>> tempRelationMap = MRRelationsMap.get(mrr.Master_Migration_Rule__c);
                Map<Id, Migration_Rule__c> tempList;
                Map<Id, Migration_Rule_Relation__c> tempRelationList;
                if (tempMap.containsKey(RelationEnum.CHILD)) {
                    tempList = tempMap.get(RelationEnum.CHILD);
                    tempRelationList = tempRelationMap.get(RelationEnum.CHILD);
                    tempList.put(migrationRules.get(mrr.Detail_Migration_Rule__c).id, migrationRules.get(mrr.Detail_Migration_Rule__c));
                    tempRelationList.put(migrationRules.get(mrr.Detail_Migration_Rule__c).id, mrr);
                } else {
                    tempList = new Map<Id, Migration_Rule__c>();
                    tempRelationList = new Map<Id, Migration_Rule_Relation__c>();
                    tempList.put(migrationRules.get(mrr.Detail_Migration_Rule__c).id, migrationRules.get(mrr.Detail_Migration_Rule__c));
                    tempRelationList.put(migrationRules.get(mrr.Detail_Migration_Rule__c).id, mrr);
                }
                tempMap.put(RelationEnum.CHILD, tempList);
                tempRelationMap.put(RelationEnum.CHILD, tempRelationList);
                relationsMap.put(mrr.Master_Migration_Rule__c, tempMap);
                MRRelationsMap.put(mrr.Master_Migration_Rule__c, tempRelationMap);
            } else if (migrationRules.containsKey(mrr.Detail_Migration_Rule__c)) {
                Map<RelationEnum, Map<Id, Migration_Rule__c>> tempMap = new Map<RelationEnum, Map<Id, Migration_Rule__c>>();
                Map<RelationEnum, Map<Id, Migration_Rule_Relation__c>> tempRelationMap = new Map<RelationEnum, Map<Id, Migration_Rule_Relation__c>>();
                tempMap.put(RelationEnum.CHILD, new Map<Id, Migration_Rule__c> {migrationRules.get(mrr.Detail_Migration_Rule__c).id => migrationRules.get(mrr.Detail_Migration_Rule__c)});
                tempRelationMap.put(RelationEnum.CHILD, new Map<Id, Migration_Rule_Relation__c> {migrationRules.get(mrr.Detail_Migration_Rule__c).id => mrr});
                relationsMap.put(mrr.Master_Migration_Rule__c, tempMap);
                MRRelationsMap.put(mrr.Master_Migration_Rule__c, tempRelationMap);
            }
            if (relationsMap.containsKey(mrr.Detail_Migration_Rule__c) && migrationRules.containsKey(mrr.Master_Migration_Rule__c)) {
                Map<RelationEnum, Map<Id, Migration_Rule__c>> tempMap = relationsMap.get(mrr.Detail_Migration_Rule__c);
                Map<RelationEnum, Map<Id, Migration_Rule_Relation__c>> tempRelationMap = MRRelationsMap.get(mrr.Detail_Migration_Rule__c);
                Map<Id, Migration_Rule__c> tempList;
                Map<Id, Migration_Rule_Relation__c> tempRelationList;
                if (tempMap.containsKey(RelationEnum.PARENT)) {
                    tempList = tempMap.get(RelationEnum.PARENT);
                    tempRelationList = tempRelationMap.get(RelationEnum.PARENT);
                    tempList.put(migrationRules.get(mrr.Master_Migration_Rule__c).id, migrationRules.get(mrr.Master_Migration_Rule__c));
                    tempRelationList.put(migrationRules.get(mrr.Master_Migration_Rule__c).id, mrr);
                } else {
                    tempList = new Map<Id, Migration_Rule__c>();
                    tempRelationList = new Map<Id, Migration_Rule_Relation__c>();
                    tempList.put(migrationRules.get(mrr.Master_Migration_Rule__c).id, migrationRules.get(mrr.Master_Migration_Rule__c));
                    tempRelationList.put(migrationRules.get(mrr.Master_Migration_Rule__c).id, mrr);
                }
                tempMap.put(RelationEnum.PARENT, tempList);
                tempRelationMap.put(RelationEnum.PARENT, tempRelationList);
                relationsMap.put(mrr.Detail_Migration_Rule__c, tempMap);
                MRRelationsMap.put(mrr.Detail_Migration_Rule__c, tempRelationMap);
            } else if (migrationRules.containsKey(mrr.Master_Migration_Rule__c)) {
                Map<RelationEnum, Map<Id, Migration_Rule__c>> tempMap = new Map<RelationEnum, Map<Id, Migration_Rule__c>>();
                Map<RelationEnum, Map<Id, Migration_Rule_Relation__c>> tempRelationMap = new Map<RelationEnum, Map<Id, Migration_Rule_Relation__c>>();
                tempMap.put(RelationEnum.PARENT, new Map<Id, Migration_Rule__c> {migrationRules.get(mrr.Master_Migration_Rule__c).id => migrationRules.get(mrr.Master_Migration_Rule__c)});
                tempRelationMap.put(RelationEnum.PARENT, new Map<Id, Migration_Rule_Relation__c> {migrationRules.get(mrr.Master_Migration_Rule__c).id => mrr});
                relationsMap.put(mrr.Detail_Migration_Rule__c, tempMap);
                MRRelationsMap.put(mrr.Detail_Migration_Rule__c, tempRelationMap);
            }
        }
    }
    private String QueryBuilder(String objectName, Set<String> whereIds) {
        return QueryBuilder(objectName, whereIds, 'Id');
    }
    private String QueryBuilder(String objectName, Set<String> whereIds, String referanceField) {
        List<String> fields = new List<String>();
        fields.addAll(sourceFields.get(objectName).keySet());
        String mergedFields = String.join(fields, ' ,');
        return String.format(QUERYTEMPLATE, new String[] {mergedFields, objectName, referanceField});
    }

}