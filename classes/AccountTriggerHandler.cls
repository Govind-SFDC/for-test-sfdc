public with sharing class AccountTriggerHandler extends TriggerHandler
{   
	///System.debug('test,.......'); 
    public AccountTriggerHandler(Boolean setReferenceIds) 
    {
        super(setReferenceIds);
    }
    
    public override void afterInsert() {
    	List<Account> newAccounts = (List<Account>) Trigger.new;
    	
    	Map<Id, String> newOrganizationAliasMap = new Map<Id, String>();
    	for (Account a : newAccounts) {
    		newOrganizationAliasMap.put(a.Id, a.Name);
    	}
    	
        addAliases(newOrganizationAliasMap);
    }
    
    public override void afterUpdate() {
        List<Account> newAccounts = (List<Account>) Trigger.new;
        Map<Id, Account> oldAccountMap = (Map<Id, Account>) Trigger.oldMap;
        
        Map<Id, String> newOrganizationAliasMap = new Map<Id, String>();
        for (Account aNew : newAccounts) {
        	Account aOld = oldAccountMap.get(aNew.Id);
        	if (aNew.Name != aOld.Name) {
	            newOrganizationAliasMap.put(aNew.Id, aNew.Name);
        	}
        }
        
        addAliases(newOrganizationAliasMap);
    }

    private void addAliases(Map<Id, String> newOrganizationAliasMap) {
    	Map<Id, Set<String>> organizationAliasesMap = new Map<Id, Set<String>>();
    	
    	// Load existing Aliases to see which ones we need to add
    	List<Organization_Alias__c> organizationAliases =
    	    [select Id,
    	            Organization__c,
    	            Organization_Alias__c
            from    Organization_Alias__c
            where   Organization__c in :newOrganizationAliasMap.keySet()];
        for (Organization_Alias__c oa : organizationAliases) {
        	Set<String> aliases = organizationAliasesMap.get(oa.Organization__c);
        	if (aliases == null) {
        		aliases = new Set<String>();
        		organizationAliasesMap.put(oa.Organization__c, aliases);
        	}
        	aliases.add(oa.Organization_Alias__c.toUpperCase());
        }
        
        List<Organization_Alias__c> newAliases = new List<Organization_Alias__c>();
        for (Id orgId : newOrganizationAliasMap.keySet()) {
        	String alias = newOrganizationAliasMap.get(orgId);
        	
        	Set<String> aliases = organizationAliasesMap.get(orgId);
        	if (aliases == null || !aliases.contains(alias.toUpperCase())) {
        		Organization_Alias__c newOrganizationAlias = new Organization_Alias__c();
        		newOrganizationAlias.Organization__c = orgId;
        		newOrganizationAlias.Organization_Alias__c = alias;
        		newAliases.add(newOrganizationAlias);
        	}
        }
        
        if (newAliases.size() > 0) {
        	//insert newAliases;
        	Database.SaveResult[] lsr = Database.insert(newAliases, false);

	        // Create counter
	        Integer i=0;
	        
	        // Process the save results
	        for(Database.SaveResult sr : lsr) {	        	
	            if(!sr.isSuccess()) {
	                // Get the first save result error
	                Database.Error err = sr.getErrors()[0];
	                // Check if the error is related to unique organization alias
	                if(err.getStatusCode() == StatusCode.DUPLICATE_VALUE && err.getMessage().contains('Organization_Alias__c')) {
	                    // Throw an error when the error is related to unique organization alias
	                    trigger.newMap.get(newAliases[i].Organization__c).addError(' Unable to add Alias : ' + err.getMessage());
	                }
	            }
	            i++;
	        }
        }
    }
}