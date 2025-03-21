/**********************************************************************
* Name:     SG_OpportunityHelper
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
* 1.0       23-Oct-2019     rwd           Initial Development           
*   
***********************************************************************/


public class SG_OpportunityHelper {
    public static Boolean hasDoneZip = false;
    public static Boolean hasDoneSchedules = false;
    public static Boolean isTest = false; // used for tests to verify trigger turned off...


    // regenerate Rev Schedules as needed when data on Opp changes
    public static void doReestablishSchedules( System.TriggerOperation triggerEvent, List<Opportunity> newOpps, Map<Id, Opportunity> oldOpps, List<TriggerOperation> allowedTriggerTypes)
    {
        System.debug(LoggingLevel.WARN, '---> start doReestablishSchedules');
        if ( !canFireTrigger( triggerEvent, allowedTriggerTypes, hasDoneSchedules) )
        {
            System.debug(LoggingLevel.WARN, '---> already hasDoneSchedules: ' + hasDoneSchedules + ' or wrong trigger type; skip');
            return;
        }
        hasDoneSchedules = true;

        // see if one of our fields has changed...
        if ( newOpps != null && newOpps.size() > 0 )
        {
            Set<Id> oppIds = new Set<Id>();
            List<OpportunityLineItemSchedule> updateScheds = new List<OpportunityLineItemSchedule>();
            for (Opportunity o : newOpps)
            {
                Opportunity oldOpp;
                if (oldOpps != null && oldOpps.containsKey(o.Id))
                {
                    oldOpp = oldOpps.get(o.Id);
                }
                System.debug(LoggingLevel.WARN, '---> oldOpp: ' + oldOpp);
                System.debug(LoggingLevel.WARN, '---> o Project_Duration_months__c: ' + o.Project_Duration_months__c);
                System.debug(LoggingLevel.WARN, '---> has changed Project_Duration_months__c: ' + SG_DisplayUtils.hasChanged(oldOpp, o, 'Project_Duration_months__c'));
                if (SG_DisplayUtils.hasChanged(oldOpp, o, 'Estimated_Project_Start_Date__c') || SG_DisplayUtils.hasChanged(oldOpp, o, 'Project_Duration_months__c')
                        || SG_DisplayUtils.hasChanged(oldOpp, o, 'of_Homes_Units__c') || SG_DisplayUtils.hasChanged(oldOpp, o, 'Estimated_Revenue_per_Home_Unit__c')) {

                    System.debug(LoggingLevel.WARN, '---> opp has field change');
                    oppIds.add( o.Id );
                }
            }

            System.debug(LoggingLevel.WARN, '---> opps to regenerate scheds: ' + oppIds);
            if ( oppIds != null && oppIds.size() > 0 )
            {
                doReestablishSchedules_ATFUTURE(oppIds);
            }
        }

    }

