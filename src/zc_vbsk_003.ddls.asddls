@EndUserText.label: 'Collective Processing'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define root view entity ZC_VBSK_003 provider contract transactional_query as projection on ZI_VBSK_003 as CollectiveProcessing 
{
    key ZvbskUUID,

    CollectiveProcessing,

    CreatedBy,
    CreatedAt,
    LastChangedBy,
    LastChangedAt,
    LocalLastChangedAt,

    /* Associations */
    _CollectiveProcessingDocument: redirected to composition child ZC_VBSS_003
}
