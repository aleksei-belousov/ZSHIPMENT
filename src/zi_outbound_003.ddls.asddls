@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Outbound'

define view entity ZI_OUTBOUND_003 as select from zoutbound003
association to parent ZI_SHIPMENT_003 as _Shipment on $projection.ShipmentUUID = _Shipment.ShipmentUUID
association [0..1] to I_DeliveryDocument as _DeliveryDocument on $projection.OutboundDelivery = _DeliveryDocument.DeliveryDocument
association [0..1] to I_OutboundDelivery as _OutboundDelivery on $projection.OutboundDelivery = _OutboundDelivery.OutboundDelivery
{
    key outbounduuid as OutboundUUID,

    selected as Selected,
    outboundid as OutboundID,
    shipmentuuid as ShipmentUUID,

    outbounddelivery as OutboundDelivery, 
    salesorder as SalesOrder,
    purchaseorderbycustomer as PurchaseOrderByCustomer,
     
    outbounddeliveryurl as OutboundDeliveryURL, 
    salesorderurl as SalesOrderURL, 

    createdby as Createdby,
    createdat as Createdat,
    lastchangedby as Lastchangedby,
    lastchangedat as Lastchangedat,
    locallastchangedat as Locallastchangedat,
    
    _Shipment, // Make association public
    _DeliveryDocument, // Make association public
    _OutboundDelivery // Make association public

}
