/**********************************************************************
* Name:     SG_BusinessDateWrapper
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
* 1.0       15-Feb-2019     rwd           Initial Development           
*   
***********************************************************************/


public interface SG_BusinessDateWrapper {

	 String getRecord_Id();
	 Date getDate_Value();
	 DateTime getDateTime_Value();
	 String getField_Api_Name();
	 Integer getNumber_Of_Business_Days();


}