/**********************************************************************
* Name:     SG_BusinessDateUtils
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


public class SG_BusinessDateUtils {

	private static BusinessHours bh;

	public static void addToUpdateList(SG_BusinessDateWrapper wrapper, DateTime bizDate, List<sObject> updateList)
	{
		System.debug(LoggingLevel.WARN, '---> start addToUpdateList');
		System.debug(LoggingLevel.WARN, '---> incoming wrapper: ' + wrapper );
		// instantiate lists as needed...
		System.debug(LoggingLevel.WARN, '---> wrapper field api name: ' + wrapper.getField_Api_Name());
		if ( wrapper != null && String.isNotBlank( wrapper.getField_Api_Name() ))
		{
			if ( updateList == null ) updateList = new List<SObject>();

			if ( String.isNotBlank(wrapper.getRecord_Id() ) )
			{
				Id theId = wrapper.getRecord_Id();
				SObject obj = theId.getSObjectType().newSObject(theId);
				System.debug(LoggingLevel.WARN, '---> wrapper target date: ' + wrapper.getDate_Value() );
				if ( wrapper.getDate_Value() != null && bizDate != null)
				{
					System.debug(LoggingLevel.WARN, '---> converting dateTime back to date and setting on object');
					System.debug(LoggingLevel.WARN, '---> incoming bizDate: ' + bizDate);
					Date d = bizDate.date();
					System.debug(LoggingLevel.WARN, '---> date now: ' + d );
					obj.put( wrapper.getField_Api_Name(), d );
				}
				else
				{
					System.debug(LoggingLevel.WARN, '---> setting dateTime on object ');
					obj.put( wrapper.getField_Api_Name(), bizDate );
				}

				System.debug(LoggingLevel.WARN, '---> adding date or dateTime to updateList: ' + obj );
				updateList.add( obj );
			}
		}
		System.debug(LoggingLevel.WARN, '---> updateList is: ' + updateList );
	}


	public static DateTime getCalculatedBizDate( DateTime targetDateTime, Integer days )
	{
		System.debug(LoggingLevel.WARN, '---> start calculateBusinessDays');
		System.debug(LoggingLevel.WARN, '---> incoming targetDateTime: ' + targetDateTime);
		System.debug(LoggingLevel.WARN, '---> incoming days to add/subtract: ' + days );

		if (targetDateTime != null)
		{
			// get the default business hour...
			if (bh == null) getBusinessHours();

			Integer elapsed = 0;
			// need two forks - one for add, one for subtract...
			if ( days < 0 )
			{
				// SUBTRACT days

				System.debug(LoggingLevel.WARN, '---> Subtracting business days...');
				while (elapsed > days)
				{
					// first - add/subtract a day (keep doing it until we reach the correct number of days to calculate
					// then see if that day is an actual business day; if not add/subtract a business day; then repeat the cycle until complete

					targetDateTime = targetDateTime.addDays(-1);

					// need to get the PREVIOUS business date!
					Boolean isWithin = BusinessHours.isWithin(bh.Id, targetDateTime);

					if (isWithin)
					{
						// falls within bus date; simply reduce counter and continue
						elapsed--;
					}
					else
					{
						// does not fall within bus date - get the previous bus date and continue from there
						DateTime tmpDt = targetDateTime;
						System.debug(LoggingLevel.WARN, '---> finding previous business day');
						Integer ctr = 0;
						while ( !isWithin )
						{
							tmpDt = tmpDt.addDays( -1 );
							System.debug(LoggingLevel.WARN, '---> tmpDt now: ' + tmpDt );
							isWithin = BusinessHours.isWithin(bh.id, tmpDt );
							System.debug(LoggingLevel.WARN, '---> isWithin now: ' + isWithin );
							system.debug( 'isWithin now: ' + isWithin );

							ctr++;
							if ( ctr == 1000 )
							{
								// let's just make sure we never get into an Apex CPU problem...
								break;
							}
						}
						System.debug(LoggingLevel.WARN, '---> after while loop; tmpDt is: ' + tmpDt );
						targetDateTime = tmpDt;
						System.debug(LoggingLevel.WARN, '---> targetDateTime now set to tmpDt: ' + targetDateTime);

						// decrement the counter...
						elapsed--;
					}
				}
			}
			else
			{
				// ADD days
				System.debug(LoggingLevel.WARN, '---> adding buisness days');

				//if ( isInclusive ) days = days - 1;

				System.debug(LoggingLevel.WARN, '---> initial elapsed value: ' + elapsed);
				System.debug(LoggingLevel.WARN, '---> initial days: ' + days );
				System.debug(LoggingLevel.WARN, '---> initial targetDateTime: ' + targetDateTime );
				while (elapsed < days)
				{
					// first - add/subtract a day (keep doing it until we reach the correct number of days to calculate
					// then see if that day is an actual business day; if not add/subtract a business day; then repeat the cycle until complete
					targetDateTime = targetDateTime.addDays(1);
					System.debug(LoggingLevel.WARN, '---> elapsed in loop: ' + elapsed);
					System.debug(LoggingLevel.WARN, '---> targetDateTime in loop: ' + targetDateTime);

					if ( !BusinessHours.isWithin(bh.Id, targetDateTime) )
					{
						System.debug(LoggingLevel.WARN, '---> day is not a biz date - get the next business day to evaluate');
						// force targetDateTime to be the next business day and start counting from there...
						//targetDateTime = BusinessHours.nextStartDate(bh.Id, targetDateTime);
						targetDateTime = getNextStartDate( targetDateTime );

					}

					// increment the counter...
					elapsed++;
				}
			}

		}

		System.debug(LoggingLevel.WARN, '---> setting targetDateTime to: ' + targetDateTime );
		return targetDateTime;
	}

	public static DateTime getNextStartDate( DateTime targetDateTime )
	{
		System.debug(LoggingLevel.WARN, '---> start setNextStartDate');
		System.debug(LoggingLevel.WARN, '---> incoming targetDateTime: ' + targetDateTime);

		if (targetDateTime != null)
		{
			// get the default business hour...
			if (bh == null) getBusinessHours();
			System.debug(LoggingLevel.WARN, '---> bh is: ' + bh );

			// Starting from the targetDateTime, find the next date when business hours reopens. Return the target time.
			// if it is within the business hours. The returned time will be in the local time zone
			targetDateTime = BusinessHours.nextStartDate(bh.id, targetDateTime);
		}

		System.debug(LoggingLevel.WARN, '---> setting next work date: ' + targetDateTime );
		return targetDateTime;
	}

	public static BusinessHours getBusinessHours()
	{
		System.debug('---> start getBusinessHours');
		if ( bh == null )
		{
			bh = [SELECT Id FROM BusinessHours WHERE IsDefault=true AND isActive=true];
			if ( bh == null )
			{
				System.debug('----> no business hours found!!!');
			}
		}

		return bh;
	}


}