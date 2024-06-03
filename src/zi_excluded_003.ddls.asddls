@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Excluded Deliveries'
define root view entity ZI_EXCLUDED_003 as select from zexcluded003 as Excluded
{
    key excludeduuid as ExcludedUUID,
    outbounddelivery as OutboundDelivery,
    salesorder as SalesOrder, 
    purchaseorderbycustomer as PurchaseOrderByCustomer,
    outbounddeliveryurl as OutboundDeliveryURL,
    salesorderurl as SalesOrderURL,
    createdby as CreatedBy,
    createdat as CreatedAt,
    lastchangedby as LastChangedBy,
    lastchangedat as LastChangedAt,
    locallastchangedat as LocalLastChangedAt
}
