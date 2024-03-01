@EndUserText.label: 'Shipment'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true

define root view entity ZC_SHIPMENT_003 provider contract transactional_query as projection on ZI_SHIPMENT_003 as Shipment
{
    key ShipmentUUID,
    ShipmentID,

    @Consumption.valueHelpDefinition: [ { entity: { name: 'I_Customer', element: 'Customer' }, useForValidation: true } ]
    @ObjectModel.foreignKey.association: '_Customer'
    @EndUserText.label: 'Sold To Party'
    @ObjectModel.text.element: ['CustomerName']
    SoldToParty as SoldToParty,
    _Customer.CustomerName as CustomerName,
    
    @EndUserText.label: 'Released'
    Released,
    
    ConfirmationDate,

    Tour,
    TransportationType, 
    FreightForwarderClient,
    
    @Consumption.valueHelpDefinition: [ { entity: { name: 'I_Customer', element: 'Customer' } } ]
    @EndUserText.label: 'Party ID'
    PartyID,
    
    @Consumption.valueHelpDefinition: [ { entity: { name: 'I_Customer', element: 'Customer' } } ]
    @EndUserText.label: 'Import Invoice Recipient'
    ImportInvoiceRecipient, 

    OrganisationFormattedName1,
    OrganisationFormattedName2,
    OrganisationFormattedName3,
    OrganisationFormattedName4,
    StreetName,
    HouseID,
    CityName,
    CountryCode,
    TaxJurisdictionCode,
    StreetPostalCode,
    Instructions,
    ReleaseDate,
    CreationDate,
         
    PartyURL,
    ImportInvoiceRecipientURL,
    
    _BuPaIdentification.BPIdentificationNumber as BPIdentificationNumber,
    
    CreatedBy,
    CreatedAt,
    LastChangedBy,
    LastChangedAt,
    LocalLastChangedAt,

    /* Associations */
    _Available: redirected to composition child ZC_AVAILABLE_003,
    _Outbound: redirected to composition child ZC_OUTBOUND_003,
    _Attachment: redirected to composition child ZC_ATTACHMENT_003,
    _Customer,
    _BuPaIdentification // Make association public

}
