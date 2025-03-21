/***************************************************
* Name:         SG_WorkdayCalculationHelper_Test
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


@isTest
public with sharing class SG_WorkdayCalculationHelper_Test {
	public static TestMethod void getDaysBetweenTest() {
		Date startDt = Date.valueOf( '2019-09-03' );
		Date endDt = Date.valueOf( '2019-09-09' );
		Integer db = SG_WorkdayCalculationHelper.getDaysBetween( startDt, endDt );

		system.assertEquals( 4, db, 'days between test' );

		startDt = Date.valueOf( '2019-09-03' );
		endDt = Date.valueOf( '2019-09-16' );
		db = SG_WorkdayCalculationHelper.getDaysBetween( startDt, endDt );

		system.assertEquals( 9, db, '2 weeks between test' );

		startDt = Date.valueOf( '2019-08-15' );
		endDt = Date.valueOf( '2019-08-09' );
		db = SG_WorkdayCalculationHelper.getDaysBetween( startDt, endDt );

		system.assertEquals( -4, db, 'backward period test' );
	}

	public static TestMethod void addBusinessDaysTest() {
		Test.startTest();

		// NOTE:  using mid-August to test because there are no holidays in that month
		// adding a holiday in August will probably make this test fail

		// 8/9/19 is Friday - test with Date assigned to Datetime to reflect actual usage
		DateTime aStartDt = Date.valueOf( '2019-08-09' ); //DateTime.valueOf( '2019-08-09 00:00:00' );

		// add 1 business day to a Friday and it should return Monday 8/12/19
		Date aDate = SG_WorkdayCalculationHelper.getDateAfterWorkdays( aStartDt, 1 );
		system.assertEquals( Date.valueOf( '2019-08-12' ), aDate, 'add 1 bday to Friday Test' );

		// 8/16/19 is Thursday
		aStartDt = Date.valueOf( '2019-08-15' ); //DateTime.valueOf( '2019-08-15 00:00:00' );

		// add 2 business days to a Thursday and it should return Monday 8/19/19
		aDate = SG_WorkdayCalculationHelper.getDateAfterWorkdays( aStartDt, 2 );
		system.assertEquals( Date.valueOf( '2019-08-19' ), aDate, 'add 2 bdays to Thursday Test' );

		// 8/12/19 is Monday
		aStartDt = Date.valueOf( '2019-08-12' ); //DateTime.valueOf( '2019-08-12 00:00:00' );

		// SUBTRACT 1 business day from a Monday and it should return Friday 8/9/19
		aDate = SG_WorkdayCalculationHelper.getDateAfterWorkdays( aStartDt, -1 );
		system.assertEquals( Date.valueOf( '2019-08-9' ), aDate, 'SUBTRACT 1 bday from Monday Test' );

		// Monday 8/19/19
		aStartDt = Date.valueOf( '2019-08-19' ); //DateTime.valueOf( '2019-08-19 00:00:00' );

		// SUBTRACT 2 business days from a Monday and it should return Thursday 8/15/19
		aDate = SG_WorkdayCalculationHelper.getDateAfterWorkdays( aStartDt, -2 );
		system.assertEquals( Date.valueOf( '2019-08-15' ), aDate, 'SUBTRACT 2 bdays from Monday Test' );

		Test.stopTest();
	}

	public static TestMethod void workdayMapTest() {
		Test.startTest();

		// 8/9/19 is Friday - test with Date assigned to Datetime to reflect actual usage
		DateTime aStartDt = Date.valueOf( '2019-08-09' ); //DateTime.valueOf( '2019-08-09 00:00:00' );

		// get next 7 business days
		Map<Integer, DateTime> workdayMap = SG_WorkdayCalculationHelper.getWorkdayMap( aStartDt, 7 );
		system.debug( 'workdayMap= ' + workdayMap );

		// add 1 business day to a Friday 8/9/19 and it should return Monday 8/12/19
		system.assertEquals( Date.valueOf( '2019-08-12' ), workdayMap.get( 1 ).date(), 'add 1 bday to Friday Test' );
		// add 6 business days to a Friday 8/9/19 and it should return Monday 8/19/19 the week after
		system.assertEquals( Date.valueOf( '2019-08-19' ), workdayMap.get( 6 ).date(), 'add 6 bdays to Friday Test' );


		// 8/20/19 is Tuesday
		aStartDt = Date.valueOf( '2019-08-20' ); //DateTime.valueOf( '2019-08-20 00:00:00' );

		// get prior 7 business days
		workdayMap = SG_WorkdayCalculationHelper.getWorkdayMap( aStartDt, -7 );
		system.debug( 'workdayMap= ' + workdayMap );

		// SUBTRACT 2 business day from a Tuesday 8/20/19 and it should return Friday 8/16/19
		system.assertEquals( Date.valueOf( '2019-08-16' ), workdayMap.get( -2 ).date(), 'SUBTRACT 2 bdays from Tuesday Test' );
		// SUBTRACT 7 business days from a Tuesday 8/20/19 and it should return Friday 8/9/19 the week before
		system.assertEquals( Date.valueOf( '2019-08-09' ), workdayMap.get( -7 ).date(), 'SUBTRACT 7 bdays to Friday Test' );

		Test.stopTest();
	}
}