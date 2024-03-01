@EndUserText.label: 'Outbound'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true

define view entity ZC_OUTBOUND_003 as projection on ZI_OUTBOUND_003 as Outbound
{
    key OutboundUUID,

    Selected,
    OutboundID,
    ShipmentUUID,

    @Consumption.valueHelpDefinition: [ { entity: { name: 'I_OutboundDeliveryTP', element: 'OutboundDelivery' },
                                          additionalBinding : [ { localElement: 'SoldToParty', element : 'SoldToParty', usage: #FILTER } ] } ] 
    @EndUserText.label: 'Outbound Delivery'
    OutboundDelivery, 

    _DeliveryDocument.UnloadingPointName as UnloadingPointName,
    _Shipment.SoldToParty as SoldToParty, 

    _DeliveryDocument.CreationDate as CreationDate,
    _DeliveryDocument.OverallGoodsMovementStatus as OverallGoodsMovementStatus,
    _DeliveryDocument.OverallSDProcessStatus as OverallSDProcessStatus,
    _DeliveryDocument.DeliveryDate as DeliveryDate,
    _DeliveryDocument.DocumentDate as DocumentDate,

    SalesOrder,
    PurchaseOrderByCustomer,
        
    OutboundDeliveryURL,
    SalesOrderURL, 
    
    Createdby,
    Createdat,
    Lastchangedby,
    Lastchangedat,
    Locallastchangedat,

    /* Associations */
    _Shipment : redirected to parent ZC_SHIPMENT_003,
    _DeliveryDocument
    
}
