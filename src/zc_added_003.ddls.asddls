@EndUserText.label: 'Added'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true

define view entity ZC_ADDED_003 as projection on ZI_ADDED_003 as Added
{
    key AddedUUID,
    ShipmentUUID,
    OutboundDelivery,
    CreatedBy,
    CreatedAt,
    LastChangedBy,
    LastChangedAt,
    LocalLastChangedAt,
    /* Associations */
    _Shipment : redirected to parent ZC_SHIPMENT_003
}
