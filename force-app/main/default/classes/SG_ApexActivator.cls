/**********************************************************************
* Name:   	ApexActivator
* Author: 	Strategic Growth, Inc. (www.strategicgrowthinc.com)
* Date: 	04 MAR 2013
* ======================================================
* ======================================================
* Purpose: The purpose of this class is to help turn triggers on and off, if they subscribe to the custom setting                                                           
* 
* ======================================================
* ======================================================
* History:                                                            
* VERSION	DATE            INITIALS	DESCRIPTION/FEATURES ADDED
* 1.0     	04 MAR 2013     CS			Initial Development           
*   
***********************************************************************/


/* USAGE

	if(SG_ApexActivator.isDisabled('Disable Quote Triggers')
	{
		System.debug('Trigger disabled by Apex Activation Settings Custom Setting.');
		return;
	}

 */

public without sharing class SG_ApexActivator
{
	//Defaults to false
	public static Boolean isDisabled(String disable_Trigger_FieldName)
	{
		Boolean isDisabled = false;
		if(disable_Trigger_FieldName != null)
		{
			try
			{
				//Ensure we have a valid custom field name
				if(!disable_Trigger_FieldName.endsWith('__c'))
				{
					disable_Trigger_FieldName += '__c';
				}
				
				//Ensure we have a valid custom field name				
				disable_Trigger_FieldName = disable_Trigger_FieldName.replaceAll(' ', '_');
				
				Apex_Activation_Settings__c settings = Apex_Activation_Settings__c.getInstance();					
				
				if (settings != null && settings.Disable_All_Registered_Triggers__c == true || (Boolean)((SObject)settings).get(disable_Trigger_FieldName) == true)
				{
					isDisabled = true;				
				} 	
			}
			catch(Exception exp)
			{
				//Ignore
				SG_DisplayUtils.debug('SG_ApexActivator', 'isDisabled', 'IGNORE EXCEPTION' + SG_DisplayUtils.exceptionToString('SG_ApexActivator', exp));
			}
		}
		
		return isDisabled;
	}

}