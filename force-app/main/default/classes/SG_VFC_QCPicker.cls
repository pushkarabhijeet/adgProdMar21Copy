/**********************************************************************
* Name:     SG_VFC_QCPicker
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
* 1.0       26-Jun-2020     rwd           Initial Development           
*   
***********************************************************************/


public with sharing class SG_VFC_QCPicker {

// ************************           PUBLIC VARIABLES          **************************
	public WorkOrder theWorkOrder { get; set; }

	public List<SelectOption> qcOptions {get; set;}
	public Boolean hasQcs {get; set;}

	public String selectedQcId {get; set;}

	// error handling
	public Boolean hasError { get; set; }
	public String errorMsg { get; set; }


// ************************           PRIVATE VARIABLES       **************************
	private ApexPages.StandardController controller;


// ************************           CONSTRUCTOR                                 **************************           
	public SG_VFC_QCPicker(ApexPages.StandardController controller)
	{
		System.debug('---> starting SG_VFC_QCPicker constructor');
		this.controller = controller;
		theWorkOrder = (WorkOrder) controller.getRecord();
		init();
	}

	public void init()
	{
		System.debug(LoggingLevel.WARN, '---> start init');
		qcOptions = getQualityControlOptions( theWorkOrder.Id );
	}

	public PageReference goToQc()
	{
		PageReference pageRef;
		if ( String.isNotBlank(selectedQcId) )
		{
			pageRef = new PageReference( '/' + selectedQcId);
		}
		else
		{
			SG_DisplayUtils.addInfo('Please select a QC');
			pageRef = null;
		}
		return pageRef;
	}

	// get a list of all open QCs associated to the HOUSE of the Work Order
	public List<SelectOption> getQualityControlOptions( Id woId )
	{
		System.debug(LoggingLevel.WARN, '---> start get getQualityControlOptions');

		List<SelectOption> options = new List<SelectOption>();

		// we need to get the HouseId (really an Asset) for the Work Order
		if ( String.isNotBlank( woId ))
		{
			Id assetId;
			List<WorkOrder> orders = [SELECT Id, AssetId FROM WorkOrder WHERE Id = :woId];

			if ( orders != null && orders.size() > 0 )
			{
				assetId = orders[0].AssetId;
			}

			hasQcs = false;
			if ( String.isNotBlank(assetId))
			{
				for ( Quality_Control__c qc : [SELECT Id, Name, RecordTypeId, RecordType.Name FROM Quality_Control__c WHERE House_Unit__c = :assetId AND Is_Open__c = true
												ORDER BY RecordType.Name])
				{
					hasQcs = true;
					options.add(new SelectOption(qc.Id, qc.RecordType.Name));
				}
			}
		}


		return options;
	}




}