    // problems with timing of OLI creation from a process builder - convert the main logic to fire @future
    @Future
    public static void doReestablishSchedules_ATFUTURE( Set<Id> oppIds )
    {
        System.debug(LoggingLevel.WARN, '---> start doReestablishSchedules_ATFUTURE');

        if ( oppIds != null && oppIds.size() > 0 )
        {
            Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([SELECT Id, Name,Estimated_Project_Start_Date__c, Project_Duration_months__c, of_Homes_Units__c, Estimated_Revenue_per_Home_Unit__c, CloseDate
                                                                        FROM Opportunity WHERE Id IN :oppIds]);
            List<OpportunityLineItemSchedule> updateScheds = new List<OpportunityLineItemSchedule>();
            System.debug(LoggingLevel.WARN, '---> opps to regenerate scheds: ' + oppMap);
            // wipe out all the schedules for the products on these opps
            if ( oppMap != null && oppMap.keySet().size() > 0 )
            {
                List<OpportunityLineItemSchedule> scheds = [SELECT Id, OpportunityLineItemId FROM OpportunityLineItemSchedule
                                                            WHERE OpportunityLineItem.OpportunityId IN :oppMap.keySet()
                                                            AND OpportunityLineItem.Product2.CanUseRevenueSchedule = true ];
                System.debug(LoggingLevel.WARN, '---> scheds to delete: ' + scheds );
                if ( scheds != null && scheds.size() > 0 )
                {
                    try
                    {
                        delete scheds;
                        System.debug(LoggingLevel.WARN, '---> scheds deleted');
                    }
                    catch ( Exception e )
                    {
                        System.debug(LoggingLevel.WARN, '---> message, stacktrace: ' + e.getMessage() + ' ' + e.getStackTraceString() );
                    }
                }
            }

            // now recreate the scheds
            // fields we care about: Estimated start date (first sched date), duration in months (# of scheds), # of Homes (quantity), Estimated rev per home (revenue)
            // for each - we'll need to start at the start date, then bump 1 month per month of project
            // take the total quantity and divide by duration
                // divide and ROUND DOWN; then for the last one do a calculation to see what the total quantity is - quantity from opp; put the remainder on the last sched
            // revenue is the Estimated Rev/Home x sched quantity

            List<OpportunityLineItem> olis = [SELECT Id, Product2Id, Product2.CanUseRevenueSchedule, Product2.Name, OpportunityId FROM OpportunityLineItem
            WHERE OpportunityLineItem.OpportunityId IN :oppMap.keySet()
            AND Product2.CanUseRevenueSchedule = true];
            System.debug(LoggingLevel.WARN, '---> olis for opp: ' + olis );


            for ( OpportunityLineItem oli : [SELECT Id, Product2Id, Product2.CanUseRevenueSchedule, Product2.Name, OpportunityId FROM OpportunityLineItem
                                                WHERE OpportunityLineItem.OpportunityId IN :oppMap.keySet()
                                                AND Product2.CanUseRevenueSchedule = true] )
            {
                System.debug(LoggingLevel.WARN, '---> creating schedule for OLI: ' + oli.Product2.Name );

                Opportunity o = oppMap.get( oli.OpportunityId );
                if ( o != null )
                {
                    // initialize the monthly constants...
                    Decimal duration = 1;
                    Date startDate = o.CloseDate;
                    if ( startDate == null ) startDate = Date.today();
                    Decimal totalQty = 1;
                    Integer schedQty = 1;
                    Decimal totalRev = 1;
                    Decimal schedRev = 1;

                    // calculate duration
                    if ( o.Project_Duration_months__c != null && o.Project_Duration_months__c != 0 )
                    {
                        System.debug(LoggingLevel.WARN, '---> setting duration');
                        duration = o.Project_Duration_months__c.round(System.RoundingMode.CEILING) ;
                    }
                    System.debug(LoggingLevel.WARN, '---> monthly duration: ' + duration );

                    // calculate start date
                    if ( o.Estimated_Project_Start_Date__c != null )
                    {
                        startDate = o.Estimated_Project_Start_Date__c;
                    }
                    // cast the start date to the first of the month
                    startDate = startDate.toStartOfMonth();
                    System.debug(LoggingLevel.WARN, '---> startDate is now: ' + startDate ); 

                    // calculate the quantity (# of Homes field on Opp)
                    if ( o.of_Homes_Units__c != null && o.of_Homes_Units__c != 0 )
                    {
                        // store this for later to do a final comparison...
                        totalQty = o.of_Homes_Units__c;

                        Decimal tmpQty = o.of_Homes_Units__c / duration;
                        System.debug(LoggingLevel.WARN, '---> tmpQty: ' + tmpQty );
                        if ( tmpQty > 0 )
                        {
                            schedQty = Integer.valueOf( tmpQty.round(System.RoundingMode.FLOOR));
                        }
                    }
                    System.debug(LoggingLevel.WARN, '---> total quantity: ' + totalQty);
                    System.debug(LoggingLevel.WARN, '---> monthly quantity: ' + schedQty );

                    // calculate the monthly rev
                    if ( o.Estimated_Revenue_per_Home_Unit__c != null && o.Estimated_Revenue_per_Home_Unit__c > 0 )
                    {
                        schedRev = o.Estimated_Revenue_per_Home_Unit__c;
                    }
                    /*if ( o.Estimated_Revenue_per_Home_Unit__c != null && o.Estimated_Revenue_per_Home_Unit__c > 0 )
                    {
                        // save the total for later to do a final comparison...
                        totalRev = o.Estimated_Revenue_per_Home_Unit__c;
                        Decimal tmpSched = totalRev / duration;
                        System.debug(LoggingLevel.WARN, '---> tmpSched = ' + tmpSched );
                        if ( tmpSched != null )
                        {
                            schedRev = tmpSched.round( System.RoundingMode.FLOOR );
                        }
                    }*/
                    System.debug(LoggingLevel.WARN, '---> total revenue: ' + totalRev );
                    System.debug(LoggingLevel.WARN, '---> sched revenue: ' + schedRev );

                    // now start building the schedules...
                    Decimal appliedQty = 0;
                    //Decimal appliedRev = 0;
                    System.debug(LoggingLevel.WARN, '---> duration: ' + duration );
                    for ( Integer i=0; i<duration; i++ )
                    {
                        System.debug(LoggingLevel.WARN, '---> ');
                        System.debug(LoggingLevel.WARN, '---> ');
                        System.debug(LoggingLevel.WARN, '---> i: ' + i );
                        OpportunityLineItemSchedule sched = new OpportunityLineItemSchedule();

                        Date schedDate = startDate.addMonths( i ); // should start at 0 since our counter starts at 0
                        System.debug(LoggingLevel.WARN, '---> schedDate: ' + schedDate );

                        sched.OpportunityLineItemId = oli.Id;
                        sched.ScheduleDate = schedDate;
                        sched.Type = 'Both';

                        // make sure quantity is correct - figure out the difference between the amt applied and the total
                        Decimal tmpQty = appliedQty + schedQty;
                        System.debug(LoggingLevel.WARN, '---> applied Qty: ' + appliedQty + ' totalQty: ' + totalQty );
                        if ( (i == duration - 1) || (tmpQty + schedQty > totalQty) )
                        {
                            sched.Quantity = totalQty - appliedQty;
                            System.debug(LoggingLevel.WARN, '---> offset Qty: ' + sched.Quantity);
                        }
                        else
                        {
                            sched.Quantity = schedQty;
                            System.debug(LoggingLevel.WARN, '---> normal Qty: ' + sched.Quantity);
                        }
                        appliedQty += schedQty;

                        sched.Revenue = sched.Quantity * schedRev;
                        /*// make sure revenue is correct - figure out the difference between the amt applied and the total
                        Decimal tmpRev = appliedRev + schedRev;
                        System.debug(LoggingLevel.WARN, '---> applied rev: ' + appliedRev + ' totalRev: ' + totalRev );
                        if ( (i == duration - 1) || (tmpRev + schedRev > totalRev) )
                        {
                            sched.Revenue = totalRev - appliedRev;
                            System.debug(LoggingLevel.WARN, '---> offset rev: ' + sched.Revenue);
                        }
                        else
                        {
                            sched.Revenue = schedRev;
                            System.debug(LoggingLevel.WARN, '---> normal rev: ' + sched.Revenue);
                        }
                        appliedRev += schedRev;*/

                        System.debug(LoggingLevel.WARN, '---> adding schedule: ' + sched );
                        updateScheds.add( sched );

                    }
                }
            }

            System.debug(LoggingLevel.WARN, '---> scheds to add: ' + updateScheds );
            if ( updateScheds != null && updateScheds.size() > 0 )
            {
                System.debug(LoggingLevel.WARN, '---> inserting updated schedules ');
                String errMsg = SG_DB.insertRecords(updateScheds);
                System.debug(LoggingLevel.WARN, '---> errors: ' + errMsg );
            }

        }

    }

