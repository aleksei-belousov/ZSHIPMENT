CLASS lhc_shipment DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Shipment RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Shipment RESULT result.

    METHODS Activate FOR MODIFY
      IMPORTING keys FOR ACTION Shipment~Activate.

    METHODS Edit FOR MODIFY
      IMPORTING keys FOR ACTION Shipment~Edit.

    METHODS Resume FOR MODIFY
      IMPORTING keys FOR ACTION Shipment~Resume.

    METHODS release FOR MODIFY
      IMPORTING keys FOR ACTION Shipment~release.

    METHODS on_create FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Shipment~on_create.

    METHODS on_save_customer FOR DETERMINE ON SAVE
      IMPORTING keys FOR Shipment~on_save_customer.

    METHODS on_modify_customer FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Shipment~on_modify_customer.

    METHODS create_invoice FOR MODIFY
      IMPORTING keys FOR ACTION Shipment~create_invoice.

    METHODS create_tkz_list FOR MODIFY
      IMPORTING keys FOR ACTION Shipment~create_tkz_list.

    METHODS create_tariff_document FOR MODIFY
      IMPORTING keys FOR ACTION Shipment~create_tariff_document.

    METHODS create_eci FOR MODIFY
      IMPORTING keys FOR ACTION Shipment~create_eci.



******** Internal Methods *********

    METHODS get_texts_internal
      IMPORTING VALUE(i_customer)               TYPE string
                VALUE(i_sales_organization)     TYPE string
                VALUE(i_distribution_channel)   TYPE string
                VALUE(i_division)               TYPE string
                VALUE(i_language)               TYPE string
                VALUE(i_long_text_id)           TYPE string
      RETURNING VALUE(o_text)                   TYPE string.

    METHODS get_address_internal
      IMPORTING VALUE(i_customer)               TYPE string
      EXPORTING VALUE(o_street_name)            TYPE string
                VALUE(o_house_number)           TYPE string.

    METHODS get_forwarding_rule_internal
      IMPORTING VALUE(i_forwarding_rule_id)             TYPE string
      EXPORTING VALUE(o_transportation_type_shipment)   TYPE string
                VALUE(o_freight_forwarder_client)       TYPE string.

ENDCLASS. " lhc_shipment DEFINITION

CLASS lhc_shipment IMPLEMENTATION.

  METHOD get_instance_features.
  ENDMETHOD.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD Activate.

     " Read transfered instances
    READ ENTITIES OF zi_shipment_003 IN LOCAL MODE
        ENTITY Shipment
        ALL FIELDS
        WITH CORRESPONDING #( keys )
        RESULT DATA(entities).

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).

        IF ( <entity>-%is_draft = '00' ). " Saved
        ENDIF.
        IF ( <entity>-%is_draft = '01' ). " Draft
        ENDIF.

*       Generate and Set New Matrix ID
        IF ( <entity>-ShipmentID IS INITIAL ).

            DATA shipmentid TYPE zi_shipment_003-ShipmentID VALUE '0000000000'.
            SELECT MAX( shipmentid ) FROM zi_shipment_003 INTO (@shipmentid).
            shipmentid  = ( shipmentid + 1 ).

            MODIFY ENTITIES OF zi_shipment_003 IN LOCAL MODE
                ENTITY Shipment
                UPDATE FIELDS ( ShipmentID )
                WITH VALUE #( (
                    %tky        = <entity>-%tky
                    ShipmentID  = shipmentid
                ) )
                FAILED DATA(ls_failed1)
                MAPPED DATA(ls_mapped1)
                REPORTED DATA(ls_reported1).

         ENDIF.

    ENDLOOP.

  ENDMETHOD. " Activate

  METHOD Edit.
  ENDMETHOD. " Edit

  METHOD Resume.
  ENDMETHOD. " Resume

  METHOD release. " on Pressing Release button

    " Read transfered instances
    READ ENTITIES OF zi_shipment_003 IN LOCAL MODE
        ENTITY Shipment
        ALL FIELDS
        WITH CORRESPONDING #( keys )
        RESULT DATA(entities).

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).

        IF ( <entity>-%is_draft = '00' ). " Saved

            IF ( <entity>-Released = abap_true ).
*               Short format message
                APPEND VALUE #( %key = <entity>-%key %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error text = 'The Shipment Binding is already released.' ) ) TO reported-shipment.
                RETURN.
            ENDIF.

            READ ENTITIES OF zi_shipment_003  IN LOCAL MODE
                ENTITY Shipment
                BY \_Available
                ALL FIELDS WITH VALUE #( (
                    %tky = <entity>-%tky
                ) )
                RESULT DATA(lt_available)
                FAILED DATA(failed1)
                REPORTED DATA(reported1).

            IF ( lt_available[] IS INITIAL ).
*               Short format message
                APPEND VALUE #( %key = <entity>-%key %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error text = 'No Outbould Deliveres.' ) ) TO reported-shipment.
                RETURN.
            ENDIF.

            SORT lt_available STABLE BY OutboundDelivery.

            SELECT SINGLE BPIdentificationNumber FROM zc_shipment_003 WHERE ( ShipmentUUID = @<entity>-ShipmentUUID ) INTO @DATA(bpIdentificationNumber).

            DATA request_body TYPE string VALUE ''.

*           Make body as an XML
            request_body = request_body && '<ShipmentBinding>' && cl_abap_char_utilities=>cr_lf.
            request_body = request_body && '<ID>' && <entity>-ShipmentID && '</ID>' && cl_abap_char_utilities=>cr_lf.
            request_body = request_body && '<ConfirmationDate>' && <entity>-ConfirmationDate && '</ConfirmationDate>' && cl_abap_char_utilities=>cr_lf.
            request_body = request_body && '<Tour>' && <entity>-Tour && '</Tour>' && cl_abap_char_utilities=>cr_lf.
            request_body = request_body && '<TransportationType>' && <entity>-TransportationType && '</TransportationType>' && cl_abap_char_utilities=>cr_lf.
            request_body = request_body && '<FreightForwarderClient>' && <entity>-FreightForwarderClient && '</FreightForwarderClient>' && cl_abap_char_utilities=>cr_lf.
            request_body = request_body && '<PartyID>' && <entity>-PartyID && '</PartyID>' && cl_abap_char_utilities=>cr_lf.
            request_body = request_body && '<GLN>' && bpIdentificationNumber && '</GLN>' && cl_abap_char_utilities=>cr_lf.
            request_body = request_body && '<OrganisationFormattedName1>' && <entity>-OrganisationFormattedName1 && '</OrganisationFormattedName1>' && cl_abap_char_utilities=>cr_lf.
            request_body = request_body && '<OrganisationFormattedName2>' && <entity>-OrganisationFormattedName2 && '</OrganisationFormattedName2>' && cl_abap_char_utilities=>cr_lf.
            request_body = request_body && '<OrganisationFormattedName3>' && <entity>-OrganisationFormattedName3 && '</OrganisationFormattedName3>' && cl_abap_char_utilities=>cr_lf.
            request_body = request_body && '<OrganisationFormattedName4>' && <entity>-OrganisationFormattedName4 && '</OrganisationFormattedName4>' && cl_abap_char_utilities=>cr_lf.
            request_body = request_body && '<StreetName>' && <entity>-StreetName && '</StreetName>' && cl_abap_char_utilities=>cr_lf.
            request_body = request_body && '<HouseID>' && <entity>-HouseID && '</HouseID>' && cl_abap_char_utilities=>cr_lf.
            request_body = request_body && '<CityName>' && <entity>-CityName && '</CityName>' && cl_abap_char_utilities=>cr_lf.
            request_body = request_body && '<CountryCode>' && <entity>-CountryCode && '</CountryCode>' && cl_abap_char_utilities=>cr_lf.
            request_body = request_body && '<TaxJurisdictionCode>' && <entity>-TaxJurisdictionCode && '</TaxJurisdictionCode>' && cl_abap_char_utilities=>cr_lf.
            request_body = request_body && '<StreetPostalCode>' && <entity>-StreetPostalCode && '</StreetPostalCode>' && cl_abap_char_utilities=>cr_lf.
            request_body = request_body && '<Instructions>' && <entity>-Instructions && '</Instructions>' && cl_abap_char_utilities=>cr_lf.
            LOOP AT lt_available INTO DATA(ls_available).
                DATA(availableID) = |{ ls_available-AvailableID ALPHA = OUT }|.
                DATA(outboundDelivery) = |{ ls_available-OutboundDelivery ALPHA = IN }|.
                SELECT SINGLE UnloadingPointName FROM zc_available_003 WHERE ( AvailableUUID = @ls_available-availableUUID ) INTO @DATA(unloadingPointName).
                request_body = request_body && '<OutboundDelivery>' && cl_abap_char_utilities=>cr_lf.
                request_body = request_body && '<ItemID>' && availableID && '</ItemID>' && cl_abap_char_utilities=>cr_lf.
                request_body = request_body && '<ID>' && outboundDelivery && '</ID>' && cl_abap_char_utilities=>cr_lf.
                request_body = request_body && '<NumberOfPackages>' && unloadingPointName && '</NumberOfPackages>' && cl_abap_char_utilities=>cr_lf.
                request_body = request_body && '</OutboundDelivery>' && cl_abap_char_utilities=>cr_lf.
            ENDLOOP.
            request_body = request_body && '</ShipmentBinding>' && cl_abap_char_utilities=>cr_lf.

