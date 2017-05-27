/**
 * @author Mert YALTI
 * @date 02/06/2017
 * Wrapper model for migration results
 * In use to parse transaction result JSON
 * In use to create transaction result JSON
 */
public with sharing class TransportResultWrapper {
	public String objectName {get;set;}
	public String idFromTarget {get; set;}
	public String status {get; set;}
	public String errorMessage {get;set;}
	public Boolean isCreated {get;set;}
	/**
	 * Constructor
	 * @param  o   ObjectName
	 * @param  ift Id from the target org
	 * @param  s   Status
	 * @param  e   Error message (If applicable, else null)
	 * @param  c   States if the new record is created or not
	 * @return     void
	 */
	public TransportResultWrapper(String o, String ift, String s, String e, Boolean c) {
		this.objectName = o;
		this.idFromTarget = ift;
		this.status = s;
		this.errorMessage = e;
		this.isCreated = c;
	}

}