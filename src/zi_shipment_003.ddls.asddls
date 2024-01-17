@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Shipment'

/*+[hideWarning] { "IDS" : [ "CARDINALITY_CHECK" ]  } */
define root view entity ZI_SHIPMENT_003 as select from zshipment003 as Shipment
composition [0..*] of ZI_AVAILABLE_003 as _Available
composition [0..*] of ZI_OUTBOUND_003 as _Outbound
association [0..1] to I_Customer as _Customer on $projection.SoldToParty = _Customer.Customer
association [0..1] to I_BuPaIdentification as _BuPaIdentification on $projection.PartyID = _BuPaIdentification.BusinessPartner and _BuPaIdentification.BPIdentificationType = 'BUP005'
{
    key shipmentuuid as ShipmentUUID,
    shipmentid as ShipmentID,
    collectiveprocessing as CollectiveProcessing, 
    soldtoparty as SoldToParty,
    released as Released,
    confirmationdate as ConfirmationDate,
    
    tour as Tour,
    transportationtype as TransportationType, 
    freightforwarderclient as FreightForwarderClient,
    partyid as PartyID,
    organisationformattedname1 as OrganisationFormattedName1,
    organisationformattedname2 as OrganisationFormattedName2,
    organisationformattedname3 as OrganisationFormattedName3,
    organisationformattedname4 as OrganisationFormattedName4,
    streetname as StreetName,
    houseid as HouseID,
    cityname as CityName,
    countrycode as CountryCode,
    taxjurisdictioncode as TaxJurisdictionCode,
    streetpostalcode as StreetPostalCode,
    instructions as Instructions,
    partyurl as PartyURL,

    createdby as CreatedBy,
    createdat as CreatedAt,
    lastchangedby as LastChangedBy,
    lastchangedat as LastChangedAt,
    locallastchangedat as LocalLastChangedAt,

    _Available, // Make association public
    _Outbound, // Make association public
    _Customer, // Make association public
    _BuPaIdentification // Make association public
}