*           Do Free Style HTTP Request
            TRY.

                DATA i_url         TYPE string VALUE 'https://felina-hu-scpi-test-eyjk96r2.it-cpi018-rt.cfapps.eu10-003.hana.ondemand.com/http/FiegeShipmentBindingRequest'.
                DATA i_username    TYPE string VALUE 'sb-1e950f89-c676-4acd-b0dc-24e58f8aab45!b143168|it-rt-felina-hu-scpi-test-eyjk96r2!b117912'.
                DATA i_password    TYPE string VALUE 'cc744b1f-5237-4a7e-ab44-858fdd00fb73$3wcTQpYfe1kbmjltnA8zSDb5ogj0TpaYon4WHM-TwfE='.

                DATA(http_destination) = cl_http_destination_provider=>create_by_url(
                    i_url = i_url
                ).

                DATA(lo_http_client) = cl_web_http_client_manager=>create_by_http_destination(
                    i_destination = http_destination
                ).

                lo_http_client->get_http_request( )->set_authorization_basic(
                    i_username = i_username
                    i_password = i_password
                ).

                lo_http_client->get_http_request( )->set_text(
                    i_text = request_body " 'Hello, CPI!'
                ).

                DATA(lo_http_response) = lo_http_client->execute(
                    i_method   = if_web_http_client=>get
*                    i_timeout  = 0
                ).

                DATA(response_body) = lo_http_response->get_text( ).
                DATA(status)        = lo_http_response->get_status( ).
                DATA(header_fields) = lo_http_response->get_header_fields( ).
                DATA(header_status) = lo_http_response->get_header_field( '~status_code' ).

*                out->write( cl_abap_char_utilities=>cr_lf && status-code && cl_abap_char_utilities=>cr_lf ).
*                out->write( cl_abap_char_utilities=>cr_lf && response_body && cl_abap_char_utilities=>cr_lf ).

                IF ( status-code = 200 ).
                    APPEND VALUE #( %key = <entity>-%key %msg = new_message_with_text( severity = if_abap_behv_message=>severity-success text = 'Successfully Sent.'  ) ) TO reported-shipment.
                ELSE.
                    DATA(code) = CONV string( status-code ).
                    CONCATENATE 'Error Status Code =' code '.' INTO DATA(text) SEPARATED BY space.
                    APPEND VALUE #( %key = <entity>-%key %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error text = text  ) ) TO reported-shipment.
                    RETURN.
                ENDIF.

            CATCH /iwbep/cx_cp_remote INTO DATA(lx_remote).
              " Handle remote Exception
*              RAISE SHORTDUMP lx_remote.
                APPEND VALUE #( %key = <entity>-%key %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error text = 'Remote Error.' ) ) TO reported-shipment.
                RETURN.

            CATCH /iwbep/cx_gateway INTO DATA(lx_gateway).
              " Handle Exception
*              RAISE SHORTDUMP lx_gateway.
                APPEND VALUE #( %key = <entity>-%key %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error text = 'Gateway Error.' ) ) TO reported-shipment.
                RETURN.

            CATCH cx_web_http_client_error INTO DATA(lx_web_http_client_error).
              " Handle Exception
*              RAISE SHORTDUMP lx_web_http_client_error.
                APPEND VALUE #( %key = <entity>-%key %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error text = 'Web HTTP Client Error.' ) ) TO reported-shipment.
                RETURN.

            CATCH cx_http_dest_provider_error INTO DATA(lx_http_dest_provider_error).
                "handle exception
*              RAISE SHORTDUMP lx_http_dest_provider_error.
                APPEND VALUE #( %key = <entity>-%key %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error text = 'HTTP Dest Provider Error.' ) ) TO reported-shipment.
                RETURN.

            ENDTRY.

*           SELECT OutboundDelivery FROM I_OutboundDeliveryTP WHERE ( SoldToParty = @sold_to_party ) INTO TABLE @DATA(lt_outbound_delivery).

            MODIFY ENTITIES OF zi_shipment_003 IN LOCAL MODE
                ENTITY Shipment
                UPDATE FIELDS ( Released )
                WITH VALUE #( (
                    %tky        = <entity>-%tky
                    Released    = abap_true
                ) )
                FAILED DATA(failed2)
                MAPPED DATA(mapped2)
                REPORTED DATA(reported2).

        ENDIF.

        IF ( <entity>-%is_draft = '01' ). " Draft

*           Short format message
            APPEND VALUE #( %key = <entity>-%key %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error text = 'Data not saved.' ) ) TO reported-shipment.
            RETURN.

**            "MESSAGE" is not allowed in the current ABAP language version.
*            MESSAGE e001(Z_SHIPMENT_003) WITH 'Test1' <entity>-ShipmentID '' ''.

**           Long format message
*            DATA(severity)  = if_abap_behv_message=>severity-error.
*            DATA msgid TYPE sy-msgid VALUE 'Z_SHIPMENT_003'.
*            DATA msgno TYPE sy-msgno VALUE '001'.
*            DATA msgv1 TYPE sy-msgv1 VALUE ''.
*            DATA msgv2 TYPE sy-msgv2 VALUE ''.
*            DATA msgv3 TYPE sy-msgv3 VALUE ''.
*            DATA msgv4 TYPE sy-msgv4 VALUE ''.
*            msgv1 = 'Shipment'.
*            msgv2 = |{ <entity>-ShipmentID ALPHA = OUT }|.
*            msgv3 = '- Data not saved.'.
*            APPEND VALUE #( %key = <entity>-%key %msg = new_message( severity = severity id = msgid number = msgno v1 = msgv1 v2 = msgv2 v3 = msgv3 v4 = msgv4 ) ) TO reported-shipment.

        ENDIF.

    ENDLOOP.

  ENDMETHOD. " release

  METHOD create_invoice. " on Create Invoice

