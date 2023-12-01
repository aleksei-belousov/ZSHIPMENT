/********** GENERATED on 11/23/2023 at 12:01:49 by CB9980000024**************/
 @OData.entitySet.name: 'I_DraftAdministrativeData' 
 @OData.entityType.name: 'I_DraftAdministrativeDataType' 
 define root abstract entity ZRAP_I_DRAFTADMINIST912358B8E7 { 
 key DraftUUID : sysuuid_x16 ; 
 key DraftEntityType : abap.char( 30 ) ; 
 @Odata.property.valueControl: 'CreationDateTime_vc' 
 CreationDateTime : tzntstmpl ; 
 CreationDateTime_vc : RAP_CP_ODATA_VALUE_CONTROL ; 
 @Odata.property.valueControl: 'CreatedByUser_vc' 
 CreatedByUser : abap.char( 12 ) ; 
 CreatedByUser_vc : RAP_CP_ODATA_VALUE_CONTROL ; 
 @Odata.property.valueControl: 'LastChangeDateTime_vc' 
 LastChangeDateTime : tzntstmpl ; 
 LastChangeDateTime_vc : RAP_CP_ODATA_VALUE_CONTROL ; 
 @Odata.property.valueControl: 'LastChangedByUser_vc' 
 LastChangedByUser : abap.char( 12 ) ; 
 LastChangedByUser_vc : RAP_CP_ODATA_VALUE_CONTROL ; 
 @Odata.property.valueControl: 'DraftAccessType_vc' 
 DraftAccessType : abap.char( 1 ) ; 
 DraftAccessType_vc : RAP_CP_ODATA_VALUE_CONTROL ; 
 @Odata.property.valueControl: 'ProcessingStartDateTime_vc' 
 ProcessingStartDateTime : tzntstmpl ; 
 ProcessingStartDateTime_vc : RAP_CP_ODATA_VALUE_CONTROL ; 
 @Odata.property.valueControl: 'InProcessByUser_vc' 
 InProcessByUser : abap.char( 12 ) ; 
 InProcessByUser_vc : RAP_CP_ODATA_VALUE_CONTROL ; 
 @Odata.property.valueControl: 'DraftIsKeptByUser_vc' 
 DraftIsKeptByUser : abap_boolean ; 
 DraftIsKeptByUser_vc : RAP_CP_ODATA_VALUE_CONTROL ; 
 @Odata.property.valueControl: 'EnqueueStartDateTime_vc' 
 EnqueueStartDateTime : tzntstmpl ; 
 EnqueueStartDateTime_vc : RAP_CP_ODATA_VALUE_CONTROL ; 
 @Odata.property.valueControl: 'DraftIsCreatedByMe_vc' 
 DraftIsCreatedByMe : abap_boolean ; 
 DraftIsCreatedByMe_vc : RAP_CP_ODATA_VALUE_CONTROL ; 
 @Odata.property.valueControl: 'DraftIsLastChangedByMe_vc' 
 DraftIsLastChangedByMe : abap_boolean ; 
 DraftIsLastChangedByMe_vc : RAP_CP_ODATA_VALUE_CONTROL ; 
 @Odata.property.valueControl: 'DraftIsProcessedByMe_vc' 
 DraftIsProcessedByMe : abap_boolean ; 
 DraftIsProcessedByMe_vc : RAP_CP_ODATA_VALUE_CONTROL ; 
 @Odata.property.valueControl: 'CreatedByUserDescription_vc' 
 CreatedByUserDescription : abap.char( 80 ) ; 
 CreatedByUserDescription_vc : RAP_CP_ODATA_VALUE_CONTROL ; 
 @Odata.property.valueControl: 'LastChangedByUserDescriptio_vc' 
 LastChangedByUserDescription : abap.char( 80 ) ; 
 LastChangedByUserDescriptio_vc : RAP_CP_ODATA_VALUE_CONTROL ; 
 @Odata.property.valueControl: 'InProcessByUserDescription_vc' 
 InProcessByUserDescription : abap.char( 80 ) ; 
 InProcessByUserDescription_vc : RAP_CP_ODATA_VALUE_CONTROL ; 
 ETAG__ETAG : abap.string( 0 ) ; 
 
 } 
