/********** GENERATED on 11/23/2023 at 12:02:06 by CB9980000024**************/

 @OData.entitySet.name: 'ZC_SHIPMENT_003' 
 @OData.entityType.name: 'ZC_SHIPMENT_003Type' 

/*+[hideWarning] { "IDS" : [ "CARDINALITY_CHECK" ] }*/
 define root abstract entity ZRAP_ZC_SHIPMENT_003 { 
 key ShipmentUUID : sysuuid_x16 ; 
 key IsActiveEntity : abap_boolean ; 
 @OData.property.valueControl: 'ShipmentID_vc' 
 ShipmentID : abap.numc( 10 ) ; 
 ShipmentID_vc : rap_cp_odata_value_control ; 
 @OData.property.valueControl: 'CollectiveProcessing_vc' 
 CollectiveProcessing : abap.char( 10 ) ; 
 CollectiveProcessing_vc : rap_cp_odata_value_control ; 
 @OData.property.valueControl: 'SoldToParty_vc' 
 SoldToParty : abap.char( 10 ) ; 
 SoldToParty_vc : rap_cp_odata_value_control ; 
 @OData.property.valueControl: 'Released_vc' 
 Released : abap_boolean ; 
 Released_vc : rap_cp_odata_value_control ; 
 @OData.property.valueControl: 'ConfirmationDate_vc' 
 ConfirmationDate : rap_cp_odata_v2_edm_datetime ; 
 ConfirmationDate_vc : rap_cp_odata_value_control ; 
 @OData.property.valueControl: 'CreatedBy_vc' 
 CreatedBy : abap.char( 12 ) ; 
 CreatedBy_vc : rap_cp_odata_value_control ; 
 @OData.property.valueControl: 'CreatedAt_vc' 
 CreatedAt : tzntstmpl ; 
 CreatedAt_vc : rap_cp_odata_value_control ; 
 @OData.property.valueControl: 'LastChangedBy_vc' 
 LastChangedBy : abap.char( 12 ) ; 
 LastChangedBy_vc : rap_cp_odata_value_control ; 
 @OData.property.valueControl: 'LastChangedAt_vc' 
 LastChangedAt : tzntstmpl ; 
 LastChangedAt_vc : rap_cp_odata_value_control ; 
 @OData.property.valueControl: 'LocalLastChangedAt_vc' 
 LocalLastChangedAt : tzntstmpl ; 
 LocalLastChangedAt_vc : rap_cp_odata_value_control ; 
 @OData.property.valueControl: 'HasDraftEntity_vc' 
 HasDraftEntity : abap_boolean ; 
 HasDraftEntity_vc : rap_cp_odata_value_control ; 
 @OData.property.valueControl: 'DraftEntityCreationDateTime_vc' 
 DraftEntityCreationDateTime : tzntstmpl ; 
 DraftEntityCreationDateTime_vc : rap_cp_odata_value_control ; 
 @OData.property.valueControl: 'DraftEntityLastChangeDateTi_vc' 
 DraftEntityLastChangeDateTime : tzntstmpl ; 
 DraftEntityLastChangeDateTi_vc : rap_cp_odata_value_control ; 
 @OData.property.valueControl: 'HasActiveEntity_vc' 
 HasActiveEntity : abap_boolean ; 
 HasActiveEntity_vc : rap_cp_odata_value_control ; 
 ETAG__ETAG : abap.string( 0 ) ; 
 
 @OData.property.name: 'DraftAdministrativeData' 
//A dummy on-condition is required for associations in abstract entities 
//On-condition is not relevant for runtime 
 _DraftAdministrativeData12 : association [1] to ZRAP_I_DRAFTADMINIST912358B8E7 on 1 = 1; 
 @OData.property.name: 'to_Added' 
//A dummy on-condition is required for associations in abstract entities 
//On-condition is not relevant for runtime 
 _Added : association [0..*] to ZRAP_ZC_ADDED_003 on 1 = 1; 
 @OData.property.name: 'to_Available' 
//A dummy on-condition is required for associations in abstract entities 
//On-condition is not relevant for runtime 
 _Available : association [0..*] to ZRAP_ZC_AVAILABLE_003 on 1 = 1; 
 } 