*   Outbound (PDF)
    DATA it_outbound_create TYPE TABLE FOR CREATE zi_shipment_003\_Outbound.

    " Read transfered instances
    READ ENTITIES OF zi_shipment_003 IN LOCAL MODE
        ENTITY Shipment
        ALL FIELDS
        WITH CORRESPONDING #( keys )
        RESULT DATA(entities).

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).

        IF ( <entity>-%is_draft = '00' ). " Saved
        ENDIF.
        IF ( <entity>-%is_draft = '01' ). " Draft
        ENDIF.

    ENDLOOP.

  ENDMETHOD. " create_invoice

  METHOD create_tkz_list. " on Create TKZ List

*   Outbound (PDF)
    DATA it_outbound_create TYPE TABLE FOR CREATE zi_shipment_003\_Outbound.

    " Read transfered instances
    READ ENTITIES OF zi_shipment_003 IN LOCAL MODE
        ENTITY Shipment
        ALL FIELDS
        WITH CORRESPONDING #( keys )
        RESULT DATA(entities).

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).

        IF ( <entity>-%is_draft = '00' ). " Saved
        ENDIF.
        IF ( <entity>-%is_draft = '01' ). " Draft
        ENDIF.

    ENDLOOP.

  ENDMETHOD. " create_tkz_list

  METHOD create_tariff_document. " on Create Tariff Document

*   Header
    DATA BEGIN OF header.
        DATA ID                     TYPE string.
        DATA ShipmentID             TYPE string.
        DATA Name                   TYPE string.
        DATA StreetName             TYPE string.
        DATA HouseID                TYPE string.
        DATA CityName               TYPE string.
        DATA CountryCode            TYPE string.
        DATA StreetPostalCode       TYPE string.
        DATA DateOfIssue            TYPE string.
        DATA CurrencyCode           TYPE string.
    DATA END OF header.

*   Item
    DATA BEGIN OF item.
        DATA CustomsTariffNumber    TYPE string. " '62121090'.
        DATA Items                  TYPE string. " 'Brassel for ladies'.
        DATA CountryOfOrigin        TYPE string. " 'MA'.
        DATA NetWeight              TYPE string. " '4.005'.
        DATA unitCode1              TYPE string. " 'KG'.
        DATA MaterialQuantity       TYPE string. " '52.0'.
        DATA unitCode2              TYPE string. " 'EA'.
        DATA NetValue               TYPE string. " '1849.18'.
        DATA currencyCode           TYPE string. " 'EUR'.
    DATA END OF item.
    DATA it_item LIKE TABLE OF item.

*   Invoice
    DATA BEGIN OF invoice.
        DATA DateOfInvoice          TYPE string. " '2022-07-18'.
        DATA CustomerInvoiceID      TYPE string. " '100-10018566'.
        DATA ClientNumber           TYPE string. " '2124100'.
        DATA ClientName             TYPE string.
        DATA Quantity               TYPE string. " '7.0'.
        DATA unitCode               TYPE string. " ''.
    DATA END OF invoice.
    DATA it_invoice LIKE TABLE OF invoice.

*   Outbound (PDF)
    DATA it_outbound_create TYPE TABLE FOR CREATE zi_shipment_003\_Outbound.

    " Read transfered instances
    READ ENTITIES OF zi_shipment_003 IN LOCAL MODE
        ENTITY Shipment
        ALL FIELDS
        WITH CORRESPONDING #( keys )
        RESULT DATA(entities).

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).

        IF ( <entity>-%is_draft = '00' ). " Saved
        ENDIF.
        IF ( <entity>-%is_draft = '01' ). " Draft
        ENDIF.

        TRY.
            " Retrive XDP template from our Web Repository
            SELECT SINGLE * FROM zi_repository_003 WHERE ( RepositoryID = 'TARIFF_DOCUMENT' ) INTO @DATA(repository).
            IF (  sy-subrc = 0 ).

*               Currency Code (default for the Shipment Group)
                DATA(partyID) = |{ <entity>-PartyID ALPHA = IN }|.
                SELECT SINGLE
                        *
                    FROM
                        I_CustomerSalesArea
                    WHERE
                        ( Customer              = @partyID )  AND
                        ( SalesOrganization     = '1000' ) AND
                        ( DistributionChannel   = '10' ) AND
                        ( Division              = '00' )
                    INTO
                        @DATA(customersalesarea).

                DATA formatted_date TYPE string.
                cl_abap_datfm=>conv_date_int_to_ext(
                  EXPORTING
                    im_datint    = cl_abap_context_info=>get_system_date( )
*                    im_datfmdes  =
                  IMPORTING
                    ex_datext    = formatted_date " 04.01.2024
*                    ex_datfmused =
                ).

*               Header
                header-ID                = <entity>-ShipmentID.                                     " '1000000059'.
                header-ShipmentID        = <entity>-ShipmentID.                                     " 'ShipmentID'.
                header-Name              = <entity>-OrganisationFormattedName1.                     " 'DPD Schweiz AG'.
                header-StreetName        = <entity>-StreetName.                                     " 'Rinaustr.'.
                header-HouseID           = <entity>-HouseID.                                        " '143'.
                header-CityName          = <entity>-CityName.                                       " 'Kaiseraugst'.
                header-CountryCode       = <entity>-CountryCode.                                    " 'CH'.
                header-StreetPostalCode  = <entity>-StreetPostalCode.                               " '4303'.
                header-DateOfIssue       = formatted_date.                                             " '2022-07-18'.
                header-CurrencyCode      = customersalesarea-Currency.                              " 'EUR'.

*               Item and Invoice sections:
                READ ENTITIES OF zi_shipment_003 IN LOCAL MODE
                    ENTITY Shipment BY \_Available
                    ALL FIELDS WITH VALUE #( (
                        %tky = <entity>-%tky
                    ) )
                    RESULT DATA(it_available)
                    FAILED DATA(failed1)
                    REPORTED DATA(reported1).

                LOOP AT it_available INTO DATA(available).

                    available-OutboundDelivery = |{ available-OutboundDelivery ALPHA = IN }|.

                    SELECT SINGLE   * FROM I_OutboundDelivery       WHERE ( OutboundDelivery = @available-OutboundDelivery ) INTO        @DATA(outbounddelivery).
                    SELECT          * FROM I_OutboundDeliveryItem   WHERE ( OutboundDelivery = @available-OutboundDelivery ) INTO TABLE  @DATA(it_outbounddeliveryitem).

                    LOOP AT it_outbounddeliveryitem INTO DATA(outbounddeliveryitem).

                        SELECT SINGLE * FROM I_BillingDocumentItem  WHERE ( ReferenceSDDocument  = @outbounddeliveryitem-OutboundDelivery ) AND ( ReferenceSDDocumentItem = @outbounddeliveryitem-OutboundDeliveryItem ) INTO @DATA(billingdocumentitem).
                        SELECT SINGLE * FROM I_BillingDocument      WHERE ( BillingDocument      = @billingdocumentitem-BillingDocument ) INTO @DATA(billingdocument).

                        IF ( billingdocumentitem IS INITIAL ).
