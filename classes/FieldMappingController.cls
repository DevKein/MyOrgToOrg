public with sharing class FieldMappingController extends AbstractRestfullService {

    public Migration_Rule__c mysObject;
    private String oAuthToken {get; set;}
    public String sourceObject {get; set;}
    public String targetObject {get; set;}
    public Map<String, SoapType> sourceFields {get; set;}
    public Map<Id, RecordType> sourceRecordTypes {get; set;}
    public Map<Id, RecordType> targetRecordTypes {get; set;}
    public Map<Id, RecordType> targetRecordTypesState {get; set;}
    public Map<String, SoapType> targetFields {get; set;}
    public Map<String, SoapType> targetFieldsState {get; set;}
    public String destinationOrgSetupId {get; set;}
    public String ruleId {get; set;}
    public Map<Id, Settings__c> settings {get; set;}
    public List<SelectOption> settingOptions {get; set;}
    public String selectedSetting {get; set;}
    public Map<String, List<mappingWrapper>> mappedFields {get; set;}
    public Map<String, List<recordTypeMappingWrapper>> recordtypeMapping {get; set;}
    public Map<String, List<mappingWrapper>> mappedFieldsState {get; set;}
    public Set<String> externalFields {get; set;}
    private Set<String> processedTargets {get; set;}
    public Settings__c setting {get; set;}
    public String selectedTargetField {get; set;}
    public String manualValue {get; set;}
    public Boolean compared {get; set;}
    public Map<String, SoapType> fullList {get; set;}
    private Map<ID, RecordType> allSourceRT {get; set;}
    //public Map<String, Set<String>> compatibleTypesMap {get;set;}

    public FieldMappingController(ApexPages.StandardController stdController) {
        if (!Test.isRunningTest()) {
            stdController.addFields(new String[] {
                                        'Source_Object__c',
                                        'Target_Object__c'
                                    });
        }
        this.mysObject = (Migration_Rule__c)stdController.getRecord();
        mappedFields = new Map<String, List<mappingWrapper>>();
        recordtypeMapping = new Map<String, List<recordTypeMappingWrapper>>();
        fullList = new Map<String, SoapType>();
        mappedFieldsState = new Map<String, List<mappingWrapper>>();
        settings = new Map<Id, Settings__c>([SELECT Id, Destination_Org_Username__c, Destination_Org_Security_Token__c, Destination_Org_Password__c, Name, Connected_App_Client_Id__c, Connected_App_Client_Secret__c, Destination_Endpoint__c FROM Settings__c WHERE Active__c = true]);
        settingOptions = new List<SelectOption>();
        settingOptions.add(new SelectOption('', '-- None --'));
        for (Id st : settings.keySet()) {
            settingOptions.add(new SelectOption(st, settings.get(st).Name));
        }
        sourceObject = mysObject.Source_Object__c;
        targetObject = mysObject.Target_Object__c;
        destinationOrgSetupId = ApexPages.currentPage().getParameters().get('org');
        ruleId = ApexPages.currentPage().getParameters().get('Id');
    }
    public PageReference retrieveSourceFields() {
        sourceFields = new Map<String, SoapType>();
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        Schema.SObjectType ctype = gd.get(mysObject.Source_Object__c);
        Map<String, Schema.SobjectField> sf = ctype.getDescribe().fields.getMap();
        for (String f : sf.keySet()) {
            Schema.DescribeFieldResult fr = sf.get(f).getDescribe();
            List<Schema.SObjectType> relatedTo = fr.getReferenceTo();
            if (fr.isAccessible() && (relatedTo.isEmpty() || (!relatedTo.isEmpty() && relatedTo[0].getDescribe().getName() != 'User'))) {
                sourceFields.put(fr.getName(), sf.get(f).getDescribe().getSoapType());
            }
        }
        return null;
    }

    public PageReference retrieveTargetRecordTypes() {
        if (!settings.isEmpty() && selectedSetting != '') {
            targetRecordTypes = new Map<Id, RecordType>();
            targetRecordTypesState = new Map<Id, RecordType>();
            sourceRecordTypes = new Map<Id, RecordType>();
            recordtypeMapping.clear();
            String result = FieldRequest(oAuthToken, targetObject, setting.Destination_Endpoint__c, true);
            if (!Test.isRunningTest()) {
                RecordTypeWrapper wrap = (RecordTypeWrapper)JSON.deserialize(result, RecordTypeWrapper.class);
                targetRecordTypes.putAll(wrap.recordTypeMap);
                targetRecordTypesState.putAll(wrap.recordTypeMap);
            } else {
                targetRecordTypes.put(mysObject.id, null);
                targetRecordTypesState.put(mysObject.id, null);
            }
            Map<String, RecordType_Mapping__c> existingTypeMapping = new Map<String, RecordType_Mapping__c>();
            for (RecordType_Mapping__c rtm : [SELECT Id, Destination_RecordType_Name__c, Source_RecordType_Name__c FROM RecordType_Mapping__c WHERE Org_Credential__c = : setting.Id AND Migration_Rule__c = : mysObject.Id]) {
                existingTypeMapping.put(rtm.Source_RecordType_Name__c, rtm);
            }
            allSourceRT = RecordTypes.getAllRecordTypes(mysObject.Source_Object__c);
            for (Id rtId : allSourceRT.keySet()) {
                if (!existingTypeMapping.containsKey(allSourceRT.get(rtId).DeveloperName)) {
                    sourceRecordTypes.put(rtId, allSourceRT.get(rtId));
                } else {
                    if (recordtypeMapping.containsKey(allSourceRT.get(rtId).DeveloperName)) {
                        List<recordTypeMappingWrapper> tempRt = recordtypeMapping.get(allSourceRT.get(rtId).DeveloperName);
                        tempRt.add(new recordTypeMappingWrapper(existingTypeMapping.get(allSourceRT.get(rtId).DeveloperName).id, existingTypeMapping.get(allSourceRT.get(rtId).DeveloperName).Source_RecordType_Name__c, rtId, existingTypeMapping.get(allSourceRT.get(rtId).DeveloperName).Destination_RecordType_Name__c, null ));
                        recordtypeMapping.put(allSourceRT.get(rtId).DeveloperName, tempRt);
                    } else {
                        List<recordTypeMappingWrapper> tempRt = new List<recordTypeMappingWrapper>();
                        tempRt.add(new recordTypeMappingWrapper(existingTypeMapping.get(allSourceRT.get(rtId).DeveloperName).id, existingTypeMapping.get(allSourceRT.get(rtId).DeveloperName).Source_RecordType_Name__c, rtId, existingTypeMapping.get(allSourceRT.get(rtId).DeveloperName).Destination_RecordType_Name__c, null ));
                        recordtypeMapping.put(allSourceRT.get(rtId).DeveloperName, tempRt);
                    }
                }
            }
        }
        return null;
    }

    public PageReference retrieveTargetFields() {
        if (!settings.isEmpty() && selectedSetting != '') {
            processedTargets = new Set<String>();
            externalFields = new Set<String>();

            targetFields = new Map<String, SoapType>();
            targetFieldsState = new Map<String, SoapType>();
            setting = settings.get(selectedSetting);
            ClientResource client = new ClientResource(setting.Destination_Org_Username__c, setting.Destination_Org_Password__c, setting.Destination_Org_Security_Token__c);
            if (!Test.isRunningTest()) {
                oAuthToken = login(setting, client);
            } else {
                oAuthToken = 'ThisIsMyTestToken';
            }
            String result = FieldRequest(oAuthToken, targetObject, setting.Destination_Endpoint__c, false);
            List<TargetFieldWrapper> resultsMap = (List<TargetFieldWrapper>)JSON.deserialize(result, List<TargetFieldWrapper>.class);
            for (Migration_Rule_Mapping__c mrp : [SELECT Source_Field__c, Target_Field__c, Source_Object__c, Migration_Type__c, Migration_Rule__c, Destination_Org__c, Is_ID_Field__c FROM Migration_Rule_Mapping__c WHERE Migration_Rule__c = : mysObject.Id AND Destination_Org__c = :setting.Id]) {
                if (mappedFields.containsKey(mrp.Source_Field__c)) {
                    List<mappingWrapper> temp = mappedFields.get(mrp.Source_Field__c);
                    temp.add(new mappingWrapper(mrp.id, mrp.Source_Field__c, mrp.Target_Field__c, mrp.Is_ID_Field__c));
                    mappedFields.put(mrp.Source_Field__c, temp);
                } else {
                    List<mappingWrapper> temp = new List<mappingWrapper>();
                    temp.add(new mappingWrapper(mrp.id, mrp.Source_Field__c, mrp.Target_Field__c, mrp.Is_ID_Field__c));
                    mappedFields.put(mrp.Source_Field__c, temp);
                }
                processedTargets.add(mrp.Target_Field__c);
            }
            mappedFieldsState.putAll(mappedFields);
            if (!resultsMap.isEmpty()) {
                for (TargetFieldWrapper f : resultsMap) {
                    if (!mappedFields.containsKey(f.fieldName) && !processedTargets.contains(f.fieldName)) {
                        targetFields.put(f.fieldName, f.fieldType);
                    }
                    if (f.isExternal) {
                        externalFields.add(f.fieldName);
                    }
                    fullList.put(f.fieldName, f.fieldType);
                }
            }
        }
        if (!targetFields.isEmpty()) {
            targetFieldsState.putAll( targetFields );
        } else {
            targetFieldsState.putAll(fullList);
        }
        return null;
    }
    public void setMapping() {
        /**Target Org Field**/
        String f = ApexPages.currentPage().getParameters().get('from').removeStart('tf');
        /**Source Org Field**/
        String t = ApexPages.currentPage().getParameters().get('to').removeStart('sf');
        if (mappedFields.containsKey(t)) {
            List<mappingWrapper> temp = mappedFields.get(f);
            Boolean isExternal = false;
            if (t == 'Id' && externalFields.contains(f)) isExternal = true;
            if (temp !=  null) {
                temp.add(new mappingWrapper(null, t, f, isExternal));
                mappedFields.put(t, temp);
            } else {
                temp = new List<mappingWrapper>();
                temp.add(new mappingWrapper(null, t, f, isExternal));
                mappedFields.put(t, temp);
            }
        } else {
            Boolean isExternal = false;
            if (t == 'Id' && externalFields.contains(f)) isExternal = true;
            List<mappingWrapper> temp = new List<mappingWrapper>();
            temp.add(new mappingWrapper(null, t, f, isExternal));
            mappedFields.put(t, temp);
        }
        processedTargets.add(f);
        targetFields.remove(f);
    }
    public void setRtMapping() {
        /**Target Org Field**/
        String f = ApexPages.currentPage().getParameters().get('from');
        /**Source Org Field**/
        String t = ApexPages.currentPage().getParameters().get('to');
        if (sourceRecordTypes.containsKey(t) && sourceRecordTypes.get(t) != null && targetRecordTypes.containsKey(f) && targetRecordTypes.get(f) != null) {
            if (recordtypeMapping.containsKey(sourceRecordTypes.get(t).DeveloperName)) {
                List<recordTypeMappingWrapper> temp = recordtypeMapping.get(sourceRecordTypes.get(t).DeveloperName);
                temp.add(new recordTypeMappingWrapper(null, sourceRecordTypes.get(t).DeveloperName, t, targetRecordTypes.get(f).DeveloperName, f ));
                recordtypeMapping.put(sourceRecordTypes.get(t).DeveloperName, temp);
            } else {
                List<recordTypeMappingWrapper> temp = new List<recordTypeMappingWrapper>();
                temp.add(new recordTypeMappingWrapper(null, sourceRecordTypes.get(t).DeveloperName, t, targetRecordTypes.get(f).DeveloperName, f ));
                recordtypeMapping.put(sourceRecordTypes.get(t).DeveloperName, temp);
            }
            sourceRecordTypes.remove(t);
        }
    }
    public void resetMapping() {
        mappedFields = new Map<String, List<mappingWrapper>>();
        mappedFields.putAll(mappedFieldsState);
        Set<String> targetState = new Set<String>();
        for (String msk : mappedFieldsState.keySet()) {
            for (mappingWrapper msw : mappedFieldsState.get(msk)) {
                targetState.add(msw.targetField);
            }
        }
        targetFields.clear();
        for (String f : targetFieldsState.keySet()) {
            if (!targetState.contains(f)) {
                targetFields.put(f, targetFieldsState.get(f));
            }
        }
    }
    public void SaveState() {
        List<Migration_Rule_Mapping__c> newMappings = new List<Migration_Rule_Mapping__c>();
        for (String f : mappedFields.keySet()) {
            for (mappingWrapper mw : mappedFields.get(f)) {
                if (mw.mId == null && String.isBlank(mw.mValue) ) {
                    Migration_Rule_Mapping__c mrp = new Migration_Rule_Mapping__c(
                        Source_Field__c = mw.sourceField,
                        Target_Field__c = mw.targetField,
                        Migration_Type__c = 'Field from Source',
                        Migration_Rule__c = mysObject.Id,
                        Destination_Org__c = setting.Id,
                        Is_ID_Field__c = mw.isExternal
                    );
                    newMappings.add(mrp);
                } else if (mw.mId == null && !String.isBlank(mw.mValue)) {
                    Migration_Rule_Mapping__c mrp = new Migration_Rule_Mapping__c(
                        Source_Field__c = null,
                        Manuel_Entry_Value__c = mw.mValue,
                        Target_Field__c = mw.targetField,
                        Migration_Type__c = 'Manuel Entry',
                        Migration_Rule__c = mysObject.Id,
                        Destination_Org__c = setting.Id,
                        Is_ID_Field__c = false
                    );
                    newMappings.add(mrp);
                }
            }
        }
        if (!newMappings.isEmpty()) {
            insert newMappings;
            mappedFields.clear();
            for (Migration_Rule_Mapping__c mrp : [SELECT Source_Field__c, Target_Field__c, Source_Object__c, Migration_Type__c, Migration_Rule__c, Destination_Org__c, Is_ID_Field__c FROM Migration_Rule_Mapping__c WHERE Migration_Rule__c = : mysObject.Id AND Destination_Org__c = :setting.Id]) {
                if (mappedFields.containsKey(mrp.Source_Field__c)) {
                    List<mappingWrapper> temp = mappedFields.get(mrp.Source_Field__c);
                    temp.add(new mappingWrapper(mrp.id, mrp.Source_Field__c, mrp.Target_Field__c, mrp.Is_ID_Field__c));
                    mappedFields.put(mrp.Source_Field__c, temp);
                } else {
                    List<mappingWrapper> temp = new List<mappingWrapper>();
                    temp.add(new mappingWrapper(mrp.id, mrp.Source_Field__c, mrp.Target_Field__c, mrp.Is_ID_Field__c));
                    mappedFields.put(mrp.Source_Field__c, temp);
                }
            }
            mappedFieldsState.clear();
            mappedFieldsState.putAll(mappedFields);
        }
    }
    public void saveRecordTypeMapping() {
        List<RecordType_Mapping__c> newMappings = new List<RecordType_Mapping__c>();
        for (String rtm : RecordTypeMapping.keySet()) {
            for (recordTypeMappingWrapper rtw : RecordTypeMapping.get(rtm)) {
                if (rtw.mId == null) {
                    RecordType_Mapping__c rt = new RecordType_Mapping__c(
                        Source_RecordType_Name__c = rtw.sourceName,
                        Destination_RecordType_Name__c = rtw.targetName,
                        Migration_Rule__c = mysObject.Id,
                        Org_Credential__c = setting.Id
                    );
                    newMappings.add(rt);
                }
            }
        }
        if (!newMappings.isEmpty()) {
            insert newMappings;
        }
    }
    public void autoMapping() {
        for (String sf : sourceFields.keySet()) {
            if (targetFields.containsKey(sf)) {
                Boolean isExternal = false;
                if (sf == 'Id' && externalFields.contains(sf)) isExternal = true;
                if (mappedFields.containsKey(sf)) {
                    List<mappingWrapper> temp = mappedFields.get(sf);
                    temp.add(new mappingWrapper(null, sf, sf, isExternal));
                    mappedFields.put(sf, temp);
                } else {
                    List<mappingWrapper> temp = new List<mappingWrapper>();
                    temp.add(new mappingWrapper(null, sf, sf, isExternal));
                    mappedFields.put(sf, temp);
                }
                processedTargets.add(sf);
                targetFields.remove(sf);
            }
        }
    }
    public void closeModal() {
        manualValue = '';
    }
    public void clearAll() {
        List<Migration_Rule_Mapping__c> delList = new List<Migration_Rule_Mapping__c>();
        for (String mf : mappedFields.keySet()) {
            for (mappingWrapper mw : mappedFields.get(mf)) {
                if (mw.mId !=  null) {
                    Migration_Rule_Mapping__c del = new Migration_Rule_Mapping__c(
                        Id = mw.mId
                    );
                    delList.add(del);
                }
            }
        }
        if (!delList.isEmpty()) {
            database.delete(delList, false);
        }
        mappedFields = new Map<String, List<mappingWrapper>>();
        mappedFieldsState = new Map<String, List<mappingWrapper>>();
        targetFields.clear();
        processedTargets.clear();
        targetFields.putAll(targetFieldsState);
    }
    public void saveManualValue() {
        String f = ApexPages.currentPage().getParameters().get('manualField');
        manualValue = ApexPages.currentPage().getParameters().get('manualVal');
        System.debug(loggingLevel.Error, '*** f: ' + f);
        System.debug(loggingLevel.Error, '*** manualValue: ' + manualValue);
        if (!String.isBlank(manualValue)) {
            if (mappedFields.containsKey(manualValue)) {
                List<mappingWrapper> temp = mappedFields.get(manualValue);
                temp.add(new mappingWrapper(null, f, manualValue));
                mappedFields.put(manualValue, temp);
            } else {
                List<mappingWrapper> temp = new List<mappingWrapper>();
                temp.add(new mappingWrapper(null, f, manualValue));
                mappedFields.put(manualValue, temp);
            }
            manualValue = '';
            targetFields.remove(f);
        }
    }
    public void remove() {
        String sourceField = ApexPages.currentPage().getParameters().get('sourceField');
        Integer order = Integer.valueOf(ApexPages.currentPage().getParameters().get('order'));
        if (mappedFields.containsKey(sourceField)) {
            mappingWrapper temp = mappedFields.get(sourceField)[order];
            targetFields.put(temp.targetField, fullList.get(temp.targetField));
            processedTargets.remove(temp.targetField);
            if (temp.mId != null) {
                Migration_Rule_Mapping__c del = new Migration_Rule_Mapping__c(
                    Id = temp.mId
                );
                database.delete(del);
            }
            mappedFields.get(sourceField).remove(order);
        }
    }
    public void removeRT() {
        String sourceField = ApexPages.currentPage().getParameters().get('sourceField');
        Integer order = Integer.valueOf(ApexPages.currentPage().getParameters().get('order'));
        System.debug(loggingLevel.Error, '*** sourceField: ' + sourceField);
        if (recordtypeMapping.containsKey(sourceField)) {
            recordTypeMappingWrapper temp = recordtypeMapping.get(sourceField)[order];
            if (temp.mId != null) {
                RecordType_Mapping__c del = new RecordType_Mapping__c(
                    Id = temp.mId
                );
                database.delete(del, false);
                //sourceRecordTypes.put(temp.mId,allSourceRT.get(temp.mId));
            }
            RecordType sourceType = RecordTypes.getRtByName(sourceField, allSourceRT);
            System.debug(loggingLevel.Error, '*** sourceType: ' + sourceType);
            if (sourceType != null) {
                sourceRecordTypes.put(sourceType.Id, sourceType);
            }
            recordtypeMapping.get(sourceField).remove(order);
        }
    }
    public void setRTWrapperforTest(String mId, String sourceName, Id sourceId, String targetName, Id targetId){
        recordTypeMappingWrapper mock = new recordTypeMappingWrapper(mId,sourceName,sourceId,targetName,targetId);
    }
    public class recordTypeMappingWrapper {
        public String mId {get; set;}
        public String sourceName {get; set;}
        public Id sourceId {get; set;}
        public String targetName {get; set;}
        public Id targetId {get; set;}
        public recordTypeMappingWrapper(String mId, String sourceName, Id sourceId, String targetName, Id targetId) {
            this.mId = mId;
            this.sourceName = sourceName;
            this.sourceId = sourceId;
            this.targetName = targetName;
            this.targetId = targetId;
        }
    }
    public class mappingWrapper {
        public String mId {get; set;}
        public String sourceField {get; set;}
        public String targetField {get; set;}
        public Boolean isExternal {get; set;}
        public String mValue {get; set;}
        public mappingWrapper(String mId, String sourceField, String targetField, Boolean isExternal) {
            this.mId = mId;
            this.sourceField = sourceField;
            this.targetField = targetField;
            this.mValue = null;
            this.isExternal = isExternal;
        }
        public mappingWrapper(String mId, String targetField, String mValue) {
            this.mId = mId;
            this.sourceField = null;
            this.targetField = targetField;
            this.mValue = mValue;
            this.isExternal = isExternal;
        }

    }
}