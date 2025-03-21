/***************************************************
* Name:         SG_BatchAssetWorkOrderControl_Test
* Author:       Strategic Growth, Inc. (www.strategicgrowthinc.com)
* Date:         31 Jul 2020
* ==================================================
* ==================================================
* Purpose:      ...
*
* ==================================================
* ==================================================
* History:
* VERSION   DATE            INITIALS    DESCRIPTION/FEATURES ADDED
* 1.0       31 Jul 2020     FMF     Initial Development
* 
****************************************************/

@isTest
public with sharing class SG_BatchAssetWorkOrderControl_Test {
    @TestSetup
    public static void setupData() {
        SG_WorkOrderHelper_Test.createDataForFSL();

    }

    public static TestMethod void changeAssetFSMTest() {
        Test.startTest();

        SG_BatchAssetWorkOrderControl.scheduleMe( SG_BatchAssetWorkOrderControl.JobName
                , SG_BatchAssetWorkOrderControl.DEFAULT_SCHEDULE, true );

        SG_BatchAssetWorkOrderControl.scheduleEveryXMin( 30 );

        Test.stopTest();
    }
}