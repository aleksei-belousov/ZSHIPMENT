@EndUserText.label: 'ZC_REPORITORY_004'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true

define root view entity ZC_REPORITORY_004 provider contract transactional_query as projection on ZI_REPORITORY_004
{
    key ZreporitoryUUID,
    Comments,
    Attachment,
    MimeType,
    FileName,
    XDP,
    MimeType1,
    FileName1,
    PDF,
    MimeType2,
    FileName2,
    CreatedBy,
    CreatedAt,
    LastChangedBy,
    LastChangedAt,
    LocalLastChangedAt
}