*                           Short format message
*                           CONCATENATE 'Missing Invoice for Outbound Delivery' outbounddeliveryitem-OutboundDelivery '/' outbounddeliveryitem-OutboundDeliveryItem INTO DATA(text) SEPARATED BY space.
*                           APPEND VALUE #( %key = <entity>-%key %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error text = text ) ) TO reported-shipment.
*                           Long format message
                            DATA(severity)  = if_abap_behv_message=>severity-error.
                            DATA msgno TYPE sy-msgno VALUE '001'.
                            DATA msgid TYPE sy-msgid VALUE 'Z_SHIPMENT_003'.
                            DATA(msgty)     = 'E'.
                            DATA(msgv1)     = 'Missing Invoice for Outbound Delivery'.
                            DATA(msgv2)     = outbounddeliveryitem-OutboundDelivery.
                            DATA(msgv3)     = '/'.
                            DATA(msgv4)     = outbounddeliveryitem-OutboundDeliveryItem.
                            APPEND VALUE #( %key = <entity>-%key %msg = new_message( severity = severity id = msgid number = msgno v1 = msgv1 v2 = msgv2 v3 = msgv3 v4 = msgv4 ) ) TO reported-shipment.
                            RETURN.
                        ENDIF.

*                       Commodity Code
                        SELECT SINGLE
                                *
                            FROM
                                c_prodcommoditycodeforkeydate( p_keydate = @billingdocument-billingdocumentdate )
                            WHERE
                                ( product = @billingdocumentitem-Product ) AND
                                ( country = @billingdocumentitem-DepartureCountry )
                            INTO
                                @DATA(prodcommoditycodeforkeydate).

*                       Customer
                        SELECT SINGLE
                                *
                            FROM
                                I_Customer
                            WHERE
                                ( Customer = @billingdocument-SoldToParty )
                            INTO
                                @DATA(customer).

*                       Product
                        SELECT SINGLE
                                *
                            FROM
                                I_Product
                            WHERE
                                ( Product = @billingdocumentitem-Product )
                            INTO
                                @DATA(product).

*                       Date Of Invoice
                        DATA dateOfInvoice TYPE string.
                        cl_abap_datfm=>conv_date_int_to_ext(
                          EXPORTING
                            im_datint    = billingdocument-billingdocumentdate
*                            im_datfmdes  =
                          IMPORTING
                            ex_datext    = dateOfInvoice " 04.01.2024
*                            ex_datfmused =
                        ).

*                       Net Weight
                        DATA netWeight TYPE string.
                        netWeight           = |{ outbounddeliveryitem-ItemNetWeight     DECIMALS = 3 }|.

*                       Material Quantity
                        DATA materialQuantity TYPE string.
                        materialQuantity    = |{ billingdocumentitem-BillingQuantity    DECIMALS = 1 }|.

*                       Net Amount
                        DATA netAmount TYPE string.
                        netAmount           = |{ billingdocumentitem-NetAmount          DECIMALS = 2 }|.

*                       Quantity
                        DATA quantity TYPE string.
                        quantity            = |{ billingdocumentitem-BillingQuantity    DECIMALS = 1 }|.

*                       Item:
                        CLEAR item.
                        item-CustomsTariffNumber   = prodcommoditycodeforkeydate-CommodityCode.     " '62121090'.
                        item-Items                 = billingdocumentitem-BillingDocumentItemText.   " 'Brassel for ladies'.
                        item-CountryOfOrigin       = product-CountryOfOrigin.                       " 'MA'.
                        item-NetWeight             = netWeight.                                     " '4.005'.
                        item-unitCode1             = outbounddeliveryitem-ItemWeightUnit.           " 'KG'.
                        item-MaterialQuantity      = materialQuantity.                              " '52.0'.
                        item-unitCode2             = billingdocumentitem-BillingQuantityUnit.       " 'EA'.
                        item-NetValue              = netAmount.                                     " '1849.18'.
                        item-currencyCode          = billingdocumentitem-TransactionCurrency.       " 'EUR'.
                        APPEND item TO it_item.

*                       Invoice:
                        CLEAR invoice.
                        invoice-DateOfInvoice      = dateOfInvoice.                                 " '18.07.2022'.
                        invoice-CustomerInvoiceID  = billingdocument-BillingDocument.               " '100-10018566'.
                        invoice-ClientNumber       = billingdocument-SoldToParty.                   " '2124100'.
                        invoice-ClientName         = customer-BPCustomerName.                       " 'Wullehus - Mode AG'.
                        invoice-Quantity           = quantity.                                      " '7.0'.
                        invoice-unitCode           = billingdocumentitem-BillingQuantityUnit.       " 'EA'.
                        APPEND invoice TO it_invoice.

                    ENDLOOP.
                ENDLOOP.

*               Group it_item By CustomsTariffNumber (Commodity Code)
                SORT it_item STABLE BY CustomsTariffNumber.
                DATA it_item2 LIKE it_item.
                DATA item2 LIKE item.
                CLEAR item2.
                LOOP AT it_item INTO item.
                    IF ( item-CustomsTariffNumber = item2-CustomsTariffNumber ) AND
                       ( sy-tabix <> 1 ).
                        item2-NetWeight         = |{ 0 + item2-NetWeight           + item-NetWeight         DECIMALS = 3 }|.
                        item2-MaterialQuantity  = |{ 0 + item2-MaterialQuantity    + item-MaterialQuantity  DECIMALS = 1 }|.
                        item2-NetValue          = |{ 0 + item2-NetValue            + item-NetValue          DECIMALS = 2 }|.
                    ELSE.
                        IF ( sy-tabix <> 1 ).
                            APPEND item2 TO it_item2.
                        ENDIF.
                        MOVE-CORRESPONDING item to item2.
                    ENDIF.
                ENDLOOP.
                IF ( item2 IS NOT INITIAL ).
                    APPEND item2 TO it_item2.
                ENDIF.

*               Group it_invoice By CustomerInvoiceID
                SORT it_invoice STABLE BY CustomerInvoiceID.
                DATA it_invoice2 LIKE it_invoice.
                DATA invoice2 LIKE invoice.
                CLEAR invoice2.
                LOOP AT it_invoice INTO invoice.
                    IF ( invoice-CustomerInvoiceID = invoice2-CustomerInvoiceID ) AND
                       ( sy-tabix <> 1 ).
                        invoice2-Quantity  = |{ 0 + invoice2-Quantity  + invoice-Quantity DECIMALS = 1 }|.
                    ELSE.
                        IF ( sy-tabix <> 1 ).
                            APPEND invoice2 TO it_invoice2.
                        ENDIF.
                        MOVE-CORRESPONDING invoice to invoice2.
                    ENDIF.
                ENDLOOP.
                IF ( invoice2 IS NOT INITIAL ).
                    APPEND invoice2 TO it_invoice2.
                ENDIF.

*               Generate XML
                DATA xml_data TYPE string VALUE ''.

                xml_data = xml_data &&
                    '<?xml version="1.0" encoding="UTF-8"?>' && cl_abap_char_utilities=>cr_lf &&
                    '<TariffDocumentForm>' && cl_abap_char_utilities=>cr_lf &&
                    '<TariffDocument>' && cl_abap_char_utilities=>cr_lf.

