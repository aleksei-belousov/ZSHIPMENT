@EndUserText.label: 'Collective Processing Document'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true

define view entity ZC_VBSS_003 as projection on ZI_VBSS_003 as CollectiveProcessingDocument
{
    key ZvbssUUID,

    @Consumption.valueHelpDefinition: [ { entity: { name: 'I_OutboundDelivery', element: 'OutboundDelivery' } } ]
    @EndUserText.label: 'Collective Processing'
    CollectiveProcessingDocument,

    ZvbskUUID,

    CreatedBy,
    CreatedAt,
    LastChangedBy,
    LastChangedAt,
    LocalLastChangedat,
    
    /* Associations */
    _CollectiveProcessing : redirected to parent ZC_VBSK_003
}
