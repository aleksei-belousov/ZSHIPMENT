@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Collective Processing'

define root view entity ZI_VBSK_003 as select from zvbsk003 as CollectiveProcessing
composition [0..*] of ZI_VBSS_003 as _CollectiveProcessingDocument
{
    key zvbskuuid as ZvbskUUID,
    collectiveprocessing as CollectiveProcessing,
    createdby as CreatedBy,
    createdat as CreatedAt,
    lastchangedby as LastChangedBy,
    lastchangedat as LastChangedAt,
    locallastchangedat as LocalLastChangedAt,
    _CollectiveProcessingDocument // Make association public
}
