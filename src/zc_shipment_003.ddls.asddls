@EndUserText.label: 'Shipment'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define root view entity ZC_SHIPMENT_003 provider contract transactional_query as projection on ZI_SHIPMENT_003 as Shipment
{
    key ShipmentUUID,

    @Consumption.valueHelpDefinition: [ { entity: { name: 'ZI_VBSK_003', element: 'CollectiveProcessing' } } ]
    @EndUserText.label: 'Collective Processing'
    CollectiveProcessing, 

    CreatedBy,
    CreatedAt,
    LastChangedBy,
    LastChangedAt,
    LocalLastChangedAt,

    /* Associations */
    _Available: redirected to composition child ZC_AVAILABLE_003,
    _Added: redirected to composition child ZC_ADDED_003

}
