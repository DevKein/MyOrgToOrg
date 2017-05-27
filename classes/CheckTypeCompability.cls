global class CheckTypeCompability {
	global static Map<String, Set<String>> compatibleTypesMap = new Map<String, Set<String>>();
	static {
		compatibleTypesMap.put(SOAPType.String.Name(), new Set<String> {SOAPType.String.Name(), SOAPType.Boolean.Name(), SOAPType.ID.Name(), SOAPType.Integer.Name(), SOAPType.Double.Name(), SOAPType.Date.Name(),SOAPType.DateTime.Name(), SOAPType.Time.Name()});
		compatibleTypesMap.put(SOAPType.Boolean.Name(), new Set<String> {SOAPType.Boolean.Name(),SOAPType.String.Name()});
		compatibleTypesMap.put(SOAPType.Date.Name(), new Set<String> {SOAPType.Date.Name(),SOAPType.DateTime.Name()});
		compatibleTypesMap.put(SOAPType.DateTime.Name(), new Set<String> {SOAPType.DateTime.Name(),SOAPType.Date.Name()});
		compatibleTypesMap.put(SOAPType.Double.Name(), new Set<String> {SOAPType.Double.Name(),SOAPType.Integer.Name()});
		compatibleTypesMap.put(SOAPType.ID.Name(), new Set<String> {SOAPType.ID.Name(),SOAPType.String.Name()});
		compatibleTypesMap.put(SOAPType.Integer.Name(), new Set<String> {SOAPType.Integer.Name(),SOAPType.Double.Name()});
		compatibleTypesMap.put(SOAPType.Time.Name(), new Set<String> {SOAPType.Time.Name(),SOAPType.DateTime.Name()});
	}
	webservice static Boolean check(String source, String target){
		return (CheckTypeCompability.compatibleTypesMap.containsKey(source.toUpperCase()) && CheckTypeCompability.compatibleTypesMap.get(source.toUpperCase()).contains(target.toUpperCase())) ? true : false;
	}
}