*               Header Section
                xml_data = xml_data &&
                    '<ID>' && header-ID && '</ID>' && cl_abap_char_utilities=>cr_lf &&
                    '<ShipmentID>' && header-ShipmentID && '</ShipmentID>' && cl_abap_char_utilities=>cr_lf &&
                    '<Name>' && header-Name && '</Name>' && cl_abap_char_utilities=>cr_lf &&
                    '<StreetName>' && header-StreetName && '</StreetName>' && cl_abap_char_utilities=>cr_lf &&
                    '<HouseID>' && header-HouseID && '</HouseID>' && cl_abap_char_utilities=>cr_lf &&
                    '<CityName>' && header-CityName && '</CityName>' && cl_abap_char_utilities=>cr_lf &&
                    '<CountryCode>' && header-CountryCode && '</CountryCode>' && cl_abap_char_utilities=>cr_lf &&
                    '<StreetPostalCode>' && header-StreetPostalCode && '</StreetPostalCode>' && cl_abap_char_utilities=>cr_lf &&
                    '<DateOfIssue>' && header-DateOfIssue && '</DateOfIssue>' && cl_abap_char_utilities=>cr_lf &&
                    '<CurrencyCode>' && header-CurrencyCode && '</CurrencyCode>' && cl_abap_char_utilities=>cr_lf.

*               Item Section
                LOOP AT it_item2 INTO item2.
                    xml_data = xml_data &&
                        '<Items>' &&
                        '<CustomsTariffNumber>' && item2-CustomsTariffNumber && '</CustomsTariffNumber>' && cl_abap_char_utilities=>cr_lf &&
                        '<Items>' && item2-Items && '</Items>' && cl_abap_char_utilities=>cr_lf &&
                        '<CountryOfOrigin>' && item2-CountryOfOrigin && '</CountryOfOrigin>' && cl_abap_char_utilities=>cr_lf &&
                        '<NetWeight unitCode="' && item2-unitCode1 && '">' && item2-NetWeight && '</NetWeight>' && cl_abap_char_utilities=>cr_lf &&
                        '<MaterialQuantity unitCode="' && item2-unitCode2 && '">' && item2-MaterialQuantity && '</MaterialQuantity>' && cl_abap_char_utilities=>cr_lf &&
                        '<NetValue currencyCode="' && item2-currencyCode && '">' && item2-NetValue && '</NetValue>' && cl_abap_char_utilities=>cr_lf &&
                        '</Items>' && cl_abap_char_utilities=>cr_lf.
                ENDLOOP.

*               Invoice Section
                LOOP AT it_invoice2 INTO invoice2.
                    xml_data = xml_data &&
                        '<Invoice>' && cl_abap_char_utilities=>cr_lf &&
                        '<DateOfInvoice>' && invoice2-DateOfInvoice && '</DateOfInvoice>' && cl_abap_char_utilities=>cr_lf &&
                        '<CustomerInvoiceID schemeAgencyID="" schemeAgencySchemeAgencyID="" schemeID="">' && invoice2-CustomerInvoiceID && '</CustomerInvoiceID>' && cl_abap_char_utilities=>cr_lf &&
                        '<ClientNumber>' && invoice2-ClientNumber && '</ClientNumber>' && cl_abap_char_utilities=>cr_lf &&
                        '<ClientName>' && invoice2-ClientName && '</ClientName>' && cl_abap_char_utilities=>cr_lf &&
                        '<Quantity unitCode="' && invoice2-unitCode && '">' && invoice2-Quantity && '</Quantity>' && cl_abap_char_utilities=>cr_lf &&
                        '</Invoice>' && cl_abap_char_utilities=>cr_lf.
                ENDLOOP.

                xml_data = xml_data &&
                    '</TariffDocument>' && cl_abap_char_utilities=>cr_lf &&
                    '</TariffDocumentForm>' && cl_abap_char_utilities=>cr_lf.

*               Remove some 'harmful' characters
                REPLACE ALL OCCURRENCES OF '&' IN xml_data WITH '&amp;'.

                DATA lv_xml_data        TYPE xstring.
                DATA lv_xdp             TYPE xstring.
                DATA ls_options         TYPE cl_fp_ads_util=>ty_gs_options_pdf.
                DATA ev_pdf             TYPE xstring.
                DATA ev_pages           TYPE int4.
                DATA ev_trace_string    TYPE string.

                lv_xml_data = cl_abap_message_digest=>string_to_xstring( xml_data ).

*               XDP - Xstring (binary) format
                lv_xdp = repository-xdp. " cl_abap_message_digest=>string_to_xstring( text ). "

*               Render PDF
                cl_fp_ads_util=>render_pdf(
                    EXPORTING iv_xml_data      = lv_xml_data
                              iv_xdp_layout    = lv_xdp
                              iv_locale        = 'en_EN'
                              is_options       = ls_options
                    IMPORTING ev_pdf           = ev_pdf
                              ev_pages         = ev_pages
                              ev_trace_string  = ev_trace_string
                ).

                IF ( sy-subrc = 0 ).

*                   Convert Xstring (binary) into Base64 (string) (for testing)
                    DATA(base64_pdf) = cl_web_http_utility=>encode_x_base64( ev_pdf ).

                    DATA(filename) = repository-RepositoryID && '_' && <entity>-ShipmentID.
                    DATA(mimetype) = 'application/pdf'.

*                   Add a New Outbound
                    APPEND VALUE #(
                        %is_draft   = <entity>-%is_draft
                        ShipmentUUID = <entity>-ShipmentUUID
                        %target = VALUE #( (
                            %is_draft       = <entity>-%is_draft
                            %cid            = '1'
                            ShipmentUUID    = <entity>-ShipmentUUID
                            Attachment      = ev_pdf
                            FileName        = filename
                            MimeType        = mimetype
                        ) )
                    ) TO it_outbound_create.

                    " Create New Items
                    MODIFY ENTITIES OF zi_shipment_003 IN LOCAL MODE
                        ENTITY Shipment
                        CREATE BY \_Outbound
                        FIELDS ( ShipmentUUID Attachment FileName MimeType )
                        WITH it_outbound_create
                        FAILED DATA(failed2)
                        MAPPED DATA(mapped2)
                        REPORTED DATA(reported2).

                ENDIF.


            ENDIF.

        CATCH cx_abap_datfm_format_unknown.
        CATCH cx_fp_ads_util.
        CATCH cx_abap_message_digest.

        ENDTRY.

    ENDLOOP.

  ENDMETHOD. " create_tariff_document

  METHOD create_eci. " csv

*   Outbound (CSV)
    DATA it_outbound_create TYPE TABLE FOR CREATE zi_shipment_003\_Outbound.

    " Read transfered instances
    READ ENTITIES OF zi_shipment_003 IN LOCAL MODE
        ENTITY Shipment
        ALL FIELDS
        WITH CORRESPONDING #( keys )
        RESULT DATA(entities).

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).

        IF ( <entity>-%is_draft = '00' ). " Saved
        ENDIF.
        IF ( <entity>-%is_draft = '01' ). " Draft
        ENDIF.

    ENDLOOP.

  ENDMETHOD. " create_eci

  METHOD on_create. " on initial create

