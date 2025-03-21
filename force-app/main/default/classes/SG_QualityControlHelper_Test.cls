/***************************************************
* Name:         SG_QualityControlHelper_Test
* Author:       Strategic Growth, Inc. (www.strategicgrowthinc.com)
* Date:         27 May 2020
* ==================================================
* ==================================================
* Purpose:      ...
*
* ==================================================
* ==================================================
* History:
* VERSION   DATE            INITIALS    DESCRIPTION/FEATURES ADDED
* 1.0       27 May 2020     FMF     Initial Development
* 
****************************************************/

@isTest
public with sharing class SG_QualityControlHelper_Test {

    public static Boolean isTest = false;

    @TestSetup
    public static void setupData() {
        SG_WorkOrderHelper_Test.createDataForFSL();

        // create/query objects to test
        Account installer = [
                SELECT ID
                FROM Account
                WHERE Name LIKE 'Installer%'
                LIMIT 1
        ];

        Asset anAsset = [
                SELECT ID, Field_Service_Manager__c, AccountID
                FROM Asset
                WHERE Name = '1313 Mockingbird'
                LIMIT 1
        ];

        SG_ServiceAppointment.recordIdsAlreadyProcessedSet = new Set<ID>();

        WorkOrder wo = new WorkOrder();
        wo.AssetId = anAsset.ID;
        wo.Installer_Account__c = installer.ID;
        wo.Job_Type__c = 'QC Pre-Walk';
        wo.Start_Day__c = Date.today().addDays( 1 );
        wo.Job_End_Day__c = Date.today().addDays( 3 );

        system.debug( 'inserting test WO= ' + wo );
        insert wo;
    }

    public static TestMethod void myUnitTest() {
        Test.startTest();

        SG_QualityControlHelper.qcConfigList = new List<Quality_Control_Trigger_Case_Creation__mdt>();
        Quality_Control_Trigger_Case_Creation__mdt qcConfig = new Quality_Control_Trigger_Case_Creation__mdt();
        qcConfig.DeveloperName = 'Test Rule';
        qcConfig.MasterLabel = 'Test Rule';
        qcConfig.QC_Field_Name_to_Verify__c = 'Installed_per_diagram__c';
        qcconfig.QC_Field_Value__c = 'No';
        qcConfig.List_of_QC_Record_Types__c = 'Pre_Walk';
        qcConfig.Case_Subject__c = 'Testing QC Trigger';
        qcconfig.Case_Type__c = 'Repair';
        qcconfig.QC_Field_Name_for_Material_Option__c = null;
        qcConfig.Case_Material_If_Yes__c = null;
        qcconfig.Case_Material_If_No__c = null;
        SG_QualityControlHelper.qcConfigList.add( qcConfig );

        Quality_Control__c qc = [
                SELECT ID, House_Unit__c, Work_Order__c, Most_Recent_Case_Created__c
                FROM Quality_Control__c
                WHERE House_Unit__r.Name = '1313 Mockingbird'
                AND Work_Order__r.Job_Type__c = 'QC Pre-Walk'
                LIMIT 1
        ];

        qc.Does_Shower_Bath_Need_Field_Measure__c = 'Yes';
        qc.Check_Slab_Tolerance__c = 'Approved';
        qc.Status__c = SG_QualityControlHelper.COMPLETED_STATUS_QC;
        qc.X1_8_between_tile_tub_pan_no_grout__c = 'No';
        qc.Action_Needed__c = 'No';
        qc.Are_Cabinets_Installed__c = 'No';
        qc.Are_Countertops_Installed__c = 'No';
        qc.Backsplash_ran_to_edge_of_counter_top__c = 'No';
        qc.Case_Billing_Info__c = 'No';
        qc.Check_Walls_for_Plumb__c = 'No';
        qc.Chipped_tiles__c = 'No';
        qc.Chipped_tiles_at_cut_edges__c = 'No';
        qc.Cuts_neat_clean_around_windows_sills__c = 'No';
        qc.Cuts_neat_clean_niches_drain_in_pan__c = 'No';
        qc.Cuts_tight_around_plugs__c = 'No';
        qc.Damage_cabinets_doors_walls__c = 'No';
        qc.Damage_to_baseboards__c = 'No';
        qc.Damage_to_cabinets_counters_sink__c = 'No';
        qc.Damage_to_tubs_pans__c = 'No';
        qc.Deco_level_and_even__c = 'No';
        qc.Did_we_meet_builder_specifications__c = 'No';
        qc.Door_jambs_under_cut__c = 'No';
        qc.Doors_rehung_hinge_pins_door_stops__c = 'No';
        qc.Electrical_cords_in_good_working_order__c = 'No';
        qc.Extra_material_in_attic_designated_area__c = 'No';
        qc.Face_hearth_per_diagram__c = 'No';
        qc.Floor_clean_free_of_glue__c = 'No';
        qc.Floor_plan_matches_actual_site__c = 'No';
        qc.Floors_covered__c = 'No';
        qc.Free_of_grout_haze__c = 'No';
        qc.Gaps_at_base__c = 'No';
        qc.Gaps_at_stairs__c = 'No';
        qc.Grout_filled_at_top_of_showers__c = 'No';
        qc.Grout_joints_properly_spaced__c = 'No';
        qc.Grout_joints_spaced_properly__c = 'No';
        qc.Gout_voids__c = 'No';
        qc.House_garage_perimeter_clean_of_trash__c = 'No';
        qc.Installed_flat_with_industry_specs__c = 'No';
        qc.Installed_per_diagram__c = 'No';
        qc.Installed_square_to_room__c = 'No';
        qc.Is_grout_color_same_throughout__c = 'No';
        qc.Is_House_Painted__c = 'No';
        qc.Is_Tile_fully_bonded__c = 'No';
        qc.Is_trim_baseboards_installed__c = 'No';
        qc.Is_Tub_Deck_Ready_for_Install__c = 'No';
        qc.Joint_spacing_between_boards_row_to_row__c = 'No';
        qc.Missing_Grout__c = 'No';
        qc.No_damage_to_baseboards__c = 'No';
        qc.No_damage_to_tubs_pans__c = 'No';
        qc.Pan_square__c = 'No';
        qc.Proper_spacing_at_baseboards_fireplace__c = 'No';
        qc.Protecting_grg_floor_while_mix_cutting__c = 'No';
        qc.Seams_acceptable__c = 'No';
        qc.Seam_sealer_installed__c = 'No';
        qc.Spot_bonding__c = 'No';
        qc.Stained_shoe_trim_stairnose_match__c = 'No';
        qc.Tile_cut_off_on_correct_side_door_jamb__c = 'No';
        qc.Trim_installed__c = 'No';
        qc.Trimmed_out__c = 'No';
        qc.Tubs_pans_covered_protected__c = 'No';
        qc.Using_eye_protection_hard_hats__c = 'No';
        qc.Wall_board_installed_w_screws_spacing__c = 'No';
        qc.Weep_holes_clear_free_of_grout__c = 'No';
        // this is to avoid validation error
        qc.Picture_Shower_Bath_Field_Measure__c = 'Test.png';
        qc.Picture_Slab_Tolerance__c = 'Test.png';
        qc.Picture_Cabinets_Installed__c = 'Test.png';
        qc.Picture_Cabinets_Condition__c = 'Test.png';
        qc.Picture_Countertops_Installed__c = 'Test.png';
        qc.Picture_Extra_Material__c = 'Test.png';
        qc.Picture_Gap_Between_Tile_and_Tub__c = 'Test.png';
        qc.Picture_Garage_Cleaned__c = 'Test.png';
        qc.Picture_House_and_Perimeter_Clean__c = 'Test.png';
        qc.Picture_House_Painted__c = 'Test.png';
        qc.Picture_Pan_Square__c = 'Test.png';
        qc.Picture_Proper_Spacing_Baseboard_FirePl__c = 'Test.png';
        qc.Picture_Trim_Baseboard_Installed__c = 'Test.png';
        qc.Picture_Tub_Condition__c = 'Test.png';
        qc.Picture_Tub_Deck_Ready_For_Install__c = 'Test.png';
        qc.Picture_Wall_Plumb__c = 'Test.png';

        system.debug( 'updating QC= ' + qc );

        update qc;

        Test.stopTest();

        qc = [
                SELECT ID, House_Unit__c, Work_Order__c, Work_Order__r.Status
                        , Work_Order__r.Work_Order_Status__c
                        , Most_Recent_Case_Created__c
                        , Most_recent_Case_Created__r.Originating_QC__c
                        , Is_Tile_fully_bonded__c
                        , Work_Order__r.Has_QC__c, Work_Order__r.QC_Count__c
                FROM Quality_Control__c
                WHERE Id = :qc.Id
                LIMIT 1
        ];

        system.assert( qc.Most_recent_Case_Created__c != null, 'Test case creation' );
        system.assertEquals( qc.ID, qc.Most_recent_Case_Created__r.Originating_QC__c, 'Test case creation' );

        //system.assertEquals( SG_QualityControlHelper.DEFAULT_PICKLIST_VALUE
        //                , qc.Is_Tile_fully_bonded__c, 'Test picklist defaulted' );

//        qc = [
//                SELECT ID, House_Unit__c, Work_Order__c, Work_Order__r.Status
//                        , Work_Order__r.Work_Order_Status__c
//                        , Most_Recent_Case_Created__c, Most_recent_Case_Created__r.Originating_QC__c
//                        , Is_Tile_fully_bonded__c
//                FROM Quality_Control__c
//                WHERE House_Unit__r.Name = '1313 Mockingbird'
//                    AND Work_Order__r.Job_Type__c = 'QC Pre-Walk'
//                LIMIT 1
//        ];
        system.debug( 'qc= ' + qc );

        system.assertEquals( SG_QualityControlHelper.COMPLETED_CUSTOM_STATUS
                        , qc.Work_Order__r.Work_Order_Status__c, 'Test CUSTOM work order status' );

        system.assertEquals( true, qc.Work_Order__r.Has_QC__c, 'has QC flag on work order should be true' );

        system.assertEquals( 1, qc.Work_Order__r.QC_Count__c, 'QC count on work order should be 1' );

        // increase test coverage a bit
        String dummy = SG_QualityControlHelper.getStrippedName( 'test.jpg' );
        system.assertEquals( 'test', dummy, 'Test getStrippedName' );

        qc.Picture_Extra_Material__c = 'abc.jpg';
        Set<String> dummySet = SG_QualityControlHelper.getImagesFromHiddenField(
                        qc, 'Picture_Extra_Material__c' );
    }

    public static TestMethod void QCChangedTest() {
        Test.startTest();

        SG_QualityControlHelper.qcConfigList = new List<Quality_Control_Trigger_Case_Creation__mdt>();
        Quality_Control_Trigger_Case_Creation__mdt qcConfig = new Quality_Control_Trigger_Case_Creation__mdt();
        qcConfig.DeveloperName = 'Test Rule';
        qcConfig.MasterLabel = 'Test Rule';
        qcConfig.QC_Field_Name_to_Verify__c = 'Installed_per_diagram__c';
        qcconfig.QC_Field_Value__c = 'No';
        qcConfig.List_of_QC_Record_Types__c = 'QC_Wood_Install';
        qcConfig.Case_Subject__c = 'Testing QC Trigger';
        qcconfig.Case_Type__c = 'Repair';
        qcconfig.QC_Field_Name_for_Material_Option__c = 'Extra_material_in_attic_designated_area__c';
        qcConfig.Case_Material_If_Yes__c = 'Extra mat = Yes';
        qcconfig.Case_Material_If_No__c = 'Extra mat = No';
        SG_QualityControlHelper.qcConfigList.add( qcConfig );

        Quality_Control__c qc = [
                SELECT ID, House_Unit__c, Work_Order__c, Most_Recent_Case_Created__c
                FROM Quality_Control__c
                WHERE House_Unit__r.Name = '1313 Mockingbird'
                AND Work_Order__r.Job_Type__c = 'QC Pre-Walk'
                LIMIT 1
        ];

        qc.RecordTypeId = Schema.SObjectType.Quality_Control__c.getRecordTypeInfosByDeveloperName().get( 'QC_Wood_Install' ).getRecordTypeId();
        qc.Installed_per_diagram__c = 'No';
        qc.Extra_material_in_attic_designated_area__c = 'No';
        update qc;

        Test.stopTest();

        qc = [
                SELECT ID, House_Unit__c, Work_Order__c, Work_Order__r.Status
                        , Most_Recent_Case_Created__c
                        , Most_recent_Case_Created__r.Subject
                        , Most_recent_Case_Created__r.Type
                        , Most_recent_Case_Created__r.Material__c
                        , Is_Tile_fully_bonded__c
                        , Work_Order__r.Has_QC__c, Work_Order__r.QC_Count__c
                FROM Quality_Control__c
                WHERE House_Unit__r.Name = '1313 Mockingbird'
                AND Work_Order__r.Job_Type__c = 'QC Pre-Walk'
                LIMIT 1
        ];

        //qcConfig = [
        //        SELECT ID, DeveloperName, MasterLabel
        //                , QC_Field_Name_to_Verify__c, QC_Field_Value__c
        //                , QC_Field_Name_for_Material_Option__c
        //                , Case_Material_If_Yes__c, Case_Material_If_No__c
        //                , List_of_QC_Record_Types__c
        //                , Case_Subject__c, Case_Type__c
        //        FROM Quality_Control_Trigger_Case_Creation__mdt
        //        WHERE QC_Field_Name_for_Material_Option__c != null
        //        LIMIT 1
        //];

        system.assert( qc.Most_recent_Case_Created__c != null, 'Test case creation' );
        system.assertEquals( qcConfig.Case_Subject__c, qc.Most_recent_Case_Created__r.Subject, 'Test case subject' );
        system.assertEquals( qcConfig.Case_Type__c, qc.Most_recent_Case_Created__r.Type, 'Test case type' );
        system.assertEquals( qcConfig.Case_Material_If_No__c, qc.Most_recent_Case_Created__r.Material__c, 'Test case material' );
    }
}