@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Attachment'
define view entity ZI_ATTACHMENT_003 as select from zattachment003
association to parent ZI_SHIPMENT_003 as _Shipment on $projection.ShipmentUUID = _Shipment.ShipmentUUID
{
    key attachmentuuid as AttachmentUUID,
    attachmentid as AttachmentID,

    shipmentuuid as ShipmentUUID,

    @Semantics.largeObject:
    { mimeType: 'MimeType',
    fileName: 'FileName',
    contentDispositionPreference: #INLINE }
    attachment as Attachment,

    @Semantics.mimeType: true
    mimetype as MimeType,
    filename as FileName,

    createdby as Createdby,
    createdat as Createdat,
    lastchangedby as Lastchangedby,
    lastchangedat as Lastchangedat,
    locallastchangedat as Locallastchangedat,
    
    _Shipment // Make association public
}
