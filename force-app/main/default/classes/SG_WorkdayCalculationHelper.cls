/***************************************************
* Name:         SG_WorkdayCalculationHelper
* Author:       Strategic Growth, Inc. (www.strategicgrowthinc.com)
* Date:         24 Nov 2020
* ==================================================
* ==================================================
* Purpose:      ...
*
* ==================================================
* ==================================================
* History:
* VERSION   DATE            INITIALS    DESCRIPTION/FEATURES ADDED
* 1.0       24 Nov 2020     FMF     Initial Development
* 
****************************************************/

public without sharing class SG_WorkdayCalculationHelper {

	public static BusinessHours orgsHours {
		get {
			if( orgsHours == null ) {
				orgsHours = [ SELECT ID, MondayStartTime, MondayEndTime
				FROM BusinessHours
				WHERE IsDefault = true
				AND IsActive = true ];
				system.debug( orgsHours );
			}
			return orgsHours;
		}
		set;
	}
	public static Decimal businessHoursPerDay {
		get {
			if( businessHoursPerDay == null ) {
				businessHoursPerDay = getBusinessHoursPerDay( orgsHours );
			}
			return businessHoursPerDay;
		}
		set;
	}
	public static Decimal getBusinessHoursPerDay( BusinessHours specificBusinessHours ) {
		// get number of work hours established for Monday and assume the rest of the week will be the same
		Long startMs = specificBusinessHours.MondayStartTime.second()
						+ specificBusinessHours.MondayStartTime.minute() * 60
						+ specificBusinessHours.MondayStartTime.hour() * 3600;
		Long endMs = specificBusinessHours.MondayEndTime.second()
						+ specificBusinessHours.MondayEndTime.minute() * 60
						+ specificBusinessHours.MondayEndTime.hour() * 3600;
		Decimal theBusinessHoursPerDay = ( endMs - startMs ) / 3600;
		system.debug( theBusinessHoursPerDay );
		return theBusinessHoursPerDay;
	}

	public static Map<Integer, DateTime> getWorkdayMap( DateTime aStartDt, Decimal nbrDays ) {
		return getWorkdayMap( orgsHours, aStartDt, nbrDays );
	}

	public static Map<Integer, DateTime> getWorkdayMap( BusinessHours specificBusinessHours
			, DateTime aStartDt, Decimal nbrDays ) {
		// returns a map like this:
		//  1 => aStartDt + 1 business day
		//  2 => aStartDt + 2 business days
		// ... and so forth up to ...
		// nbrDays => aStartDt + nbrDays business days

		// this uses Salesforce standard workdays calculation using the BusinessHours object
		// and returns a map of dates indexed by the number of workdays after the aStartDt
		// this should help optimize repeated workday calculations

		system.debug( 'Start Dt= ' + aStartDt );

		if( nbrDays == 0 ) {
			return null;
		}

		Map<Integer, DateTime> workdayMap = new Map<Integer, DateTime>();

		//Datetime businessStartDt = getBusinessStartDt( aStartDt );
		Datetime businessStartDt = getBusinessStartDtWithNoGMT(
										specificBusinessHours, aStartDt );
		Time endBusinessTime = specificBusinessHours.MondayEndTime;

		// initial date will be at zero business days
		workdayMap.put( 0, businessStartDt );

		// get number of ms in 1 workday
		Long millisecondsInAWorkday = getMillisecondsInWorkdays( specificBusinessHours, 1 );

		// prepare loop depending on the direction forward/backward we need to go in the calendar
		Integer dayCount = 1;
		Decimal totalDays = nbrDays;
		if( nbrDays < 0 ) {
			millisecondsInAWorkday = - millisecondsInAWorkday;
			totalDays = - nbrDays;
			dayCount = 1;
			//dayCount = 2;
		}

		// add (or subtract) day by day and store the calculated workday in the map
		for( ; dayCount <= totalDays; dayCount++ ) {
			system.debug( 'Day #' + dayCount );

			businessStartDt = addTimeToWorkday( specificBusinessHours, businessStartDt
									, millisecondsInAWorkday, endBusinessTime );

			// store the date in the map
			Integer dayIndex = dayCount;
			if( nbrDays < 0 ) {
				dayIndex = - dayIndex;
			}
			workdayMap.put( dayIndex, businessStartDt );
		}

		system.debug( workdayMap );

		return workdayMap;
	}

	public static Long getMillisecondsInWorkdays( BusinessHours specificBusinessHours
					, Decimal nbrDays ) {
		// need to use string because there is no other way to convert to long
		String hoursInAWorkday = ( nbrDays * getBusinessHoursPerDay( specificBusinessHours ) ).format();

		// 3,600,000 miliseconds in an hour
		Long millisecondsInAWorkday = Long.valueOf( hoursInAWorkday ) * 3600000;

		return millisecondsInAWorkday;
	}

	public static DateTime addTimeToWorkday( DateTime businessStartDt
			, Long millisecondsInAWorkday, Time endBusinessTime ) {
		return addTimeToWorkday( orgsHours, businessStartDt, millisecondsInAWorkday, endBusinessTime );
	}

	public static DateTime addTimeToWorkday( BusinessHours specificBusinessHours
			, DateTime businessStartDt, Long millisecondsInAWorkday, Time endBusinessTime ) {

		DateTime nextBusinessDt = BusinessHours.add(
							specificBusinessHours.ID, businessStartDt, millisecondsInAWorkday );
		system.debug( 'new date => ' + nextBusinessDt );

		if( nextBusinessDt.hour() > endBusinessTime.hour() ) {
			system.debug( 'adding an extra day to make business start hour less than business end hour' );
			// if somehow the calculation failed to put the date at the beginning of the business day
			// add another business day
			nextBusinessDt = BusinessHours.add(
							specificBusinessHours.ID, nextBusinessDt, millisecondsInAWorkday );
			system.debug( 'new date after adjustment to start hour => ' + nextBusinessDt );
		}

		return nextBusinessDt;
	}

	public static Datetime getBusinessStartDtWithNoGMT( Datetime aStartDt ) {
		return getBusinessStartDtWithNoGMT( orgsHours, aStartDt );
	}

	public static Datetime getBusinessStartDtWithNoGMT( BusinessHours specificBusinessHours
						, Datetime aStartDt ) {

		// set the beginning start date at 1 minute into the working hours so that when we add
		// the full duration of a business day, it will jump to the next business day
		Time oneMinuteBusinessTime = specificBusinessHours.MondayStartTime.addMinutes( 1 ); // .addHours( 1 );

		Datetime businessStartDt = DateTime.newInstance( aStartDt.yearGmt(), aStartDt.monthGmt(), aStartDt.dayGmt()
				, oneMinuteBusinessTime.hour(), oneMinuteBusinessTime.minute(), oneMinuteBusinessTime.second() );

		system.debug( 'Business Start Dt= ' + businessStartDt );
		return businessStartDt;

	}

	public static DateTime addWorkdays( DateTime aStartDt, Decimal nbrDays ) {
		return addWorkdays( orgsHours, aStartDt, nbrDays );
	}

	public static DateTime addWorkdays( BusinessHours specificBusinessHours
				, DateTime aStartDt, Decimal nbrDays ) {
		system.debug( 'Start Dt= ' + aStartDt );
		system.debug( 'nbrDays= ' + nbrDays );

		if( nbrDays == 0 ) {
			return null;
		}

		//Datetime businessStartDt = getBusinessStartDt( aStartDt );
		Datetime businessStartDt = getBusinessStartDtWithNoGMT(
									specificBusinessHours, aStartDt );
		Time endBusinessTime = specificBusinessHours.MondayEndTime;

		// get number of ms in the period of workdays
		Long millisecondsToFutureDt = getMillisecondsInWorkdays(
										specificBusinessHours, nbrDays );

		DateTime futureDt = addTimeToWorkday( specificBusinessHours
						, businessStartDt, millisecondsToFutureDt, endBusinessTime );

		return futureDt;
	}

	public static Date getDateAfterWorkdays( DateTime aStartDt, Decimal nbrDays ) {
		return getDateAfterWorkdays( orgsHours, aStartDt, nbrDays );
	}

	public static Date getDateAfterWorkdays( BusinessHours specificBusinessHours
										, DateTime aStartDt, Decimal nbrDays ) {
		DateTime aDateTime = addWorkdays( specificBusinessHours, aStartDt, nbrDays );

		// dateGmt() to extract date only without converting to timezone
		// example:  2019-08-02 00:00:00 is actually 2019-08-01 15:00:00 in CST, so date() returns 2019-08-01
		// while dateGmt() returns 2019-08-02
		Date aDate = aDateTime.dateGmt();
		system.debug( 'aDateTime= ' + aDateTime );
		system.debug( 'aDate= ' + aDate );

		return aDate;
	}

	public static Integer getDaysBetween( Date aStartDt, Date anEndDt ) {
		return getDaysBetween( orgsHours, aStartDt, anEndDt );
	}

	public static Integer getDaysBetween( BusinessHours specificBusinessHours
						, Date aStartDt, Date anEndDt ) {
		if( aStartDt == anEndDt ) {
			return 0;
		}

		Time oneMinuteBusinessTime = specificBusinessHours.MondayStartTime.addMinutes( 1 );
		Datetime startDateTime = DateTime.newInstance( aStartDt.year(), aStartDt.month(), aStartDt.day()
				, oneMinuteBusinessTime.hour(), oneMinuteBusinessTime.minute(), oneMinuteBusinessTime.second() );

		Time endBusinessTime = specificBusinessHours.MondayEndTime;
		DateTime endDateTime = DateTime.newInstance( anEndDt.year(), anEndDt.month(), anEndDt.day()
				, endBusinessTime.hour(), endBusinessTime.minute(), endBusinessTime.second() );

		// get number of ms in the period of workdays
		Long millisecondsInAWorkDay = getMillisecondsInWorkdays( specificBusinessHours, 1 );
		system.debug( 'millisecondsInAWorkDay= ' + millisecondsInAWorkDay );

		Long millisecondsBetween = BusinessHours.diff( specificBusinessHours.ID, startDateTime, endDateTime );
		system.debug( 'millisecondsBetween= ' + millisecondsBetween );

		// take into account the minute we've added to start date
		millisecondsBetween = millisecondsBetween - 60000;

		Integer daysBetween = Integer.valueOf( millisecondsBetween / millisecondsInAWorkDay );

		// consider current day when calculating backward periods
		if( aStartDt > anEndDt ) {
			return daysBetween - 1;
		}

		return daysBetween;
	}
}