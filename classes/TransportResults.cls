/**
 * @author Mert YALTI
 * @date 02/06/2017
 * Transaction results acceptor
 */
public with sharing class TransportResults {
	public Map<String,List<TransportResultWrapper>> JSONWrapper {get;set;}
}