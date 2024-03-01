@EndUserText.label: 'Available'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true

define view entity ZC_AVAILABLE_003 as projection on ZI_AVAILABLE_003 as Available
{
    key AvailableUUID,

    Selected,
    //AvailableID,
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

    CreatedBy,
    Createdat,
    LastChangedBy,
    LastChangedAt,
    LocalLastChangedAt,
    
    /* Associations */
    _Shipment : redirected to parent ZC_SHIPMENT_003,
    _DeliveryDocument
}
