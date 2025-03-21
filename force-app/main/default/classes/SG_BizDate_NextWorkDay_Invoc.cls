/**********************************************************************
* Name:     SG_BizDate_NextWorkDay_Invoc
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


public class SG_BizDate_NextWorkDay_Invoc {

	private static List<sObject> updateList;

	@InvocableMethod(label='Set to next Biz Day' description='If the target Date or DateTime does not fall on a business day, sets to the next business day.')
	public static void setNextWorkDate( List<SG_BizDate_NextWorkDay_Wrapper> dates )
	{
		System.debug(LoggingLevel.WARN, '---> start setNextWorkDate');
		if ( dates != null && dates.size() > 0 )
		{
			updateList = new List<SObject>();
			for ( SG_BizDate_NextWorkDay_Wrapper wrapper : dates )
			{
				DateTime dt;
				System.debug(LoggingLevel.WARN, '---> looping date: ' + wrapper );
				if ( wrapper.date_value != null )
				{
					// convert to a DateTime...
					// TODO: is midnight a good time? Or something that would be in normal business hours like 8:00 AM?
					// take our date and make a new DateTime for :01 past midnight of the date
					Time t = Time.newInstance( 00, 01, 00, 00);
					dt = DateTime.newInstance( wrapper.date_value, t);
				}
				else
				{
					System.debug(LoggingLevel.WARN, '---> using incoming dt: ' + wrapper.dateTime_value);
					dt = wrapper.dateTime_value;
				}

				dt = SG_BusinessDateUtils.getNextStartDate( dt );
				SG_BusinessDateUtils.addToUpdateList( wrapper, dt, updateList );
			}

			System.debug(LoggingLevel.WARN, '---> updateList: ' + updateList);
			if ( updateList != null && updateList.size() > 0 )
			{
				try
				{
					System.debug(LoggingLevel.WARN, '---> about to update the objects...');
					update updateList;
				}
				catch ( Exception e )
				{
					System.debug(LoggingLevel.WARN, '---> message, stacktrace: ' + e.getMessage() + ' ' + e.getStackTraceString() );
				}
			}
		}
	}

}