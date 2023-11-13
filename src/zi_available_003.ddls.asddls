@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Available'
define view entity ZI_AVAILABLE_003 as select from zavailable003
association to parent ZI_SHIPMENT_003 as _Shipment on $projection.ShipmentUUID = _Shipment.ShipmentUUID
{
    key availableuuid as AvailableUUID,
    shipmentuuid as ShipmentUUID,
    outbounddelivery as OutboundDelivery,
    createdby as CreatedBy,
    createdat as Createdat,
    lastchangedby as LastChangedBy,
    lastchangedat as LastChangedAt,
    locallastchangedat as LocalLastChangedAt,
    _Shipment // Make association public
}
