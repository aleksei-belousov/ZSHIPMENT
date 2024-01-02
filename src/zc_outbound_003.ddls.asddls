@EndUserText.label: 'Outbound'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true

define view entity ZC_OUTBOUND_003 as projection on ZI_OUTBOUND_003
{
    key OutboundUUID,
    OutboundID,
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
