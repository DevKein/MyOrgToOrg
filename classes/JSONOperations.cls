public with sharing class JSONOperations {
        public static String generateExternalJSON(Map<String, List<sObject>> dataSet, Map<Integer, String> priorityMap, Map<String, Boolean> selfRelation, Map<String, Map<String, String>> externalMapping, Map<String, Map<String, String>> sourceFields, Map<String, String> sourceToTarget, Integer orderNo,Map<String, Map<Id, String>> rtMappings) {
                JSONModel jm = new JSONModel();
                Map<String, List<sObject>> temp = new Map<String, List<sObject>>();
                temp.put(priorityMap.get(orderNo),dataSet.get(priorityMap.get(orderNo)));
                jm.dataset = temp;
                jm.priorityMap = priorityMap;
                jm.selfRelation = selfRelation;
                jm.externalMappings = externalMapping;
                jm.sourceFields = sourceFields;
                jm.sourceToTarget = sourceToTarget;
                jm.orderNo = orderNo;
                jm.rtMappings = rtMappings;
                return JSON.serialize(jm, true);
        }
}