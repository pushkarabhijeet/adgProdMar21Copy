/**********************************************************************
* Name:     SG_BizDate_NextWorkDay_Wrapper
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
* 1.0       28-Jan-2019     rwd           Initial Development           
*   
***********************************************************************/


public class SG_BizDate_NextWorkDay_Wrapper implements SG_BusinessDateWrapper {

	@InvocableVariable
	public String Record_Id;

	@InvocableVariable
	public Date Date_Value;

	@InvocableVariable
	public Date DateTime_Value;

	@InvocableVariable
	public String Field_API_Name;


	public String getRecord_Id() {
		return Record_Id;
	}

	public Date getDate_Value() {
		return Date_Value;
	}
	public DateTime getDateTime_Value() {
		return DateTime_Value;
	}

	public String getField_Api_Name() {
		return Field_API_Name;
	}

	public Integer getNumber_of_Business_Days()
	{
		return null;
	}

}