/**********************************************************************
* Name:     SG_VFC_ProjectLocation
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


public with sharing class SG_VFC_ProjectLocation {

/**************************************************************************************
    * Setup Variables for storing data required to show Acounts onto a Map
    ***************************************************************************************/

	// instead of Accounts - get Opp and wrap the project location
	public Opportunity theOpp {get; set;}
	public Project_Location_GEO__c geo {get; set;}
	public Id oppId {get; set;}


	// Create and initialize the variables below for storing current information on current and nearby accounts
	public NearbyLocation targetProject {get; set;}
	public List<NearbyLocation> nearbyLocations {get; set;}

	public String distance {get;set;}                   // Stores the filter criteria to show the distance scale that should be shown on the map
	public Integer vZoomLevels {get;set;}               // This is the zoom level for the Map according to the distance in Miles on the map to help scaling


	// This method will pull the details of the currently opened account in Salesforce
	// Constructor for initializing and pulling back data to display
	public SG_VFC_ProjectLocation(ApexPages.StandardController controller)
	{
		// Pull back the current Opp Id from the Page and query for the Co-ordinates
		if(controller.getRecord() != null && controller.getRecord().Id != null)
		{
			theOpp = [SELECT Id, Name, Project_Location_Zip__c, Entity__c
							FROM Opportunity WHERE Id = :controller.getRecord().Id];


		}

		init();

	}

	private void init()
	{
		System.debug(LoggingLevel.WARN, '---> start init');
		doQuery();
		//referenceLocations = new List<NearbyLocation>();

	}

	public void doQuery()
	{
		System.debug(LoggingLevel.WARN, '---> start doQuery');

		if ( theOpp != null && theOpp.Project_Location_Zip__c != null)
		{
			oppId = theOpp.Id;
			List<Project_Location_GEO__c> geos = [SELECT Id, Name, City__c, County_Name__c, Lat__c, Long__c, State_Abbr__c, State_Name__c, Time_Zone__c
			FROM Project_Location_GEO__c WHERE Id = :theOpp.Project_Location_Zip__c];

			if ( geos != null && geos.size() > 0 )
			{
				String whereClause = null;
				geo = geos[0];
				//referenceLocations = new List<NearbyLocation>();
				targetProject = new NearbyLocation( geo.Lat__c, geo.Long__c, geo, theOpp );
				//referenceLocations.add( nearby );
				String entity = theOpp.Entity__c;
				System.debug(LoggingLevel.WARN, '---> entity: ' + entity);
				if ( String.isNotBlank(entity) )
				{
					whereClause = '';
					whereClause += ' AND Entity__c = \'' + entity + '\'';
				}

				nearbyLocations = getNearbys(geo.Lat__c, geo.Long__c, 'Project_Location_GEO__c', whereClause );
			}

		}
	}


	public List<NearbyLocation> getNearbys(Decimal latitude, Decimal longitude, String locationFieldApiName, String whereClause )
	{
		System.debug(LoggingLevel.WARN, '---> start getNearbys');
		// todo: put query fields into custom setting...
		List<NearbyLocation> nearbys;
		if ( latitude != null && longitude != null && String.isNotBlank(locationFieldApiName))
		{
			if(distance == null) distance = '100';
			Integer distanceInt = 100;
			try
			{
				distanceInt = Integer.valueOf(distance);
			}
			catch(Exception exp)
			{
				System.debug('Error converting string to integration for distance. ' + exp);
			}

			String qry = 'SELECT ';
			qry += ' Id, Name, Project_Location_GEO__c, Project_Location_GEO__latitude__s, Project_Location_GEO__longitude__s, Project_Location_Zip__r.City__c, Project_Location_Zip__r.County_Name__c, Project_Location_Zip__r.State_Name__c, Project_Location_Zip__r.Name';

			qry += ' FROM Opportunity ';
			qry += ' WHERE (IsClosed = false OR IsWon = true)  ';
			if(!Test.isRunningTest()) qry += ' AND DISTANCE(' + locationFieldApiName + ', GEOLOCATION(' + latitude + ', ' + longitude + '), \'mi\') < ' + distanceInt;
			if(String.isNotBlank(whereClause)) qry += whereClause; // whereClause format should be "AND blah is blah, etc"
			if(!Test.isRunningTest()) qry += ' ORDER BY DISTANCE(' + locationFieldApiName + ', GEOLOCATION(' + latitude + ', ' + longitude + '), \'mi\')';

			System.debug(LoggingLevel.WARN, '---> the query: ' + qry );
			List<Opportunity> nearbyOpps;
			try
			{
				nearbyOpps = Database.query(qry);
			}
			catch (Exception e )
			{
				System.debug(LoggingLevel.WARN, '---> message, stacktrace: ' + e.getMessage() + ' ' + e.getStackTraceString() );

			}

			if ( nearbyOpps != null && nearbyOpps.size() > 0 )
			{
				nearbys = new List<NearbyLocation>();
				for ( Opportunity o : nearbyOpps )
				{
					if ( o.Id == oppId )
					{
						continue;
					}
					// create a temp GeoLocation object to pass in...
					Project_Location_GEO__c geo;
					Decimal lat = o.Project_Location_GEO__latitude__s;
					Decimal lon = o.Project_Location_GEO__longitude__s;
					try
					{
						geo = new Project_Location_GEO__c();
						geo.Lat__c = o.Project_Location_GEO__latitude__s;
						geo.Long__c = o.Project_Location_GEO__longitude__s;
						geo.City__c = o.Project_Location_Zip__r.City__c;
						geo.County_Name__c = o.Project_Location_Zip__r.County_Name__c;
						geo.State_Name__c = o.Project_Location_Zip__r.State_Name__c;
						geo.Name = o.Project_Location_Zip__r.Name;
					}
					catch( Exception e )
					{
						System.debug(LoggingLevel.WARN, '---> message, stacktrace: ' + e.getMessage() + ' ' + e.getStackTraceString() );
					}

					NearbyLocation loc = new NearbyLocation(lat, lon, geo,  o);
					nearbys.add( loc );
				}
			}

			setZoomLevels(distanceInt);
		}

		return nearbys;
	}

	//Find zoomlevels
	public void setZoomLevels(Integer distanceInt)
	{
		if (distanceInt <= 2) {               // If set to 2 miles then the zoom level is set to 14
			vZoomLevels = 14;
		}
		else if (distanceInt <= 5) {       // If set to 5 miles then the zoom level is set to 11
			vZoomLevels = 11;
		}
		else if (distanceInt <= 20) {
			vZoomLevels = 10;
		}
		else if (distanceInt <= 50) {
			vZoomLevels = 9;
		}
		else if (distanceInt <= 100) {
			vZoomLevels = 7;
		}
		else if (distanceInt <= 500) {
			vZoomLevels = 5;
		}
		else if (distanceInt <= 1000) {
			vZoomLevels = 4;
		}
		else {
			vZoomLevels = 11;  // If there are no other options then do this    Approx 5 Miles
		}
	}

	public class NearbyLocation
	{
		public String position {get;set;}
		public Decimal latitude {get;set;}
		public Decimal longitude {get;set;}
		public Project_Location_GEO__c geo {get;set;}
		public String locationTitle {get; set;}
		public String city {get; set;}
		public String state {get; set;}
		public String county {get; set;}
		public String zip {get; set;}
		public Opportunity o {get; set;}

		public NearbyLocation(Decimal latitude, Decimal longitude, Project_Location_GEO__c geo, Opportunity o)
		{
			//{latitude: 37.794, longitude: -122.395}
			position = '{latitude: ' + latitude + ', longitude: ' + longitude + '}';
			this.latitude = latitude;
			this.longitude = longitude;
			this.o = o;
			setLocation(geo, o);
		}

		public void setLocation(Project_Location_GEO__c geo, Opportunity o)
		{
			this.geo = geo;
			if ( geo != null )
			{
				if ( o != null )
				{
					locationTitle = o.Name;
				}

				city = geo.City__c;
				state = geo.State_Name__c;
				county = geo.County_Name__c;
				zip = geo.Name;
			}
		}
	}


}