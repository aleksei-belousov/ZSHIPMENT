/********** GENERATED on 11/23/2023 at 12:01:49 by CB9980000024**************/

 @OData.entitySet.name: 'I_DraftAdministrativeData' 
 @OData.entityType.name: 'I_DraftAdministrativeDataType' 
 define root abstract entity ZRAP_I_DRAFTADMINIST912358B8E7 { 
 key DraftUUID : sysuuid_x16 ; 
 key DraftEntityType : abap.char( 30 ) ; 
 @OData.property.valueControl: 'CreationDateTime_vc' 
 CreationDateTime : tzntstmpl ; 
 CreationDateTime_vc : rap_cp_odata_value_control ; 
 @OData.property.valueControl: 'CreatedByUser_vc' 
 CreatedByUser : abap.char( 12 ) ; 
 CreatedByUser_vc : rap_cp_odata_value_control ; 
 @OData.property.valueControl: 'LastChangeDateTime_vc' 
 LastChangeDateTime : tzntstmpl ; 
 LastChangeDateTime_vc : rap_cp_odata_value_control ; 
 @OData.property.valueControl: 'LastChangedByUser_vc' 
 LastChangedByUser : abap.char( 12 ) ; 
 LastChangedByUser_vc : rap_cp_odata_value_control ; 
 @OData.property.valueControl: 'DraftAccessType_vc' 
 DraftAccessType : abap.char( 1 ) ; 
 DraftAccessType_vc : rap_cp_odata_value_control ; 
 @OData.property.valueControl: 'ProcessingStartDateTime_vc' 
 ProcessingStartDateTime : tzntstmpl ; 
 ProcessingStartDateTime_vc : rap_cp_odata_value_control ; 
 @OData.property.valueControl: 'InProcessByUser_vc' 
 InProcessByUser : abap.char( 12 ) ; 
 InProcessByUser_vc : rap_cp_odata_value_control ; 
 @OData.property.valueControl: 'DraftIsKeptByUser_vc' 
 DraftIsKeptByUser : abap_boolean ; 
 DraftIsKeptByUser_vc : rap_cp_odata_value_control ; 
 @OData.property.valueControl: 'EnqueueStartDateTime_vc' 
 EnqueueStartDateTime : tzntstmpl ; 
 EnqueueStartDateTime_vc : rap_cp_odata_value_control ; 
 @OData.property.valueControl: 'DraftIsCreatedByMe_vc' 
 DraftIsCreatedByMe : abap_boolean ; 
 DraftIsCreatedByMe_vc : rap_cp_odata_value_control ; 
 @OData.property.valueControl: 'DraftIsLastChangedByMe_vc' 
 DraftIsLastChangedByMe : abap_boolean ; 
 DraftIsLastChangedByMe_vc : rap_cp_odata_value_control ; 
 @OData.property.valueControl: 'DraftIsProcessedByMe_vc' 
 DraftIsProcessedByMe : abap_boolean ; 
 DraftIsProcessedByMe_vc : rap_cp_odata_value_control ; 
 @OData.property.valueControl: 'CreatedByUserDescription_vc' 
 CreatedByUserDescription : abap.char( 80 ) ; 
 CreatedByUserDescription_vc : rap_cp_odata_value_control ; 
 @OData.property.valueControl: 'LastChangedByUserDescriptio_vc' 
 LastChangedByUserDescription : abap.char( 80 ) ; 
 LastChangedByUserDescriptio_vc : rap_cp_odata_value_control ; 
 @OData.property.valueControl: 'InProcessByUserDescription_vc' 
 InProcessByUserDescription : abap.char( 80 ) ; 
 InProcessByUserDescription_vc : rap_cp_odata_value_control ; 
 ETAG__ETAG : abap.string( 0 ) ; 
 
 } 
