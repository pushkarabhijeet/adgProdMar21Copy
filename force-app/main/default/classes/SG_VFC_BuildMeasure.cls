/**********************************************************************
* Name:     SG_VFC_BuildMeasure
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
* 1.0       10-Nov-2020     rwd           Initial Development           
*   
***********************************************************************/


public with sharing class SG_VFC_BuildMeasure {

// ************************           PUBLIC VARIABLES          **************************
	public Quality_Control__c theQc { get; set; }
	public List<QC_Build_Measure__c> existingMeasurements {get; set;}
	public List<QC_Build_Measure__c> measurements {get; set;}
 
	// error handling
	public Boolean hasError { get; set; }
	public String errorMsg { get; set; }

	public List<SelectOption> getEdgeItems() {
		List<SelectOption> options = new List<SelectOption>();
		options.add(new SelectOption('Yes','Yes'));
		options.add(new SelectOption('No','No'));
		return options;
	}


// ************************           PRIVATE VARIABLES       **************************
	private ApexPages.StandardController controller;
	@TestVisible
	private static final Integer INITIAL_MEASUREMENT_NUMBER = 4;
	@TestVisible
	private static final Integer ADDITIONAL_MEASUREMENT_NUMBER = 1;


// ************************           CONSTRUCTOR                                 **************************           
	public SG_VFC_BuildMeasure(ApexPages.StandardController controller) {
		System.debug('---> starting SG_VFC_BuildMeasure constructor');
		this.controller = controller;
		theQc = (Quality_Control__c) controller.getRecord();

		// get the full qc...
		if ( theQc != null )
		{
			List<Quality_Control__c> qcs = SG_ContentDocumentHelper.getFullQcs( new Set<Id>{
					theQc.Id} );
			if ( qcs != null && qcs.size() > 0 )
			{ 
				theQc = qcs[0];
				System.debug(LoggingLevel.WARN, '---> full qc: ' + theQc);
			}
		}

		init();
	}

	public void init()
	{
		System.debug(LoggingLevel.WARN, '---> start init');
		existingMeasurements = getExistingMeasures();
		List<QC_Build_Measure__c> blanks = getBlankMeasurements( INITIAL_MEASUREMENT_NUMBER );
		measurements = new List<QC_Build_Measure__c>();
		if ( existingMeasurements != null && existingMeasurements.size() > 0 )
		{
			measurements.addAll( existingMeasurements );
		}
		if ( blanks != null && blanks.size() > 0 )
		{
			measurements.addAll( blanks );
		}


	}

	public List<QC_Build_Measure__c> getExistingMeasures()
	{
		System.debug(LoggingLevel.WARN, '---> start getExistingMeasures');
		List<QC_Build_Measure__c> tmpList;
		if ( theQc != null )
		{
			tmpList = [SELECT Id, Name, Length__c, Width__c, Material__c, Do_edges_need_beveled_and_polished__c, Quality_Control__c, Comments__c FROM QC_Build_Measure__c WHERE Quality_Control__c = :theQc.Id];
		}
		System.debug(LoggingLevel.WARN, '---> existing measurements: ' + tmpList );
		return tmpList;
	}

	public List<QC_Build_Measure__c> getBlankMeasurements( Integer numberToAdd)
	{
		List<QC_Build_Measure__c> tmpList = new List<QC_Build_Measure__c>();
		for ( Integer i=0;i< numberToAdd;i++ )
		{
			QC_Build_Measure__c measurement = new QC_Build_Measure__c();
			measurement.Quality_Control__c = theQc.Id;
			tmpList.add( measurement );
		}

		return tmpList;
	}

	public PageReference addMoreMeasurements()
	{
		System.debug(LoggingLevel.WARN, '---> start addMoreMeasurements');

		customSave();

		List<QC_Build_Measure__c> tmpList = getBlankMeasurements(ADDITIONAL_MEASUREMENT_NUMBER);
		if ( measurements == null ) measurements = new List<QC_Build_Measure__c>();
		measurements.addAll( tmpList );

		return null;
	}

	public PageReference customSave()
	{
		System.debug(LoggingLevel.WARN, '---> start customSave');
		if ( measurements != null )
		{
			List<QC_Build_Measure__c> upsertList = new List<QC_Build_Measure__c>();
			for ( QC_Build_Measure__c measure : measurements )
			{
				if ( String.isNotBlank( measure.Name ))
				{
					upsertList.add( measure );
				}
			}

			System.debug(LoggingLevel.WARN, '---> measurements to upsert: ' + measurements );
			if ( upsertList != null && upsertList.size()  > 0 )
			{
				try
				{
					upsert upsertList;
					SG_DisplayUtils.addConfirm('Changes Saved');
				}
				catch (Exception e)
				{
					System.debug(LoggingLevel.WARN, '---> message, stacktrace: ' + e.getMessage() + ' ' + e.getStackTraceString() );
					SG_DisplayUtils.addError('There was a problem saving. For reference, the error was: ' + e.getMessage() );

				}

			}
		}
		return null;
	}



}