/**********************************************************************
* Name:     SG_BizDate_CalcWorkDays_Wrapper
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


public class SG_BizDate_CalcWorkDays_Wrapper implements SG_BusinessDateWrapper{

	@InvocableVariable
	public String Record_Id;

	@InvocableVariable
	public Date Date_Value;

	@InvocableVariable
	public Date DateTime_Value;

	@InvocableVariable
	public String Field_API_Name;

	@InvocableVariable
	public String Number_of_Business_Days;

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
		Integer theInt = 0;
		try
		{
			theInt = Integer.valueOf( Number_of_Business_Days );
		}
		catch (Exception e)
		{
			System.debug(LoggingLevel.WARN, '---> message, stacktrace: ' + e.getMessage() + ' ' + e.getStackTraceString() );
		}

		return theInt;
	}


}