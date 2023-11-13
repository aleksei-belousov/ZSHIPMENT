@EndUserText.label: 'Available'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define view entity ZC_AVAILABLE_003 as projection on ZI_AVAILABLE_003 as Available
{
    key AvailableUUID,
    ShipmentUUID,
    OutboundDelivery,
    CreatedBy,
    Createdat,
    LastChangedBy,
    LastChangedAt,
    LocalLastChangedAt,
    /* Associations */
    _Shipment : redirected to parent ZC_SHIPMENT_003
}
