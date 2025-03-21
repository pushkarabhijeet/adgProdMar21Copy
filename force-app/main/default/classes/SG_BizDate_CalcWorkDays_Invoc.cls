/**********************************************************************
* Name:     SG_BizDate_CalcWorkDays_Invoc
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


public class SG_BizDate_CalcWorkDays_Invoc {

	private static List<sObject> updateList;

	@InvocableMethod(label='Set to XX Biz Days in Future/Past' description='Given a Date or DateTime, add/subtract business days. Use the date_value variable for Dates; use dateTime_value for DateTimes.')
	public static void setCalculatedWorkDate( List<SG_BizDate_CalcWorkDays_Wrapper> dates )
	{
		System.debug(LoggingLevel.WARN, '---> start setCalculatedWorkDate');


		if ( dates != null && dates.size() > 0 )
		{
			updateList = new List<SObject>();
			for ( SG_BizDate_CalcWorkDays_Wrapper wrapper : dates )
			{
				DateTime dt;
				System.debug(LoggingLevel.WARN, '---> looping date: ' + wrapper );

				System.debug(LoggingLevel.WARN, '---> wrapper.date_value: ' + wrapper.date_value);
				if ( wrapper.date_value != null )
				{
					// using a DATE field
					// convert to a DateTime...
					// TODO: is midnight a good time? Or something that would be in normal business hours like 8:00 AM?
					// take our date and make a new DateTime for :01 past midnight of the date
					Time t = Time.newInstance( 00, 01, 00, 00);
					dt = DateTime.newInstance( wrapper.date_value, t);
				}
				else
				{
					// using a DATETIME field
					System.debug(LoggingLevel.WARN, '---> using incoming dateTime: ' + wrapper.dateTime_value);
					dt = wrapper.dateTime_value;
				}

				System.debug(LoggingLevel.WARN, '---> dateTime: ' + dt);
				Integer bizDays = 0;
				if ( String.isNotBlank( wrapper.number_of_business_days))
				{
					try
					{
						bizDays = Integer.valueOf( wrapper.number_of_business_days );
					}
					catch (Exception e )
					{
						System.debug(LoggingLevel.WARN, '---> message, stacktrace: ' + e.getMessage() + ' ' + e.getStackTraceString() );
					}
				}

				dt = SG_BusinessDateUtils.getCalculatedBizDate( dt, bizDays );

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