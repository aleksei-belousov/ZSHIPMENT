@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Added'

define view entity ZI_ADDED_003 as select from zadded003
association to parent ZI_SHIPMENT_003 as _Shipment on $projection.ShipmentUUID = _Shipment.ShipmentUUID
{
    key addeduuid as AddedUUID,
    shipmentuuid as ShipmentUUID,
    outbounddelivery as OutboundDelivery,
    createdby as CreatedBy,
    createdat as CreatedAt,
    lastchangedby as LastChangedBy,
    lastchangedat as LastChangedAt,
    locallastchangedat as LocalLastChangedAt,
    _Shipment // Make association public
}
