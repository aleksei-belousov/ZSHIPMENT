@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Available'

define view entity ZI_AVAILABLE_003 as select from zavailable003
association to parent ZI_SHIPMENT_003 as _Shipment on $projection.ShipmentUUID = _Shipment.ShipmentUUID
association [0..1] to I_DeliveryDocument as _DeliveryDocument on $projection.OutboundDelivery = _DeliveryDocument.DeliveryDocument
association [0..1] to I_OutboundDelivery as _OutboundDelivery on $projection.OutboundDelivery = _OutboundDelivery.OutboundDelivery
{
    key availableuuid as AvailableUUID,

    selected as Selected,
    //availableid as AvailableID,
    shipmentuuid as ShipmentUUID,
    
    outbounddelivery as OutboundDelivery,
    salesorder as SalesOrder,
    purchaseorderbycustomer as PurchaseOrderByCustomer,

    outbounddeliveryurl as OutboundDeliveryURL,
    salesorderurl as SalesOrderURL, 

    createdby as CreatedBy,
    createdat as Createdat,
    lastchangedby as LastChangedBy,
    lastchangedat as LastChangedAt,
    locallastchangedat as LocalLastChangedAt,

    _Shipment, // Make association public
    _DeliveryDocument, // Make association public
    _OutboundDelivery // Make association public
    
}
