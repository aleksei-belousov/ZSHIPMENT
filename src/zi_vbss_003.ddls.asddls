@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Collective Processing Document'

define view entity ZI_VBSS_003 as select from zvbss003 as CollectiveProcessingDocument
association to parent ZI_VBSK_003 as _CollectiveProcessing on $projection.ZvbskUUID = _CollectiveProcessing.ZvbskUUID
{
    key zvbssuuid as ZvbssUUID,
    collectiveprocessingdocument as CollectiveProcessingDocument,
    zvbskuuid as ZvbskUUID, // ref to Collective Processing
    createdby as CreatedBy,
    createdat as CreatedAt,
    lastchangedby as LastChangedBy,
    lastchangedat as LastChangedAt,
    locallastchangedat as LocalLastChangedat,
    _CollectiveProcessing // Make association public
}
