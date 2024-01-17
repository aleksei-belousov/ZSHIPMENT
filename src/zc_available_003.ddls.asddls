@EndUserText.label: 'Available'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true

define view entity ZC_AVAILABLE_003 as projection on ZI_AVAILABLE_003 as Available
{
    key AvailableUUID,
    AvailableID,
    ShipmentUUID,

    @Consumption.valueHelpDefinition: [ { entity: { name: 'I_OutboundDeliveryTP', element: 'OutboundDelivery' },
                                          additionalBinding : [ { localElement: 'SoldToParty', element : 'SoldToParty', usage: #FILTER } ] } ] 
    @EndUserText.label: 'Outbound Delivery'
    OutboundDelivery,

    OutboundDeliveryURL,
    _DeliveryDocument.UnloadingPointName as UnloadingPointName,
    _Shipment.SoldToParty as SoldToParty, 

    CreatedBy,
    Createdat,
    LastChangedBy,
    LastChangedAt,
    LocalLastChangedAt,
    
    /* Associations */
    _Shipment : redirected to parent ZC_SHIPMENT_003,
    _DeliveryDocument
}
