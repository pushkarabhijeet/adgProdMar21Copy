/**********************************************************************
* Name:   	SG_TestDataGenerator
* Author: 	Strategic Growth, Inc. (www.strategicgrowthinc.com)
* Date: 	2009
* ======================================================
* ======================================================
* Purpose:                                                            
* This class is used to create test data. It is virtual so that it can be extended
*                                                            
* ======================================================
* ======================================================
* History:                                                            
* VERSION	DATE            INITIALS	DESCRIPTION/FEATURES ADDED
* 1.0     	2009	        CS			Initial Development           
*   
***********************************************************************/

public virtual class SG_TestDataGenerator 
{
    //Always allow for the creation of one or more users
    private List<User> users;
    private Map<String,List<User>> profileToUserMap;    
    
    private List<Lead> leads;    
    private List<Account> accounts;    
    private List<Contact> contacts;     
    private List<Opportunity> opportunities;       
	private Pricebook2 pricebook;
    private List<Product2> products;
    private List<PricebookEntry> pricebookEntries;
    private List<OpportunityLineItem> opportunityLineItems;
    private List<Project_Location_GEO__c> geos;
    private List<Asset> assets;
      
    public Integer leadNum;
    public Integer accountNum;
    public Integer contactNum;
    public Integer opptyNum;
	public Integer opptyLineItemNum;
    public Integer productNum;
    public Integer pricebookEntryNum;
    public Integer assetNum;

    
    public Integer userNum;

    public static Pricebook2 stdPB {
        get {
            if( stdPB == null ) {
                // if you just use standardPBId without doing the update below,
                // there is a risk that the pricebook entries will not created properly
                Id standardPBId = Test.getStandardPricebookId();

                stdPB = new Pricebook2();
                stdPB.ID = standardPBId;
                stdPB.IsActive = true;
                update stdPB;
            }

            return stdPB;
        }
        set;
    }

    public SG_TestDataGenerator()
    {
    	userNum = 2;
      	accountNum = 10;
	    contactNum = 20;
	    opptyNum = 20;	    
	    leadNum = 20;
	    opptyLineItemNum = opptyNum * 2;
	    productNum = Math.max(10,opptyLineItemNum);
	    pricebookEntryNum = productNum;
        assetNum = 1;
    }
    
    public Map<String,List<User>> getProfileToUserMap(List<String> profileNames) {
        System.debug('@@@SG: getProfileToUserMap');
        getUsers(profileNames);
        return profileToUserMap;
    }
    
    //A user needs a profile
    public List<User> getUsers(List<String> profileNames){
        System.debug('@@@SG: getUsers');
        if(users == null) {
            users = new List<User>();
            
            //There are 3 classes of users, create at least one of each
            if(profileNames == null || profileNames.size() == 0) {
                profileNames = new List<String>();
                profileNames.add('Standard User');      
            }
            
            System.debug('@@@SG: profileNames: ' + profileNames);
            
            Map<Id,Profile> profileMap;         
            try {       
                profileMap = new Map<Id,Profile>([select id, Name from profile where name IN :profileNames]);
            } catch (Exception exp) {
                //Can not test exceptions
                System.debug('@@@SG: Could not find profiles: ' + exp.getMessage());               
            }
            
            if(profileMap == null || profileMap.size() == 0) {
                profileMap = new Map<Id,Profile>([select id, Name from profile where name = 'Standard User']);
            }
            
            System.debug('@@@SG: profileMap: ' + profileMap);
            
            //Untested - this should never happen, just 3x checking
            if(profileMap == null || profileMap.size() == 0) {
                System.assert(false,'Could not find profiles');
                return null;
            }
                                    
            if(userNum == null || userNum < profileMap.size()) {
                userNum = profileMap.size();
            }
                    
            for(Integer i = 0; i < userNum; i++) {
                Integer profilePosition = Math.mod(i,profileMap.size());
                Integer random = Math.random().intValue();
                User u = getUser(profileMap.values()[profilePosition], 'User' + i.format() + random.format());
                users.add(u);                       
            }
            
            System.debug('@@@SG: inserting users');
            insert users;
            
            //Now build the user map
            profileToUserMap = new Map<String,List<User>>();
            
            for(User u : users) {
                if(profileToUserMap.containsKey(profileMap.get(u.ProfileId).Name)) {
                    profileToUserMap.get(profileMap.get(u.ProfileId).Name).add(u);
                } else {
                    List<User> tmpUsers = new List<User>();
                    tmpUsers.add(u);
                    profileToUserMap.put(profileMap.get(u.ProfileId).Name,tmpUsers);
                }
            }
        }       
        return users;
    }
           
    private User getUser(Profile p, String uniqueName){
        System.debug('@@@SG: getUser');
                
        String orgId = (String)Userinfo.getOrganizationId();        
        String uniqueEmail = uniqueName + '@' + orgId + '.net.test';
        
        User u = new User(alias = 'standt', 
                          email=uniqueEmail,
                          emailencodingkey='UTF-8', 
                          lastname='Testing', 
                          languagelocalekey='en_US',
                          localesidkey='en_US', 
                          profileid = p.Id,
                          timezonesidkey='America/Los_Angeles',
                          username=uniqueEmail);
        return u;
    }
    
    public Id getParentId(List<SObject> objects, Integer i)
    {
    	Integer j = Math.mod(i,objects.size());
        SObject obj = objects[j];
        if(obj != null)
        {
        	return (Id)obj.get('Id');
        }
        return null;
    }
     
    public List<Account> getAccounts(Boolean xCommit) 
    {
        if(accounts == null) {
            accounts = new List<Account>();
            for(Integer i = 0; i < accountNum; i++) {
                Account a = new Account();
                a.Name = 'Test ' + i; 
                a.BillingStreet = '1 Main St';                  
		        a.BillingCity = 'Austin';
		        a.BillingCountryCode = 'US';
		        a.BillingStateCode = 'TX';
		        a.BillingPostalCode = '78731';
		        
		        a.ShippingStreet = '1 Main St';
		        a.ShippingCity = 'Austin';
		        a.ShippingCountryCode = 'US';
		        a.ShippingStateCode = 'TX';
		        a.ShippingPostalCode = '78731';
				a.NumberOfEmployees = 0;
                                          
                accounts.add(a);
                
            }
            if(xCommit) insert accounts;
        }
        
        if(xCommit && accounts.size() > 0 && accounts[0].Id == null) insert accounts;                               
        
        return accounts;
    }
            
    public List<Contact> getContacts(Boolean xCommit) {
        if(contacts == null) {
            contacts = new List<Contact>();
            for(Integer i = 0; i < contactNum; i++) {
                Contact c = new Contact();
                c.FirstName = 'First ' + i;
                c.LastName = 'Last ' + i;
                c.Email = 'First.Last@fake.com.' + i;                              
                c.AccountId = getParentId(getAccounts(true),i);

				try
				{
					//((SObject)c).put('Unit_Contact__c',1);
				}
				catch(Exception exp)
				{
					//Ignore if fields aren't there
				}

                contacts.add(c);
            }
            if(xCommit) insert contacts;
        }
        
        if(xCommit && contacts.size() > 0 && contacts[0].Id == null) insert contacts;
        
        return contacts;
    }    
    
    public List<Opportunity> getOpportunities(Boolean xCommit, Id pricebookId)
    {
    	if(opportunities == null) {
            opportunities = new List<Opportunity>();
            for(Integer i = 0; i < opptyNum; i++) {
                Opportunity o = new Opportunity();
                o.Name = 'Test ' + i;
                o.CloseDate = Date.today().addDays(1);
                o.StageName = 'Prospecting';
                o.AccountId = getParentId(getAccounts(true),i);
                if(pricebookId != null)
                {
                	o.Pricebook2Id = pricebookId;
                }
                                
                opportunities.add(o);
            }
            if(xCommit) insert opportunities;
        }
        
        if(xCommit && opportunities.size() > 0 && opportunities[0].Id == null) insert opportunities;
        
        return opportunities;
    }
        
    public List<Opportunity> getOpportunities(Boolean xCommit) {
        return getOpportunities(xCommit, null);
    }
    
    public List<Product2> getProducts(Boolean xCommit) {
        if(products == null) {
            products = new List<Product2>();
            for(Integer i = 0; i < productNum; i++) {
                Product2 p = new Product2();
                p.IsActive = true;
                p.Name = 'Test Product ' + i;
                p.ProductCode = 'TestPCode ' + i; 
                products.add(p);
            }
            if(xCommit) insert products;
        }
        
        if(xCommit && products.size() > 0 && products[0].Id == null) insert products;           
        
        return products;
    }
    
    public Pricebook2 getPricebook(Boolean xCommit) {
        if(pricebook == null) {        	
            pricebook = new Pricebook2();
            pricebook.IsActive = true;
            pricebook.Name = 'Test Pricebook';
            if(xCommit) insert pricebook;
        }
        
        if(xCommit && pricebook.Id == null) insert pricebook;                   
        
        return pricebook;
    }
    
    public List<PricebookEntry> getPricebookEntries(Boolean xCommit) {
        if(pricebookEntries == null) {
            pricebookEntries = new List<PricebookEntry>();
            List<PricebookEntry> stdPricebookEntries = new List<PricebookEntry>();

            // there is no need to use Test.getStandardPricebookId()
            // if you just use getStandardPricebookId without updating the PB to active,
            // there is a risk that the pricebook entries will not created properly
            Id standardPBId = stdPB.ID;

            for(Integer i = 0; i < pricebookEntryNum; i++) {
                PricebookEntry pbeStd = new PricebookEntry();
                pbeStd.IsActive = true;
                pbeStd.Pricebook2Id = standardPBId;
                System.assertNotEquals(null, pbeStd.Pricebook2Id,standardPBId);
                
                Integer j = Math.mod(i, getProducts(true).size());
                pbeStd.Product2Id = getProducts(true)[j].Id;
                System.assertNotEquals(null, pbeStd.Product2Id,getProducts(true)[j]);
                
                pbeStd.UnitPrice = i;
                pbeStd.UseStandardPrice = false;
                stdPricebookEntries.add(pbeStd);
                
                PricebookEntry pbe = new PricebookEntry();
                pbe.IsActive = true;
                pbe.Pricebook2Id = getPricebook(true).Id;
                System.assertNotEquals(null, pbe.Pricebook2Id,getPricebook(true));
                                
                pbe.Product2Id = pbeStd.Product2Id;
                System.assertNotEquals(null, pbe.Product2Id,pbeStd);
                
                pbe.UnitPrice = i;
                pbe.UseStandardPrice = false;
                pricebookEntries.add(pbe);
            }
            insert stdPricebookEntries;
            if(xCommit) insert pricebookEntries;
        }
        
        if(xCommit && pricebookEntries.size() > 0 && pricebookEntries[0].Id == null) insert pricebookEntries;       
        
        return pricebookEntries;
    }
    
   /* public List<OpportunityLineItem> getOpportunityLineItems(Boolean xCommit) {
        if(opportunityLineItems == null) {
            opportunityLineItems = new List<OpportunityLineItem>();
            for(Integer i = 0; i < opptyLineItemNum; i++) {
                OpportunityLineItem oli = new OpportunityLineItem();
                
                Integer j = Math.mod(i,getOpportunities(true).size());
                oli.OpportunityId = getOpportunities(true,getPricebook(true).Id)[j].Id;
                
                Integer k = Math.mod(i,getPricebookEntries(true).size());               
                oli.PricebookEntryId = getPricebookEntries(true)[k].Id;
                
                oli.Quantity = i + 1;
                
                oli.UnitPrice = getPricebookEntries(true)[k].UnitPrice;
                            
                opportunityLineItems.add(oli);              
            }
            if(xCommit) insert opportunityLineItems;
        }
        
        if(xCommit && opportunityLineItems.size() > 0 && opportunityLineItems[0].Id == null) insert opportunityLineItems;
                
        return opportunityLineItems;
    }*/
    
    public List<Lead> getLeads(Boolean xCommit) {
        if(leads == null) {
            leads = new List<Lead>();
            for(Integer i = 0; i < leadNum; i++) {
                Lead l = new Lead();
                l.FirstName = 'First ' + i;
                l.LastName = 'Last ' + i;
                l.Email = 'email' + i + '@test.com';
                
                Integer j = Math.mod(i,getAccounts(true).size());
                Account a = getAccounts(true)[j];               
                l.Company = a.Name;
                              
                leads.add(l);
            }
            if(xCommit) insert leads;
        }
        
        if(xCommit && leads.size() > 0 && leads[0].Id == null) insert leads;
        
        return leads;
    }

    public List<Asset> getAssets(Boolean xCommit) {
        System.debug(LoggingLevel.WARN, '---> start getAssets in TD');
        if(assets == null) {
            System.debug(LoggingLevel.WARN, '---> initializing asset list');
            assets = new List<Asset>();
            Community__c aCommunity = new Community__c();
            aCommunity.Name = 'Someone\'s community';
            aCommunity.EntityIntegration__c = 'ABC_123:';
            aCommunity.Builder__c = getAccounts(true)[0].id;
            insert aCommunity;

            for(Integer i = 0; i < assetNum; i++) {
                Asset a = new Asset();
                a.Name = i + ' St';
                a.Lot_Block__c =  i + ' St';

                Integer j = Math.mod(i,getAccounts(true).size());
                Account acct = getAccounts(true)[j];

                a.AccountID = acct.ID;
                a.Community__c = aCommunity.ID;
               // a.Field_Service_Manager__c = aResource.ID;
                //anAsset.ContactID = aCustomer.ID;
                a.Status = 'Pre-Start';
                a.Integration_Key_Billing_Group__c = 'TEST123';
                a.PrimaryIdentifier__c = 'ID-TEST123';

                assets.add(a);
            }
            if(xCommit) insert assets;
        }

        if(xCommit && assets.size() > 0 && assets[0].Id == null) insert assets;

        return assets;
    }


    public List<Project_Location_GEO__c> getGeos(Boolean xCommit )
    {
        if ( geos == null )
        {
            geos = new List<Project_Location_GEO__c>();
            Project_Location_GEO__c geo = new Project_Location_GEO__c();
            geo.Name = '01001';
            geo.Lat__c = 42.06258;
            geo.Long__c = -72.62590;
            geo.City__c = 'Agawam';
            geo.State_Abbr__c = 'MA';
            geo.State_Name__c = 'Massachusetts';
            geo.County_Name__c = 'Hampden';
            geo.Time_Zone__c = 'America/New_York';
            geos.add( geo );

            Project_Location_GEO__c geo1 = new Project_Location_GEO__c();
            geo1.Name = '01002';
            geo1.Lat__c = 42.37492;
            geo1.Long__c = -72.46210;
            geo1.City__c = 'Amherst';
            geo1.State_Abbr__c = 'MA';
            geo1.State_Name__c = 'Massachusetts';
            geo1.County_Name__c = 'Hampshire';
            geo1.Time_Zone__c = 'America/New_York';
            geos.add( geo1 );

            if(xCommit) insert geos;
        }
        if(xCommit && geos.size() > 0 && geos[0].Id == null) insert geos;

        return geos;
    }
     
    public virtual void initAllTestData() {
        getUsers(null);
        getLeads(true);
        getAccounts(true);
        getContacts(true);
        getOpportunities(true);        
        getPricebook(true);
		getProducts(true);
		//getOpportunityLineItems(true);
        getAssets(true);
    }  
	
}