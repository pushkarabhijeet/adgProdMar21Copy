/***************************************************
* Name:         SG_GenericBatchApex
* Author:       Strategic Growth, Inc. (www.strategicgrowthinc.com)
* Date:         29 Jul 2020
* ==================================================
* ==================================================
* Purpose:      ...
*
* ==================================================
* ==================================================
* History:
* VERSION   DATE            INITIALS    DESCRIPTION/FEATURES ADDED
* 1.0       29 Jul 2020     FMF     Initial Development
* 
****************************************************/

global virtual class SG_GenericBatchApex
        implements Database.Batchable<sObject>, Database.Stateful, Schedulable {

    public static final String jobName = 'SGI - Generic Batch Apex - Daily Run';

    // Seconds Minutes Hours Day_of_month Month Day_of_week Optional_year
    public static final String DEFAULT_SCHEDULE = '0 30 2 15 * ?'; // every 15th at 2:30 am

    global Integer BatchSize = 1200;
    global String theQuery;
    global ID batchID;

    global SG_GenericBatchApex() {
        system.debug( 'super class constructor' );
        initialize();
    }

    global virtual void initialize() {
        system.debug( 'super class initialize' );

        System.debug( 'theQuery= ' + theQuery );
    }

    global Database.QueryLocator start( Database.BatchableContext bc ) {
        system.debug( 'super class start' );
        return Database.getQueryLocator( theQuery );
    }

    global void execute( Database.BatchableContext bc, List<SObject> scope ) {
        system.debug( 'super class execute' );
        processRecords( scope );
    }

    global virtual void processRecords( List<SObject> scope ) {
        System.debug( 'super class processRecords - scope= ' + scope );
    }

    global virtual void finish( Database.BatchableContext bc ) {
        // start the next batch apex here
        System.debug( 'super class finish' );

    }

    global virtual void execute( SchedulableContext sc ) {
        System.debug( 'super class execute' );
    }

    global static void removeSchedule( String aJobName ) {
        // remove existing schedule
        System.debug( 'super class removeSchedule= ' + aJobName );
        String jobNameMask = aJobName + '%';
        List<CronTrigger> cL = [
                SELECT ID
                FROM CronTrigger
                WHERE CronJobDetail.Name LIKE :jobNameMask
        ];

        for( CronTrigger aCronTrigger : cL ) {
            system.abortJob( aCronTrigger.ID );
        }
    }

}