*     " Read transfered instances
*    READ ENTITIES OF zi_shipment_003 IN LOCAL MODE
*        ENTITY Shipment
*        ALL FIELDS
*        WITH CORRESPONDING #( keys )
*        RESULT DATA(entities).
*
*    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).
*
*        IF ( <entity>-%is_draft = '00' ). " Saved
*        ENDIF.
*        IF ( <entity>-%is_draft = '01' ). " Draft
*        ENDIF.
*
**       Generate New Matrix ID (moved to Activate (Save) )
*        DATA shipmentid TYPE zi_shipment_003-ShipmentID VALUE '0000000000'.
*        SELECT MAX( shipmentid ) FROM zi_shipment_003 INTO (@shipmentid).
*        shipmentid  = ( shipmentid + 1 ).
*
*        MODIFY ENTITIES OF zi_shipment_003 IN LOCAL MODE
*            ENTITY Shipment
*            UPDATE FIELDS ( ShipmentID )
*            WITH VALUE #( (
*                %tky        = <entity>-%tky
**                ShipmentID  = shipmentid
*            ) )
*            FAILED DATA(ls_failed1)
*            MAPPED DATA(ls_mapped1)
*            REPORTED DATA(ls_reported1).
*
*    ENDLOOP.

  ENDMETHOD. " on_create

  METHOD on_save_customer.
  ENDMETHOD. " on_save_customer

  METHOD on_modify_customer.

    DATA partyID TYPE zi_shipment_003-PartyID.

     " Read transfered instances
    READ ENTITIES OF zi_shipment_003 IN LOCAL MODE
        ENTITY Shipment
        ALL FIELDS
        WITH CORRESPONDING #( keys )
        RESULT DATA(entities).

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).

        IF ( <entity>-%is_draft = '00' ). " Saved
        ENDIF.
        IF ( <entity>-%is_draft = '01' ). " Draft
        ENDIF.

        partyID = |{ <entity>-PartyID ALPHA = IN }|. " Add leading zeros

        IF ( partyID <> <entity>-PartyID ).

            MODIFY ENTITIES OF zi_shipment_003 IN LOCAL MODE
                ENTITY Shipment
                UPDATE FIELDS (
                    PartyID
                )
                WITH VALUE #( (
                    %tky    = <entity>-%tky
                    PartyID = partyID
                ) )
                MAPPED DATA(mapped1)
                FAILED DATA(failed1)
                REPORTED DATA(reported1).

        ENDIF.

        " Read transfered instances
        SELECT SINGLE * FROM I_Customer WHERE ( Customer = @partyID ) INTO @DATA(ls_customer).

        IF ( sy-subrc = 0 ).

            DATA(tx03) = get_texts_internal(
                EXPORTING
                    i_customer             = CONV string( ls_customer-Customer )
                    i_sales_organization   = '1000'
                    i_distribution_channel = '10'
                    i_division             = '00'
                    i_language             = 'EN'
                    i_long_text_id         = 'TX03'
            ).

            DATA(zfw1) = get_texts_internal(
                EXPORTING
                    i_customer             = CONV string( ls_customer-Customer )
                    i_sales_organization   = '1000'
                    i_distribution_channel = '10'
                    i_division             = '00'
                    i_language             = 'EN'
                    i_long_text_id         = 'ZFW1'
            ).

            DATA(zlvs) = get_texts_internal(
                EXPORTING
                    i_customer             = CONV string( ls_customer-Customer )
                    i_sales_organization   = '1000'
                    i_distribution_channel = '10'
                    i_division             = '00'
                    i_language             = 'EN'
                    i_long_text_id         = 'ZLVS'
            ).

            get_forwarding_rule_internal(
              EXPORTING
                i_forwarding_rule_id           = zfw1
              IMPORTING
                o_transportation_type_shipment = DATA(transportationTypeShipment)
                o_freight_forwarder_client     = DATA(freightForwarderClient)
            ).

            get_address_internal(
              EXPORTING
                i_customer     = CONV string( ls_customer-Customer )
              IMPORTING
                o_street_name  = DATA(streetName)
                o_house_number = DATA(houseNumber)
            ).

        ENDIF.

        MODIFY ENTITIES OF zi_shipment_003 IN LOCAL MODE
            ENTITY Shipment
            UPDATE FIELDS (
                CityName
                CountryCode
                HouseID
                OrganisationFormattedName1
                OrganisationFormattedName2
                OrganisationFormattedName3
                OrganisationFormattedName4
                StreetName
                StreetPostalCode
                TaxJurisdictionCode
                Tour
                TransportationType
                FreightForwarderClient
                Instructions
            )
            WITH VALUE #( (
                %is_draft                   = <entity>-%is_draft
                %key                        = <entity>-%key
                CityName                    = ls_customer-CityName
                CountryCode                 = ls_customer-Country
                HouseID                     = houseNumber
                OrganisationFormattedName1  = ls_customer-BusinessPartnerName1
                OrganisationFormattedName2  = ls_customer-BusinessPartnerName2
                OrganisationFormattedName3  = ls_customer-BusinessPartnerName3
                OrganisationFormattedName4  = ls_customer-BusinessPartnerName4
                StreetName                  = streetName
                StreetPostalCode            = ls_customer-PostalCode
                TaxJurisdictionCode         = ls_customer-TaxJurisdiction
                Tour                        = zlvs
                TransportationType          = transportationTypeShipment
                FreightForwarderClient      = freightForwarderClient
                Instructions                = tx03
            ) )
            MAPPED DATA(mapped2)
            FAILED DATA(failed2)
            REPORTED DATA(reported2).


    ENDLOOP.

  ENDMETHOD. " on_modify_customer

  METHOD get_texts_internal.

* https://my404907.s4hana.cloud.sap/sap/opu/odata/sap/API_BUSINESS_PARTNER/A_CustomerSalesAreaText(Customer='GKK',SalesOrganization='1000',DistributionChannel='10',Division='00',Language='EN',LongTextID='ZFW1')

    TRY.

*  DATA(i_url) = 'https://my404898-api.s4hana.cloud.sap/sap/opu/odata/sap/API_BUSINESS_PARTNER/A_CustomerSalesAreaText(Customer=''10001722'',SalesOrganization=''1000'',DistributionChannel=''10'',Division=''00'',Language=''EN'',LongTextID=''ZLVS'')'.
        DATA(system_url)    = cl_abap_context_info=>get_system_url( ).
        DATA(customer)      = '''' && i_customer && ''','.
        DATA(long_text_id)  = '''' && i_long_text_id && ''')'.
        CONCATENATE
                'https://'
                system_url(8) " my404898
                '-api.s4hana.cloud.sap/sap/opu/odata/sap/API_BUSINESS_PARTNER/A_CustomerSalesAreaText('
                'Customer='
                customer " '''10001722'','
                'SalesOrganization='
                '''1000'','
                'DistributionChannel='
                '''10'','
                'Division='
                '''00'','
                'Language='
                '''EN'','
                'LongTextID='
                long_text_id " '''ZLVS'')'
            INTO DATA(i_url).

        DATA i_username TYPE string VALUE 'INBOUND_USER'.
        DATA i_password TYPE string VALUE 'rtrVDDgelabtTjUiybRX}tVD3JksqqfvPpBdJRaL'.
