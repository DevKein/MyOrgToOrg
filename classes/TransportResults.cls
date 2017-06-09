/**
 * @author Mert YALTI
 * @date 02/06/2017
 * Transaction results acceptor
 * @version 1.0
 */
public with sharing class TransportResults {
    public Map<String,List<TransportResultWrapper>> JSONWrapper {get;set;}
}