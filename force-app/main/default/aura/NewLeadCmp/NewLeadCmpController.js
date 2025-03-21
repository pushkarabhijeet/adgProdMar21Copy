/**********************************************************************
* Name:     NewLeadCmpController.js
* Author:   Strategic Growth, Inc. (www.strategicgrowthinc.com)
* 
* ======================================================
* ======================================================
* Purpose:                                                      
* 
* ======================================================
* ======================================================
* History:                                                            
* VERSION   DATE            INITIALS      DESCRIPTION/FEATURES ADDED
* 1.0       27-Mar-2020     rwd           Initial Development           
*   
***********************************************************************/
({
	doInit : function(component, event, helper) {
        console.log('---> start init');		
        //get record type Id
        var recordTypeId = component.get("v.pageReference").state.recordTypeId;
        component.set("v.selectedRecordId", recordTypeId);
        console.log('--> recordTypeId:' +recordTypeId);

        if ( recordTypeId == "0124T000000DPxNQAW")
        {
            console.log('---> forward to retail');
         	var urlEvent = $A.get("e.force:navigateToURL");
                urlEvent.setParams({
                     "url": "/apex/RetailLead"
                });
                urlEvent.fire();
            console.log('---> done');
        }
        else
        {
          console.log('---> forwarding to create');
         	var createRecordEvent = $A.get("e.force:createRecord");
            createRecordEvent.setParams({
                "entityApiName": "Lead",
                "recordTypeId": recordTypeId,
                'defaultFieldValues': {

                }
            });
            createRecordEvent.fire();
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();	     
        }
	}
    , reInit : function(component, event, helper) {
        console.log('---> start reInit');
        $A.get('e.force:refreshView').fire();
    }
})