*        IF ( system_url(8) = 'my404907' ). " test
*            i_username = 'INBOUND_FIEGE_USER'.
*            i_password = 'JpLftkzhkoktLzvvoxD6oWeXsM#ZXccgfsBBzRpg'.
*        ENDIF.

        DATA(http_destination) = cl_http_destination_provider=>create_by_url( i_url = i_url ).

        DATA(lo_http_client) = cl_web_http_client_manager=>create_by_http_destination( http_destination ).

        lo_http_client->get_http_request( )->set_authorization_basic(
            i_username = i_username
            i_password = i_password
        ).

        DATA(lo_http_response) = lo_http_client->execute(
            i_method   = if_web_http_client=>get
        ).

        DATA(text) = lo_http_response->get_text( ).

        DATA(status) = lo_http_response->get_status( ).

        REPLACE '<d:LongText>'  WITH '******' INTO text.
        REPLACE '</d:LongText>' WITH '******' INTO text.
        SPLIT text AT '******' INTO DATA(s1) DATA(s2) DATA(s3).

        o_text = s2.

    CATCH cx_abap_context_info_error INTO DATA(lx_abap_context_info_error).
      " Handle remote Exception
*      RAISE SHORTDUMP lx_abap_context_info_error.

    CATCH /iwbep/cx_cp_remote INTO DATA(lx_remote).
      " Handle remote Exception
*      RAISE SHORTDUMP lx_remote.

    CATCH /iwbep/cx_gateway INTO DATA(lx_gateway).
      " Handle Exception
*      RAISE SHORTDUMP lx_gateway.

    CATCH cx_web_http_client_error INTO DATA(lx_web_http_client_error).
      " Handle Exception
*      RAISE SHORTDUMP lx_web_http_client_error.

    CATCH cx_http_dest_provider_error INTO DATA(lx_http_dest_provider_error).
        "handle exception
*      RAISE SHORTDUMP lx_http_dest_provider_error.

    ENDTRY.

  ENDMETHOD. " get_texts_internal

  METHOD get_address_internal.

    TRY.

*  DATA(i_url) = 'https://my404898-api.s4hana.cloud.sap/sap/opu/odata/sap/API_BUSINESS_PARTNER/A_BusinessPartnerAddress(BusinessPartner='10001722',AddressID='7927')'.
*  DATA(i_url) = 'https://my404898-api.s4hana.cloud.sap/sap/opu/odata/sap/API_BUSINESS_PARTNER/A_BusinessPartner(BusinessPartner='10001722')/to_BusinessPartnerAddress'.
        DATA(system_url)    = cl_abap_context_info=>get_system_url( ).
        DATA(customer)      = '''' && i_customer && ''')'.
        CONCATENATE
                'https://'
                system_url(8) " my404898
                '-api.s4hana.cloud.sap/sap/opu/odata/sap/API_BUSINESS_PARTNER/A_BusinessPartner('
                'BusinessPartner='
                customer " '''10001722'','
                '/to_BusinessPartnerAddress'
            INTO DATA(i_url).

        DATA i_username TYPE string VALUE 'INBOUND_USER'.
        DATA i_password TYPE string VALUE 'rtrVDDgelabtTjUiybRX}tVD3JksqqfvPpBdJRaL'.
*        IF ( system_url(8) = 'my404907' ). " test
*            i_username = 'INBOUND_FIEGE_USER'.
*            i_password = 'JpLftkzhkoktLzvvoxD6oWeXsM#ZXccgfsBBzRpg'.
*        ENDIF.

        DATA(http_destination) = cl_http_destination_provider=>create_by_url( i_url = i_url ).

        DATA(lo_http_client) = cl_web_http_client_manager=>create_by_http_destination( http_destination ).

        lo_http_client->get_http_request( )->set_authorization_basic(
            i_username = i_username
            i_password = i_password
        ).

        DATA(lo_http_response) = lo_http_client->execute(
            i_method   = if_web_http_client=>get
        ).

        DATA(text) = lo_http_response->get_text( ).

        DATA(status) = lo_http_response->get_status( ).

        REPLACE '<d:StreetName>'        IN text WITH '******'.
        REPLACE '</d:StreetName>'       IN text WITH '******'.
        REPLACE '<d:HouseNumber>'       IN text WITH '******'.
        REPLACE '</d:HouseNumber>'      IN text WITH '******'.
        SPLIT text AT '******' INTO DATA(s1) DATA(s2) DATA(s3) DATA(s4) DATA(s5).

        o_house_number  = s2.
        o_street_name   = s4.

    CATCH cx_abap_context_info_error INTO DATA(lx_abap_context_info_error).
      " Handle remote Exception
*      RAISE SHORTDUMP lx_abap_context_info_error.

    CATCH /iwbep/cx_cp_remote INTO DATA(lx_remote).
      " Handle remote Exception
*      RAISE SHORTDUMP lx_remote.

    CATCH /iwbep/cx_gateway INTO DATA(lx_gateway).
      " Handle Exception
*      RAISE SHORTDUMP lx_gateway.

    CATCH cx_web_http_client_error INTO DATA(lx_web_http_client_error).
      " Handle Exception
*      RAISE SHORTDUMP lx_web_http_client_error.

    CATCH cx_http_dest_provider_error INTO DATA(lx_http_dest_provider_error).
        "handle exception
*      RAISE SHORTDUMP lx_http_dest_provider_error.

    ENDTRY.

  ENDMETHOD. " get_address_internal

  METHOD get_forwarding_rule_internal.

    TRY.

*  DATA(i_url) = 'https://my404898.s4hana.cloud.sap/sap/opu/odata/sap/YY1_FORWARDINGRULE_CDS/YY1_FORWARDINGRULE?$filter=ForwardingRuleID eq '262_NEUTRAL KARSTADT'&$select=TransportationTypeShipment,FreightForwarderClient'.
        DATA(system_url)    = cl_abap_context_info=>get_system_url( ).
        DATA(forwarding_rule_id)  = '''' && i_forwarding_rule_id && ''''.
        CONCATENATE
                'https://'
                system_url(8) " my404898
                '-api.s4hana.cloud.sap/sap/opu/odata/sap/YY1_FORWARDINGRULE_CDS/YY1_FORWARDINGRULE'
*                '?$filter=ForwardingRuleID eq'
*                forwarding_rule_id " '''262_NEUTRAL KARSTADT'''
*                '&$select=TransportationTypeShipment,FreightForwarderClient'
            INTO DATA(i_url).

        DATA i_username TYPE string VALUE 'INBOUND_USER'.
        DATA i_password TYPE string VALUE 'rtrVDDgelabtTjUiybRX}tVD3JksqqfvPpBdJRaL'.
        IF ( system_url(8) = 'my404907' ). " test
            i_username = 'INBOUND_FIEGE_USER'.
            i_password = 'JpLftkzhkoktLzvvoxD6oWeXsM#ZXccgfsBBzRpg'.
        ENDIF.

        DATA(http_destination) = cl_http_destination_provider=>create_by_url( i_url = i_url ).

        DATA(lo_http_client) = cl_web_http_client_manager=>create_by_http_destination( http_destination ).

        lo_http_client->get_http_request( )->set_authorization_basic(
            i_username = i_username
            i_password = i_password
        ).

        DATA(lo_http_request) = lo_http_client->get_http_request( ).

        CONCATENATE
                '$filter=ForwardingRuleID eq'
                forwarding_rule_id " '''262_NEUTRAL KARSTADT'''
                '&$select=TransportationTypeShipment,FreightForwarderClient'
            INTO
                DATA(query).
        lo_http_request->set_query( query = query ).

        DATA(lo_http_response) = lo_http_client->execute(
            i_method   = if_web_http_client=>get
        ).

        DATA(text) = lo_http_response->get_text( ).

        DATA(status) = lo_http_response->get_status( ).

        REPLACE '<d:TransportationTypeShipment>'    IN text WITH '******'.
        REPLACE '</d:TransportationTypeShipment>'   IN text WITH '******'.
        REPLACE '<d:FreightForwarderClient>'        IN text WITH '******'.
        REPLACE '</d:FreightForwarderClient>'       IN text WITH '******'.
        SPLIT text AT '******' INTO DATA(s1) DATA(s2) DATA(s3) DATA(s4) DATA(s5).

        o_transportation_type_shipment  = s2.
        o_freight_forwarder_client      = s4.

    CATCH cx_abap_context_info_error INTO DATA(lx_abap_context_info_error).
      " Handle remote Exception
