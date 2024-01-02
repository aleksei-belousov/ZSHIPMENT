@EndUserText.label: 'Repository'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true


define root view entity ZC_REPOSITORY_003 provider contract transactional_query as projection on ZI_REPOSITORY_003
{
    key RepositoryUUID,
    RepositoryID,
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
