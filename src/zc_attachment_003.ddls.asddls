@EndUserText.label: 'Attachment'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true

define view entity ZC_ATTACHMENT_003 as projection on ZI_ATTACHMENT_003
{
    key AttachmentUUID,

    AttachmentID,
    ShipmentUUID,

    Attachment,
    MimeType,
    FileName,

    Createdby,
    Createdat,
    Lastchangedby,
    Lastchangedat,
    Locallastchangedat,

    /* Associations */
    _Shipment : redirected to parent ZC_SHIPMENT_003
}
