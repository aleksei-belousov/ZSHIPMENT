@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Shipment'
define root view entity ZI_SHIPMENT_003 as select from zshipment003 as Shipment
composition [0..*] of ZI_AVAILABLE_003 as _Available
composition [0..*] of ZI_ADDED_003 as _Added
{
    key shipmentuuid as ShipmentUUID,
    shipmentid as ShipmentID,
    collectiveprocessing as CollectiveProcessing, 
    soldtoparty as SoldToParty,
    released as Released,
    
    createdby as CreatedBy,
    createdat as CreatedAt,
    lastchangedby as LastChangedBy,
    lastchangedat as LastChangedAt,
    locallastchangedat as LocalLastChangedAt,

    _Available, // Make association public
    _Added // Make association public
}