    // grab a ZIP CODE object, based on the Opp's custom zip field; populate relevant fields wo we can display on a map
    public static void doZipLocation(System.TriggerOperation triggerEvent, List<Opportunity> newOpps, Map<Id, Opportunity> oldOpps)
    {
        System.debug(LoggingLevel.WARN, '---> start doZipLocation');

        Boolean canFire = false;
        switch on triggerEvent
        {
            // define what trigger events should invoke this code (before insert, after update, etc)
            when BEFORE_INSERT, BEFORE_UPDATE
            {
                System.debug(LoggingLevel.WARN, '---> canFire is true');
                canFire = true;
            }
        }
        if ( hasDoneZip || !canFire )
        {
            System.debug(LoggingLevel.WARN, '---> already hasDoneZip: ' + hasDoneZip + ' or wrong trigger type; skip');
            return;
        }

        // prevents recursive triggers
        hasDoneZip = true;
        System.debug(LoggingLevel.WARN, '---> newOpps: ' + newOpps);

        if ( newOpps != null && newOpps.size() > 0 )
        {
            Map<Id, List<Opportunity>> zipToOppMap = new Map<Id, List<Opportunity>>();

            for ( Opportunity o :newOpps )
            {
                // get the zip if added/updated; also blank it out if zip removed
                Opportunity oldOpp;
                if ( oldOpps != null && oldOpps.containsKey(o.Id))
                {
                    oldOpp = oldOpps.get(o.Id);
                }

                System.debug(LoggingLevel.WARN, '---> testing to see if location has changed...');
                System.debug(LoggingLevel.WARN, '---> oldOpp: ' + oldOpp);
                System.debug(LoggingLevel.WARN, '---> o: ' + o );
                System.debug(LoggingLevel.WARN, '---> new opp project location: ' + o.Project_Location_Zip__c );
                System.debug(LoggingLevel.WARN, '---> hasChanged: ' + SG_DisplayUtils.hasChanged( oldOpp, o, 'Project_Location_Zip__c' ));
                if ( SG_DisplayUtils.hasChanged( oldOpp, o, 'Project_Location_Zip__c') )
                {
                    // blank out relevant fields if zip is removed...
                    if ( String.isBlank(o.Project_Location_Zip__c) )
                    {
                        System.debug(LoggingLevel.WARN, '---> removing obsolete locations');
                        o.Project_Location_City__c = null;
                        o.Project_Location_State__c = null;
                        o.Project_Location_GEO__latitude__s = null;
                        o.Project_Location_GEO__longitude__s = null;
                    }
                    else
                    {
                        List<Opportunity> tmpList = zipToOppMap.get( o.Project_Location_Zip__c );
                        if ( tmpList == null ) tmpList = new List<Opportunity>();
                        tmpList.add( o );
                        zipToOppMap.put( o.Project_Location_Zip__c, tmpList );
                    }

                }
            }

            System.debug(LoggingLevel.WARN, '---> zipToOppMap: ' + zipToOppMap);
            if ( zipToOppMap != null && zipToOppMap.keySet().size() > 0 )
            {
                for ( Project_Location_GEO__c zip : [SELECT Id, Name, City__c, County_Name__c, Lat__c, Long__c, State_Abbr__c, State_Name__c, Time_Zone__c
                                                        FROM Project_Location_GEO__c WHERE Id IN :zipToOppMap.keySet()])
                {
                    System.debug(LoggingLevel.WARN, '---> setting for zip: ' + zip );
                    List<Opportunity> opps = zipToOppMap.get( zip.Id );
                    if ( opps != null && opps.size() > 0 )
                    {
                        for ( Opportunity o : opps )
                        {
                            System.debug(LoggingLevel.WARN, '---> setting project zip info for Opp: ' + o.Name );

                            System.debug(LoggingLevel.WARN, '---> city: ' + zip.City__c );

                            o.Project_Location_City__c = zip.City__c;
                            o.Project_Location_State__c = zip.State_Name__c;
                            if ( zip.Lat__c != null && zip.Long__c != null )
                            {
                                o.Project_Location_GEO__latitude__s = zip.Lat__c;
                                o.Project_Location_GEO__longitude__s = zip.Long__c;
                            }
                        }
                    }
                }
            }

        }


    }


    // determines if entrance criteria for trigger has been met; NOTE - is not used for business logic
    public static Boolean canFireTrigger(TriggerOperation type, List<TriggerOperation> allowedTypes, Boolean isRecursive )
    {
        Boolean canFire = false;
        if ( !isRecursive && type != null && allowedTypes != null && allowedTypes.contains(type))
        {
            System.debug(LoggingLevel.WARN, '---> allowed type...');
            canFire = true;
        }

        return canFire;
    }




}