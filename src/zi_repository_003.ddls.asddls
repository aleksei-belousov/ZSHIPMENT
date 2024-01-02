@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Repository'

define root view entity ZI_REPOSITORY_003 as select from zrepository003
{
    key repositoryuuid as RepositoryUUID,

    repositoryid as RepositoryID,
    comments as Comments,

    @Semantics.largeObject:
    { mimeType: 'MimeType',
    fileName: 'FileName',
    contentDispositionPreference: #INLINE }
    attachment as Attachment,

    @Semantics.mimeType: true
    mimetype as MimeType,
    filename as FileName,

    @Semantics.largeObject:
    { mimeType: 'MimeType1',
    fileName: 'FileName1',
    contentDispositionPreference: #INLINE }
    xdp as XDP,

    @Semantics.mimeType: true
    mimetype1 as MimeType1,
    filename1 as FileName1,

    @Semantics.largeObject:
    { mimeType: 'MimeType2',
    fileName: 'FileName2',
    contentDispositionPreference: #INLINE }
    pdf as PDF,

    @Semantics.mimeType: true
    mimetype2 as MimeType2,
    filename2 as FileName2,

    createdby as CreatedBy,
    createdat as CreatedAt,
    lastchangedby as LastChangedBy,
    lastchangedat as LastChangedAt,
    locallastchangedat as LocalLastChangedAt
}
