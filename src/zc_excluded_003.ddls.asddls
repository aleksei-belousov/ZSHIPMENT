@EndUserText.label: 'Excluded Deliveries'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define root view entity ZC_EXCLUDED_003 provider contract transactional_query as projection on ZI_EXCLUDED_003
{
    key ExcludedUUID,
    OutboundDelivery,
    SalesOrder, 
    PurchaseOrderByCustomer,
    OutboundDeliveryURL,
    SalesOrderURL,
    CreatedBy,
    CreatedAt,
    LastChangedBy,
    LastChangedAt,
    LocalLastChangedAt
}