*      RAISE SHORTDUMP lx_abap_context_info_error.

    CATCH /iwbep/cx_cp_remote INTO DATA(lx_remote).
      " Handle remote Exception
*      RAISE SHORTDUMP lx_remote.

    CATCH /iwbep/cx_gateway INTO DATA(lx_gateway).
      " Handle Exception
*      RAISE SHORTDUMP lx_gateway.

    CATCH cx_web_http_client_error INTO DATA(lx_web_http_client_error).
      " Handle Exception
*      RAISE SHORTDUMP lx_web_http_client_error.

    CATCH cx_http_dest_provider_error INTO DATA(lx_http_dest_provider_error).
        "handle exception
*      RAISE SHORTDUMP lx_http_dest_provider_error.

    ENDTRY.

  ENDMETHOD. " get_forwarding_rule_internal

ENDCLASS. " lhc_shipment IMPLEMENTATION


CLASS lsc_zi_shipment_003 DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS. " lsc_zi_shipment_003 DEFINITION

CLASS lsc_zi_shipment_003 IMPLEMENTATION.

  METHOD save_modified.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS. " lsc_zi_shipment_003 IMPLEMENTATION


CLASS lhc_available DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS on_available_create FOR DETERMINE ON MODIFY IMPORTING keys FOR Available~on_available_create.
    METHODS on_outbound_delivery_modify FOR DETERMINE ON MODIFY IMPORTING keys FOR Available~on_outbound_delivery_modify.

ENDCLASS. " lhc_available DEFINITION

CLASS lhc_available IMPLEMENTATION.

  METHOD on_available_create.

     " Read transfered instances
    READ ENTITIES OF zi_shipment_003 IN LOCAL MODE
        ENTITY Available
        ALL FIELDS
        WITH CORRESPONDING #( keys )
        RESULT DATA(entities).

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).

        IF ( <entity>-%is_draft = '00' ). " Saved
        ENDIF.
        IF ( <entity>-%is_draft = '01' ). " Draft
        ENDIF.

*       Read items
        READ ENTITIES OF zi_shipment_003 IN LOCAL MODE
            ENTITY Shipment BY \_Available
            ALL FIELDS WITH VALUE #( (
                %is_draft       = <entity>-%is_draft
                ShipmentUUID    = <entity>-ShipmentUUID
            ) )
            RESULT DATA(lt_available)
            FAILED DATA(failed1)
            REPORTED DATA(reported1).

        SORT lt_available STABLE BY AvailableID DESCENDING.

        DATA newAvailableID TYPE zi_available_003-AvailableID.

        IF ( lt_available[] IS INITIAL ).
            newAvailableID = 10.
        ELSE.
            READ TABLE lt_available INDEX 1 INTO DATA(available).
            newAvailableID = available-AvailableID + 10.
        ENDIF.

        MODIFY ENTITIES OF zi_shipment_003 IN LOCAL MODE
            ENTITY Available
            UPDATE FIELDS (
                AvailableID
            )
            WITH VALUE #( (
                %is_draft       = <entity>-%is_draft
                AvailableUUID   = <entity>-AvailableUUID
                AvailableID     = newAvailableID
            ) )
            MAPPED DATA(mapped2)
            FAILED DATA(failed2)
            REPORTED DATA(reported2).

    ENDLOOP.

  ENDMETHOD. " on_available_create

  METHOD on_outbound_delivery_modify.

    DATA outboundDelivery TYPE zi_available_003-OutboundDelivery.

     " Read transfered instances
    READ ENTITIES OF zi_shipment_003 IN LOCAL MODE
        ENTITY Available
        ALL FIELDS
        WITH CORRESPONDING #( keys )
        RESULT DATA(entities).

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).

        outboundDelivery = |{ <entity>-OutboundDelivery ALPHA = IN }|. " Add leading zeros

        IF ( outboundDelivery <> <entity>-OutboundDelivery ).

            MODIFY ENTITIES OF zi_shipment_003 IN LOCAL MODE
                ENTITY Available
                UPDATE FIELDS (
                    OutboundDelivery
                )
                WITH VALUE #( (
*                    %is_draft           = <entity>-%is_draft
*                    AvailableUUID       = <entity>-AvailableUUID
                    %tky                = <entity>-%tky

                    OutboundDelivery    = outboundDelivery
                ) )
                MAPPED DATA(mapped2)
                FAILED DATA(failed2)
                REPORTED DATA(reported2).

        ENDIF.

    ENDLOOP.

  ENDMETHOD. " on_outbound_delivery_modify

ENDCLASS. " lhc_available IMPLEMENTATION

CLASS lhc_outbound DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS on_outbound_create FOR DETERMINE ON MODIFY IMPORTING keys FOR Outbound~on_outbound_create.

ENDCLASS. " lhc_outbound DEFINITION

CLASS lhc_outbound IMPLEMENTATION.

  METHOD on_outbound_create. " on Outbound (PDF printing form) create (Outbound ID numbering)

     " Read transfered instances
    READ ENTITIES OF zi_shipment_003 IN LOCAL MODE
        ENTITY Outbound
        ALL FIELDS
        WITH CORRESPONDING #( keys )
        RESULT DATA(entities).

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).

        IF ( <entity>-%is_draft = '00' ). " Saved
        ENDIF.
        IF ( <entity>-%is_draft = '01' ). " Draft
        ENDIF.

*       Read items
        READ ENTITIES OF zi_shipment_003 IN LOCAL MODE
            ENTITY Shipment BY \_Outbound
            ALL FIELDS WITH VALUE #( (
                %is_draft       = <entity>-%is_draft
                ShipmentUUID    = <entity>-ShipmentUUID
            ) )
            RESULT DATA(lt_outbound)
            FAILED DATA(failed1)
            REPORTED DATA(reported1).

        SORT lt_outbound STABLE BY OutboundID DESCENDING.

        DATA newOutboundID TYPE zi_outbound_003-OutboundID.

        IF ( lt_outbound[] IS INITIAL ).
            newOutboundID = 1.
        ELSE.
            READ TABLE lt_outbound INDEX 1 INTO DATA(outbound).
            newOutboundID = outbound-OutboundID + 1.
        ENDIF.

        MODIFY ENTITIES OF zi_shipment_003 IN LOCAL MODE
            ENTITY Outbound
            UPDATE FIELDS (
                OutboundID
            )
            WITH VALUE #( (
                %is_draft       = <entity>-%is_draft
                OutboundUUID    = <entity>-OutboundUUID
                OutboundID      = newOutboundID
            ) )
            MAPPED DATA(mapped2)
            FAILED DATA(failed2)
            REPORTED DATA(reported2).

    ENDLOOP. " on_outbound_create

  ENDMETHOD.

ENDCLASS. " lhc_outbound IMPLEMENTATION
