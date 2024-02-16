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
    METHODS on_modify_recipient FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Shipment~on_modify_recipient.

******** Internal Methods *********

    METHODS get_texts_internal
      IMPORTING VALUE(i_customer)                       TYPE string
                VALUE(i_sales_organization)             TYPE string
                VALUE(i_distribution_channel)           TYPE string
                VALUE(i_division)                       TYPE string
                VALUE(i_language)                       TYPE string
                VALUE(i_long_text_id)                   TYPE string
      RETURNING VALUE(o_text)                           TYPE string.

    METHODS get_address_internal
      IMPORTING VALUE(i_customer)                       TYPE string
      EXPORTING VALUE(o_street_name)                    TYPE string
                VALUE(o_house_number)                   TYPE string.

    METHODS get_forwarding_rule_internal
      IMPORTING VALUE(i_forwarding_rule_id)             TYPE string
      EXPORTING VALUE(o_transportation_type_shipment)   TYPE string
                VALUE(o_freight_forwarder_client)       TYPE string.

    METHODS get_components_internal
      IMPORTING VALUE(i_product)                        TYPE string
      EXPORTING VALUE(o_components)                     TYPE string.

    METHODS split_string_internal
      IMPORTING VALUE(i_str)                            TYPE string
                VALUE(i_len)                            TYPE I OPTIONAL
      RETURNING VALUE(o_str)                            TYPE string.

    METHODS get_commodity_code_internal
      IMPORTING VALUE(i_code)                           TYPE string
      EXPORTING VALUE(o_code)                           TYPE string
                VALUE(o_description)                    TYPE string.


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

*           Outbound Delivery
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


*           Attachments
            READ ENTITIES OF zi_shipment_003  IN LOCAL MODE
                ENTITY Shipment
                BY \_Outbound
                ALL FIELDS WITH VALUE #( (
                    %tky = <entity>-%tky
                ) )
                RESULT DATA(lt_outbound)
                FAILED DATA(failed2)
                REPORTED DATA(reported2).

            IF ( lt_outbound[] IS INITIAL ).
*               Short format message
*                APPEND VALUE #( %key = <entity>-%key %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error text = 'No Attachment.' ) ) TO reported-shipment.
*                RETURN.
            ENDIF.

            SORT lt_outbound STABLE BY OutboundID.

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

            DATA availableID        TYPE string.
            DATA outboundDelivery   TYPE string..
            LOOP AT lt_available INTO DATA(ls_available).
                availableID         = |{ ls_available-AvailableID ALPHA = OUT }|.
                outboundDelivery    = |{ ls_available-OutboundDelivery ALPHA = IN }|.
                SELECT SINGLE UnloadingPointName FROM zc_available_003 WHERE ( AvailableUUID = @ls_available-availableUUID ) INTO @DATA(unloadingPointName).
                request_body = request_body && '<OutboundDelivery>' && cl_abap_char_utilities=>cr_lf.
                request_body = request_body && '<ItemID>' && availableID && '</ItemID>' && cl_abap_char_utilities=>cr_lf.
                request_body = request_body && '<ID>' && outboundDelivery && '</ID>' && cl_abap_char_utilities=>cr_lf.
                request_body = request_body && '<NumberOfPackages>' && unloadingPointName && '</NumberOfPackages>' && cl_abap_char_utilities=>cr_lf.
                request_body = request_body && '</OutboundDelivery>' && cl_abap_char_utilities=>cr_lf.
            ENDLOOP.

            DATA outboundID TYPE string.
            DATA fileName   TYPE string.
            DATA mimeType   TYPE string.
            DATA base64     TYPE string.
            LOOP AT lt_outbound INTO DATA(ls_outbound).
                outboundID      = |{ ls_outbound-OutboundID ALPHA = OUT }|.
                CONDENSE outboundID NO-GAPS.
                fileName        = ls_outbound-FileName.
                mimeType        = ls_outbound-MimeType.
                SELECT SINGLE attachment FROM zc_outbound_003 WHERE ( OutboundUUID = @ls_outbound-OutboundUUID ) INTO @DATA(attachment).
                base64       = cl_web_http_utility=>encode_x_base64( attachment ). " convert Xstring (binary) into Base64 (string)
                request_body = request_body && '<Attachment>' && cl_abap_char_utilities=>cr_lf.
                request_body = request_body && '<ID>' && outboundID && '</ID>' && cl_abap_char_utilities=>cr_lf.
                request_body = request_body && '<FileName>' && fileName && '</FileName>' && cl_abap_char_utilities=>cr_lf.
                request_body = request_body && '<MimeType>' && mimeType && '</MimeType>' && cl_abap_char_utilities=>cr_lf.
                request_body = request_body && '<Content>' && cl_abap_char_utilities=>cr_lf.
*               Split by 50
                DATA(l) = STRLEN( base64 ). " total length
                DATA(p) = 0.                " starting position
                DATA s TYPE string.         " substring C(50)
                DO 1000 TIMES.
                    IF      ( ( p + 50 ) < l ).
                        s = base64+p(50).
                    ELSEIF  ( ( p + 0  ) < l ).
                        s = base64+p.
                    ELSE.
                        EXIT.
                    ENDIF.
                    request_body = request_body && s && cl_abap_char_utilities=>cr_lf.
                    p = p + 50.
                ENDDO.
                request_body = request_body && '</Content>' && cl_abap_char_utilities=>cr_lf.
                request_body = request_body && '</Attachment>' && cl_abap_char_utilities=>cr_lf.
            ENDLOOP.

            request_body = request_body && '</ShipmentBinding>' && cl_abap_char_utilities=>cr_lf.

*           Do Free Style HTTP Request
            TRY.

                DATA i_url         TYPE string VALUE 'https://felina-hu-scpi-test-eyjk96r2.it-cpi018-rt.cfapps.eu10-003.hana.ondemand.com/http/FiegeShipmentBindingRequest'.
                DATA i_username    TYPE string VALUE 'sb-1e950f89-c676-4acd-b0dc-24e58f8aab45!b143168|it-rt-felina-hu-scpi-test-eyjk96r2!b117912'.
                DATA i_password    TYPE string VALUE 'cc744b1f-5237-4a7e-ab44-858fdd00fb73$3wcTQpYfe1kbmjltnA8zSDb5ogj0TpaYon4WHM-TwfE='.

                DATA(system_url) = cl_abap_context_info=>get_system_url( ).
                IF ( system_url(8) = 'my404898' ). " dev-cust
                    i_url = 'https://felina-hu-scpi-test-eyjk96r2.it-cpi018-rt.cfapps.eu10-003.hana.ondemand.com/http/FiegeOutboundDevCust'.
                ENDIF.

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

            CATCH cx_abap_context_info_error INTO DATA(lx_abap_context_info_error).
                "handle exception
*              RAISE SHORTDUMP lx_abap_context_info_error.
                APPEND VALUE #( %key = <entity>-%key %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error text = 'ABAP Context Info Error.' ) ) TO reported-shipment.
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
                FAILED DATA(failed3)
                MAPPED DATA(mapped3)
                REPORTED DATA(reported3).

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

*   Header
    DATA BEGIN OF header.

        DATA ID                     TYPE string.
        DATA CreationDate           TYPE string.
        DATA TotalCurrencyCode      TYPE string.
        DATA TotalQuantity          TYPE string.
        DATA TotalListPrice         TYPE string.
        DATA TotalDiscount          TYPE string.
        DATA TotalMainPrice         TYPE string.

*       Postal Address
        DATA StreetName             TYPE string.
        DATA HouseID                TYPE string.
        DATA CityName               TYPE string.
        DATA CountryCode            TYPE string.
        DATA StreetPostalCode       TYPE string.
        DATA DateOfIssue            TYPE string.
        DATA CurrencyCode           TYPE string.

*       Name
        DATA FirstLineName          TYPE string.
        DATA SecondLineName         TYPE string.
        DATA ThirdLineName          TYPE string.
        DATA FourthLineName         TYPE string.
        DATA FifthLineName          TYPE string.

*       Formatted Address
        DATA FirstLineDescription   TYPE string.
        DATA ThirdLineDescription   TYPE string.

    DATA END OF header.

*   Item
    DATA BEGIN OF item.
        DATA MaterialCup                TYPE string.
        DATA Description                TYPE string.
        DATA MaterialColor              TYPE string.
        DATA MaterialQuantity           TYPE string.
        DATA MatierialID                TYPE string.
        DATA MaterialPrice              TYPE string.
        DATA MaterialDiscountPercent    TYPE string. " '51%'
        DATA CountryOfOrigin            TYPE string.
    DATA END OF item.
    DATA it_item LIKE TABLE OF item.

*   Outbound (PDF)
    DATA it_outbound_create TYPE TABLE FOR CREATE zi_shipment_003\_Outbound.

    DATA pricingElement TYPE I_BillingDocumentItemPrcgElmnt.

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
            SELECT SINGLE * FROM zi_repository_003 WHERE ( RepositoryID = 'INVOICE' ) INTO @DATA(repository).
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

*               Creation Date
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
                header-ID                   = 'ISB-' && <entity>-ShipmentID. " 'ISB-1000000059'.
                header-CreationDate         = formatted_date.
                header-TotalCurrencyCode    = customersalesarea-Currency.
                header-TotalQuantity        = ''.
                header-TotalListPrice       = ''.
                header-TotalDiscount        = ''.
                header-TotalMainPrice       = ''.

*               Name
                header-FirstLineName        = <entity>-OrganisationFormattedName1.                      " PIU BIU " SKLEP Z BIELIZNA
                header-SecondLineName       = |{ <entity>-StreetName } { <entity>-HouseID }|.           " Plac Bankowy 4 VA BANK
                header-ThirdLineName        = |{ <entity>-StreetPostalCode } { <entity>-CityName }|.    " 00-095 WARSZAWA
                header-FourthLineName       = <entity>-CountryCode. " Poland

*               Postal Address
                header-StreetName           = ''.
                header-HouseID              = ''.
                header-CityName             = ''.
                header-CountryCode          = ''.
                header-StreetPostalCode     = ''.
                header-DateOfIssue          = ''.
                header-CurrencyCode         = ''.

*               Formatted Address
                header-FirstLineDescription = ''.
                header-ThirdLineDescription = ''.

*               Item sections:
                READ ENTITIES OF zi_shipment_003 IN LOCAL MODE
                    ENTITY Shipment BY \_Available
                    ALL FIELDS WITH VALUE #( (
                        %tky = <entity>-%tky
                    ) )
                    RESULT DATA(it_available)
                    FAILED DATA(failed1)
                    REPORTED DATA(reported1).

                SORT it_available STABLE BY AvailableID.

                DATA quantity   TYPE I_BillingDocumentItem-BillingQuantity.
                DATA listPrice  TYPE I_BillingDocumentItem-NetAmount.
                DATA discount   TYPE I_BillingDocumentItem-NetAmount.
                DATA mainPrice  TYPE I_BillingDocumentItem-NetAmount.

                DATA totalQuantity  TYPE I_BillingDocumentItem-BillingQuantity  VALUE 0.
                DATA totalListPrice TYPE I_BillingDocumentItem-NetAmount        VALUE 0.
                DATA totalDiscount  TYPE I_BillingDocumentItem-NetAmount        VALUE 0.
                DATA totalMainPrice TYPE I_BillingDocumentItem-NetAmount        VALUE 0.

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

*                       Product
                        "SELECT SINGLE * FROM I_Product WHERE ( Product = @billingdocumentitem-Product ) INTO @DATA(product).

*                       Product -> Model/Color/Cupsize/Backsize
                        SPLIT billingdocumentitem-Product AT '-' INTO DATA(model) DATA(color) DATA(cupsize) DATA(backsize).

*                       Color Description
                        SELECT SINGLE zi_color_005~Description FROM zi_color_005 WHERE ( ColorID = @color ) INTO @DATA(colorDescription).

*                       Discount (from PricingElement)
                        CLEAR pricingElement.
                        SELECT SINGLE
                                *
                            FROM
                                I_BillingDocumentItem\_PricingElement as PricingElement
                            WHERE
                                ( BillingDocument     = @billingdocumentitem-BillingDocument        ) AND
                                ( BillingDocumentItem = @billingdocumentitem-BillingDocumentItem    ) AND
                                ( ConditionType = 'DRG1' )
                            INTO
                                @pricingElement.

                        quantity  = ( billingdocumentitem-BillingQuantity ).
                        mainPrice = ( billingdocumentitem-NetAmount ).
                        discount  = ( pricingElement-ConditionAmount ). " negative value
                        listPrice = ( billingdocumentitem-NetAmount - pricingElement-ConditionAmount ).

*                       Fix - In the column “Preis” there must be the gross value (PPR0 price)
*                       Gross Price (from PricingElement)
                        CLEAR pricingElement.
                        SELECT SINGLE
                                *
                            FROM
                                I_BillingDocumentItem\_PricingElement as PricingElement
                            WHERE
                                ( BillingDocument     = @billingdocumentitem-BillingDocument        ) AND
                                ( BillingDocumentItem = @billingdocumentitem-BillingDocumentItem    ) AND
                                ( ConditionType = 'PPR0' )
                            INTO
                                @pricingElement.
                        DATA(grossAmount)   = pricingElement-ConditionAmount.

*                       Rebate % and Amount (from PricingElement)
                        CLEAR pricingElement.
                        SELECT SINGLE
                                *
                            FROM
                                I_BillingDocumentItem\_PricingElement as PricingElement
                            WHERE
                                ( BillingDocument     = @billingdocumentitem-BillingDocument        ) AND
                                ( BillingDocumentItem = @billingdocumentitem-BillingDocumentItem    ) AND
                                ( ConditionType = 'ZK07' )
                            INTO
                                @pricingElement.
                        DATA(rebatePercent) = pricingElement-ConditionRateValue.
                        DATA(rebateAmount)  = pricingElement-ConditionAmount.
                        rebateAmount        = - ( rebateAmount ). " 5.61

*                       Verpackungsentgelt - Packaging fee (from PricingElement)
                        CLEAR pricingElement.
                        SELECT SINGLE
                                *
                            FROM
                                I_BillingDocumentItem\_PricingElement as PricingElement
                            WHERE
                                ( BillingDocument     = @billingdocumentitem-BillingDocument        ) AND
                                ( BillingDocumentItem = @billingdocumentitem-BillingDocumentItem    ) AND
                                ( ConditionType = 'ZLAB' )
                            INTO
                                @pricingElement.
                        DATA(feeAmount) = pricingElement-ConditionAmount. " 5.00

*                       Take a few amounts just from the Invoice Item
                        grossAmount     = billingdocumentitem-Subtotal1Amount.
                        feeAmount       = billingdocumentitem-Subtotal4Amount.

*                       Item:
                        CLEAR item.
                        item-MaterialCup                = cupsize.
                        item-Description                = billingdocumentitem-BillingDocumentItemText.
                        item-MaterialColor              = colorDescription.
                        item-MaterialQuantity           = |{ billingdocumentitem-BillingQuantity DECIMALS = 1 }|.
                        item-MatierialID                = |{ billingdocumentitem-Product ALPHA = IN }|.
                        item-MaterialPrice              = |{ grossAmount DECIMALS = 2 }|. " 47.25
                        item-MaterialDiscountPercent    = |{ rebatePercent }|. " '11.4%'
                        item-CountryOfOrigin            = billingdocumentitem-CountryOfOrigin.
                        APPEND item TO it_item.

                        totalQuantity   = totalQuantity     + ( quantity ).
                        totalListPrice  = totalListPrice    + ( item-MaterialPrice ).
                        totalDiscount   = totalDiscount     + ( rebateAmount ).
                        totalMainPrice  = totalMainPrice    + ( mainPrice - feeAmount ).

                    ENDLOOP.

                ENDLOOP.

                header-TotalCurrencyCode    = billingdocument-TransactionCurrency.  " Währung

                header-TotalQuantity        = |{ totalQuantity  DECIMALS = 1 }|.    " Menge
                header-TotalListPrice       = |{ totalListPrice DECIMALS = 2 }|.    " Warenwert
                header-TotalDiscount        = |{ totalDiscount  DECIMALS = 2 }|.    " Positionsrabatt
                header-TotalMainPrice       = |{ totalMainPrice DECIMALS = 2 }|.    " Rechnungsbetrag


*               Import Invoice recipient address (Hard Code, for now)
                header-FirstLineName    = 'Felina GmbH'.
                header-SecondLineName   = 'c/o CCI France Suisse'.
                header-ThirdLineName    = 'Route de Jussy 35'.
                header-FourthLineName   = '1211 Genève 6'.
                header-FifthLineName    = 'Schweiz'.

*               Generate XML
                DATA xml_data TYPE string VALUE ''.

*               Header Section
                xml_data = xml_data &&
                    '<?xml version="1.0" encoding="UTF-8"?>' && cl_abap_char_utilities=>cr_lf &&
                    '<InvoiceShipmentBindingForm>' && cl_abap_char_utilities=>cr_lf &&
                    '<InvoiceShipmentBinding>' && cl_abap_char_utilities=>cr_lf &&

                    '<ID>' && header-ID && '</ID>' && cl_abap_char_utilities=>cr_lf && " ISB-100062
                    '<CreationDate>' && header-CreationDate && '</CreationDate>' && cl_abap_char_utilities=>cr_lf && " '2024-01-09'
                    '<TotalCurrencyCode>' && header-TotalCurrencyCode && '</TotalCurrencyCode>' && cl_abap_char_utilities=>cr_lf && " 'EUR'
                    '<TotalQuantity unitCode="">' && header-TotalQuantity && '</TotalQuantity>' && cl_abap_char_utilities=>cr_lf && " '149.00'
                    '<TotalListPrice currencyCode="">' && header-TotalListPrice && '</TotalListPrice>' && cl_abap_char_utilities=>cr_lf && " '3074.45'
                    '<TotalDiscount currencyCode="">' && header-TotalDiscount && '</TotalDiscount>' && cl_abap_char_utilities=>cr_lf &&
                    '<TotalMainPrice currencyCode="">' && header-TotalMainPrice && '</TotalMainPrice>' && cl_abap_char_utilities=>cr_lf && " '3074.45'

                    '<ToShipmentBinding>' && cl_abap_char_utilities=>cr_lf &&
                    '<ToImportInvoiceRecipient>' && cl_abap_char_utilities=>cr_lf &&
                    '<AddressSnapshot>' && cl_abap_char_utilities=>cr_lf &&
                    '<Name>' && cl_abap_char_utilities=>cr_lf &&
                    '<Name>' && cl_abap_char_utilities=>cr_lf &&
                    '<FirstLineName>' && header-FirstLineName && '</FirstLineName>' && cl_abap_char_utilities=>cr_lf && " 'PIU BIU " SKLEP Z BIELIZNA'
                    '<SecondLineName>' && header-SecondLineName && '</SecondLineName>' && cl_abap_char_utilities=>cr_lf && " 'Plac Bankowy 4 VA BANK'
                    '<ThirdLineName>' && header-ThirdLineName && '</ThirdLineName>' && cl_abap_char_utilities=>cr_lf && " '00-095 WARSZAWA'
                    '<FourthLineName>' && header-FourthLineName && '</FourthLineName>' && cl_abap_char_utilities=>cr_lf && " 'Poland'
                    '<FifthLineName>' && header-FifthLineName && '</FifthLineName>' && cl_abap_char_utilities=>cr_lf && " 'Poland'
                    '</Name>' && cl_abap_char_utilities=>cr_lf &&
                    '</Name>' && cl_abap_char_utilities=>cr_lf &&
                    '<PostalAddress>' && cl_abap_char_utilities=>cr_lf &&
                    '<CityName>' && header-CityName && '</CityName>' && cl_abap_char_utilities=>cr_lf &&
                    '<StreetPostalCode>' && header-StreetPostalCode && '</StreetPostalCode>' && cl_abap_char_utilities=>cr_lf &&
                    '<StreetName>' && header-StreetName && '</StreetName>' && cl_abap_char_utilities=>cr_lf &&
                    '<HouseID>' && header-HouseID && '</HouseID>' && cl_abap_char_utilities=>cr_lf &&
                    '</PostalAddress>' && cl_abap_char_utilities=>cr_lf &&
                    '<PostalAddress>' && cl_abap_char_utilities=>cr_lf &&
                    '<HouseID>' && header-HouseID && '</HouseID>' && cl_abap_char_utilities=>cr_lf &&
                    '</PostalAddress>' && cl_abap_char_utilities=>cr_lf &&
                    '<FormattedAddress>' && cl_abap_char_utilities=>cr_lf &&
                    '<FormattedPostalAddress>' && cl_abap_char_utilities=>cr_lf &&
                    '<FirstLineDescription>' && header-FirstLineDescription && '</FirstLineDescription>' && cl_abap_char_utilities=>cr_lf &&
                    '<ThirdLineDescription>' && header-ThirdLineDescription && '</ThirdLineDescription>' && cl_abap_char_utilities=>cr_lf &&
                    '</FormattedPostalAddress>' && cl_abap_char_utilities=>cr_lf &&
                    '</FormattedAddress>' && cl_abap_char_utilities=>cr_lf &&
                    '</AddressSnapshot>' && cl_abap_char_utilities=>cr_lf &&
                    '</ToImportInvoiceRecipient>' && cl_abap_char_utilities=>cr_lf &&
                    '</ToShipmentBinding>' && cl_abap_char_utilities=>cr_lf.

*               Item Section
                LOOP AT it_item INTO item.
                    xml_data = xml_data &&
                        '<Items>' && cl_abap_char_utilities=>cr_lf &&
                        '<MaterialCup>' && item-MaterialCup && '</MaterialCup>' && cl_abap_char_utilities=>cr_lf && " 'C'
                        '<Description languageCode="">' && item-Description && '</Description>' && cl_abap_char_utilities=>cr_lf && " 'Moments - Bügel-BH'
                        '<MaterialColor>' && item-MaterialColor && '</MaterialColor>' && cl_abap_char_utilities=>cr_lf && " 'white'
                        '<MaterialQuantity unitCode="">' && item-MaterialQuantity && '</MaterialQuantity>' && cl_abap_char_utilities=>cr_lf && " '1.00'
                        '<MatierialID schemeAgencyID="" schemeID="">' && item-MatierialID && '</MatierialID>' && cl_abap_char_utilities=>cr_lf && " '000519'
                        '<MaterialPrice currencyCode="">' && item-MaterialPrice && '</MaterialPrice>' && cl_abap_char_utilities=>cr_lf && " '18.90'
                        '<MaterialDiscountPercent>' && item-MaterialDiscountPercent && '</MaterialDiscountPercent>' && cl_abap_char_utilities=>cr_lf &&
                        '<CountryOfOrigin>' && item-CountryOfOrigin && '</CountryOfOrigin>' && cl_abap_char_utilities=>cr_lf && " 'MA'
                        '</Items>' && cl_abap_char_utilities=>cr_lf.
                ENDLOOP.

                xml_data = xml_data &&
                    '</InvoiceShipmentBinding>' && cl_abap_char_utilities=>cr_lf &&
                    '</InvoiceShipmentBindingForm>'.

*               Fix some 'harmful' characters
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
                              iv_locale        = 'de_DE'
*                              iv_locale        = 'en_EN'
                              is_options       = ls_options
                    IMPORTING ev_pdf           = ev_pdf
                              ev_pages         = ev_pages
                              ev_trace_string  = ev_trace_string
                ).

                IF ( sy-subrc = 0 ).

*                   Convert Xstring (binary) into Base64 (string) (for testing)
                    DATA(base64_pdf) = cl_web_http_utility=>encode_x_base64( ev_pdf ).

                    DATA(filename) = repository-RepositoryID && '_' && <entity>-ShipmentID && '.PDF'.
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
            "handle exception
        CATCH cx_abap_message_digest.
            "handle exception
        CATCH cx_fp_ads_util INTO DATA(fp_ads_util).
            "handle exception
            RAISE SHORTDUMP fp_ads_util.
            APPEND VALUE #( %key = <entity>-%key %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error text = 'Rendering PDF error.' ) ) TO reported-shipment.
            RETURN.
        ENDTRY.

    ENDLOOP.

  ENDMETHOD. " create_invoice

  METHOD create_tkz_list. " on Create TKZ List

*   Header
    DATA BEGIN OF header.
        DATA ID                             TYPE string.
        DATA TKZNumber                      TYPE string.
        DATA ShipmentID                     TYPE string.
        DATA CreationDate                   TYPE string.
        DATA InvoiceRecipient               TYPE string.
        DATA InvoiceRecipientName           TYPE string.
        DATA CustomerInvoiceListAsString    TYPE string.
    DATA END OF header.

*   Item
    DATA BEGIN OF item.
        DATA ID                     TYPE string.
        DATA ItemID                 TYPE string.
        DATA SiteLogisticsRequestID TYPE string.
        DATA MaterialCup            TYPE string.
        DATA MaterialComposition    TYPE string.
        DATA MatierialID            TYPE string.
        DATA MaterialQuantity       TYPE string.
        DATA OutboundDeliveryID     TYPE string.
    DATA END OF item.
    DATA it_item LIKE TABLE OF item.

*   Invoice
    DATA BEGIN OF invoice.
        DATA InvoiceDocumentID      TYPE string.
        DATA InvoiceQuantity        TYPE string.
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
            SELECT SINGLE * FROM zi_repository_003 WHERE ( RepositoryID = 'TKZ_LIST' ) INTO @DATA(repository).
            IF (  sy-subrc = 0 ).

                DATA(partyID) = |{ <entity>-PartyID ALPHA = IN }|.

*               Customer
                SELECT SINGLE * FROM I_Customer WHERE ( Customer = @partyID ) INTO @DATA(customer).

*               Currency Code (default for the Shipment Group)
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

*               Header
                header-ID                           = |{ <entity>-ShipmentID ALPHA = OUT }|. " '1000000059'.
                header-TKZNumber                    = |{ <entity>-ShipmentID ALPHA = OUT }|.
                header-ShipmentID                   = |{ <entity>-ShipmentID ALPHA = OUT }|. " '1000000059'.
                header-CreationDate                 = cl_abap_context_info=>get_system_date( ).
                header-InvoiceRecipient             = |{ partyID ALPHA = OUT }|.
                header-InvoiceRecipientName         = customer-BPCustomerName.
                header-CustomerInvoiceListAsString  = ''.

*               Item and Invoice sections:
                READ ENTITIES OF zi_shipment_003 IN LOCAL MODE
                    ENTITY Shipment BY \_Available
                    ALL FIELDS WITH VALUE #( (
                        %tky = <entity>-%tky
                    ) )
                    RESULT DATA(it_available)
                    FAILED DATA(failed1)
                    REPORTED DATA(reported1).

                DATA(count) = 0.

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

*                       Product
                        SELECT SINGLE * FROM I_Product  WHERE ( Product = @billingdocumentitem-Product ) INTO @DATA(product).

*                       Material Quantity
                        DATA materialQuantity TYPE string.
                        materialQuantity    = |{ billingdocumentitem-BillingQuantity    DECIMALS = 1 }|.

                        SPLIT billingdocumentitem-Product AT '-' INTO DATA(model) DATA(color) DATA(capsize) DATA(backsize).

*                       Material Composition
                        DATA material_composition TYPE string.
                        get_components_internal(
                          EXPORTING
                            i_product    = CONV string( billingdocumentitem-Product )
                          IMPORTING
                            o_components = material_composition
                        ).

                        count = count + 1.

*                       Item:
                        CLEAR item.
                        item-ID                     = count.
                        item-ItemID                 = model.
                        item-SiteLogisticsRequestID = outbounddelivery-ShippingPoint.
                        item-MaterialCup            = capsize.
                        item-MaterialComposition    = material_composition. " 'material composition'.
                        item-MatierialID            = billingdocumentitem-Product.
                        item-MaterialQuantity       = materialQuantity. " '1.0'.
                        item-OutboundDeliveryID     = outbounddeliveryitem-OutboundDelivery. "
                        APPEND item TO it_item.

*                       Invoice:
                        CLEAR invoice.
                        invoice-InvoiceDocumentID   = |{ billingdocumentitem-BillingDocument ALPHA = OUT }|. " '80000000'.
                        invoice-InvoiceQuantity     = materialQuantity. " '1'.
                        APPEND invoice TO it_invoice.

                    ENDLOOP.
                ENDLOOP.

*               Group it_item By MatierialID
                SORT it_item STABLE BY ItemID MatierialID.
                DATA it_item2 LIKE it_item.
                DATA item2 LIKE item.
                CLEAR item2.
                LOOP AT it_item INTO item.
                    IF ( item-ItemID = item2-ItemID ) AND
                       ( sy-tabix <> 1 ).
                        item2-MaterialQuantity  = |{ 0  + item2-MaterialQuantity + item-MaterialQuantity DECIMALS = 1 }|.
                        IF ( item2-MaterialCup NS item-MaterialCup ).
                            IF ( item2-MaterialCup IS NOT INITIAL ).
                                item2-MaterialCup = item2-MaterialCup && ','.
                            ENDIF.
                            item2-MaterialCup = item2-MaterialCup && item-MaterialCup.
                        ENDIF.
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
                SORT it_invoice STABLE BY InvoiceDocumentID.
                DATA it_invoice2 LIKE it_invoice.
                DATA invoice2 LIKE invoice.
                CLEAR invoice2.
                LOOP AT it_invoice INTO invoice.
                    IF ( invoice-InvoiceDocumentID = invoice2-InvoiceDocumentID ) AND
                       ( sy-tabix <> 1 ).
                        invoice2-InvoiceQuantity  = |{ 0 + invoice2-InvoiceQuantity  + invoice-InvoiceQuantity DECIMALS = 1 }|.
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
                    '<TKZListForm>' && cl_abap_char_utilities=>cr_lf &&
                    '<TKZList>' && cl_abap_char_utilities=>cr_lf.

*               Header Section
                xml_data = xml_data &&
                    '<ID>' && header-ID && '</ID>' && cl_abap_char_utilities=>cr_lf &&
                    '<TKZNumber>' && header-TKZNumber && '</TKZNumber>' && cl_abap_char_utilities=>cr_lf && " '100012'
                    '<ShipmentID>' && header-ShipmentID && '</ShipmentID>' && cl_abap_char_utilities=>cr_lf &&
                    '<CreationDate>' && header-CreationDate && '</CreationDate>' && cl_abap_char_utilities=>cr_lf &&
                    '<InvoiceRecipient>' && header-InvoiceRecipient && '</InvoiceRecipient>' && cl_abap_char_utilities=>cr_lf &&
                    '<InvoiceRecipientName>' && header-InvoiceRecipientName && '</InvoiceRecipientName>' && cl_abap_char_utilities=>cr_lf &&
                    '<CustomerInvoiceListAsString>' && header-CustomerInvoiceListAsString && '</CustomerInvoiceListAsString>' && cl_abap_char_utilities=>cr_lf.

*               Item Section
                LOOP AT it_item2 INTO item2.
                    xml_data = xml_data &&
                        '<Items>' && cl_abap_char_utilities=>cr_lf &&
                        '<ID>' && item2-ID && '</ID>' && cl_abap_char_utilities=>cr_lf &&
                        '<ItemID>' && item2-ItemID && '</ItemID>' && cl_abap_char_utilities=>cr_lf &&
                        '<SiteLogisticsRequestID>' && item2-SiteLogisticsRequestID && '</SiteLogisticsRequestID>' && cl_abap_char_utilities=>cr_lf &&
                        '<MaterialCup>' && item2-MaterialCup && '</MaterialCup>' && cl_abap_char_utilities=>cr_lf &&
                        '<MaterialComposition>' && item2-MaterialComposition && '</MaterialComposition>' && cl_abap_char_utilities=>cr_lf &&
                        '<MatierialID>' && item2-MatierialID && '</MatierialID>' && cl_abap_char_utilities=>cr_lf &&
                        '<MaterialQuantity>' && item2-MaterialQuantity && '</MaterialQuantity>' && cl_abap_char_utilities=>cr_lf &&
                        '<OutboundDeliveryID>' && item2-OutboundDeliveryID && '</OutboundDeliveryID>' && cl_abap_char_utilities=>cr_lf &&
                        '</Items>' && cl_abap_char_utilities=>cr_lf.
                ENDLOOP.

*               Invoice Section
                LOOP AT it_invoice2 INTO invoice2.
                    xml_data = xml_data &&
                        '<InvoiceDocument>' && cl_abap_char_utilities=>cr_lf &&
                        '<InvoiceDocumentID schemeAgencyID="" schemeAgencySchemeAgencyID="" schemeID="">' && invoice2-InvoiceDocumentID && '</InvoiceDocumentID>' && cl_abap_char_utilities=>cr_lf &&
                        '<InvoiceQuantity>' && invoice2-InvoiceQuantity && '</InvoiceQuantity>' && cl_abap_char_utilities=>cr_lf &&
                        '</InvoiceDocument>' && cl_abap_char_utilities=>cr_lf.
                ENDLOOP.

                xml_data = xml_data &&
                    '</TKZList>' && cl_abap_char_utilities=>cr_lf &&
                    '</TKZListForm>' && cl_abap_char_utilities=>cr_lf.

*               Fix some 'harmful' characters
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
                              iv_locale        = 'de_DE'
                              is_options       = ls_options
                    IMPORTING ev_pdf           = ev_pdf
                              ev_pages         = ev_pages
                              ev_trace_string  = ev_trace_string
                ).

                IF ( sy-subrc = 0 ).

*                   Convert Xstring (binary) into Base64 (string) (for testing)
                    DATA(base64_pdf) = cl_web_http_utility=>encode_x_base64( ev_pdf ).

                    DATA(filename) = repository-RepositoryID && '_' && <entity>-ShipmentID && '.PDF'.
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

*                       Commodity Code Text
*                        DATA commodityCodeText TYPE string.
*                        SELECT SINGLE
*                                \_CommodityCodeText-TrdClassfctnNmbrText AS TrdClassfctnNmbrText
*                             FROM
*                                C_ProdCommodityCodeForKeyDate( p_keydate = @billingdocument-billingdocumentdate )
*                             WHERE
*                                ( C_ProdCommodityCodeForKeyDate~Product                     = @billingdocumentitem-Product                   ) AND
*                                ( C_ProdCommodityCodeForKeyDate~Country                     = @billingdocumentitem-DepartureCountry          ) AND
*                                ( C_ProdCommodityCodeForKeyDate~ValidityStartDate           = @prodcommoditycodeforkeydate-ValidityStartDate ) AND
*                                ( C_ProdCommodityCodeForKeyDate~TrdClassfctnNmbrSchm        = 'EU01'                                         ) AND
*                                ( C_ProdCommodityCodeForKeyDate~TrdClassfctnNmbrSchmCntnt   = 'EU01'                                         ) AND
*                                ( \_CommodityCodeText-TrdClassfctnNmbrSchmCntnt IS NOT NULL )
*                             INTO
*                                @DATA(commodityCodeText).
                        get_commodity_code_internal(
                            EXPORTING
                                i_code        = CONV string( prodcommoditycodeforkeydate-CommodityCode )
                            IMPORTING
                                o_code        = DATA(commodityCode)
                                o_description = DATA(commodityCodeText)
                        ).

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

*                       Country Of Origin
*                        DATA countryOfOrigin TYPE string.
*                        SELECT SINGLE
*                                \_ESHProductPlant-CountryOfOrigin
*                            FROM
*                                I_Product
*                            WHERE
*                                ( I_Product~Product         = @billingdocumentitem-Product  ) AND
*                                ( \_ESHProductPlant-Plant   = '1000'                        ) AND " Fiege DE
*                                ( \_ESHProductPlant-Product IS NOT NULL )
*                            INTO
*                                @DATA(countryOfOrigin).
                        SELECT SINGLE
                                ProdPlantInternationalTrade~CountryOfOrigin
                            FROM
                                I_ProductTP_2\_ProductPlant\_ProdPlantInternationalTrade as ProdPlantInternationalTrade
                            WHERE
                                ( Product = @billingdocumentitem-Product ) AND
                                ( Plant   = '1000'                       )  " Fiege DE
                            INTO
                                @DATA(countryOfOrigin).

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
                        item-Items                 = commodityCodeText.                             " 'Brassel for ladies'.
                        item-CountryOfOrigin       = countryOfOrigin.                               " 'AU'.
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

*               Group it_item By CustomsTariffNumber (Commodity Code), CountryOfOrigin
                SORT it_item STABLE BY CustomsTariffNumber CountryOfOrigin.
                DATA it_item2 LIKE it_item.
                DATA item2 LIKE item.
                CLEAR item2.
                LOOP AT it_item INTO item.
                    IF ( item-CustomsTariffNumber   = item2-CustomsTariffNumber ) AND
                       ( item-CountryOfOrigin       = item2-CountryOfOrigin     ) AND
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

*               Fix some 'harmful' characters
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

                    DATA(filename) = repository-RepositoryID && '_' && <entity>-ShipmentID && '.PDF'.
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

  METHOD create_eci. " on Create ECI

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

*       Item and Invoice sections:
        READ ENTITIES OF zi_shipment_003 IN LOCAL MODE
            ENTITY Shipment BY \_Available
            ALL FIELDS WITH VALUE #( (
                %tky = <entity>-%tky
            ) )
            RESULT DATA(it_available)
            FAILED DATA(failed1)
            REPORTED DATA(reported1).

        DATA body TYPE string VALUE ''.

        body = body && 'Proveedor;Empresa Recepción;Lugar Recepción;Empresa Destino;Lugar destino;Uneco;Pedido;Albarán;Bultos;Embalaje;Transportista;Expedición' && cl_abap_char_utilities=>cr_lf.

        LOOP AT it_available INTO DATA(available).

*           Outbound Delivery
            SELECT SINGLE * FROM I_OutboundDelivery WHERE ( OutboundDelivery = @available-OutboundDelivery ) INTO @DATA(outboundDelivery).

*           Outbound Delivery Item
            SELECT SINGLE * FROM I_OutboundDeliveryItem WHERE ( OutboundDelivery = @available-OutboundDelivery ) INTO @DATA(outboundDeliveryItem).

*           Sales Order
            SELECT SINGLE * FROM I_SalesOrder WHERE ( SalesOrder = @outboundDeliveryItem-ReferenceSDDocument ) INTO @DATA(salesOrder).

*           Address Details
            SELECT SINGLE * FROM I_BusinessPartnerAddressTP_3  WHERE ( BusinessPartner = @outboundDelivery-SoldToParty ) INTO @DATA(businessPartnerAddress).

*           Proveedor
            body = body && '1125518' && ';'.

*           Empresa RecepciÃ³n
            body = body && '1' && ';'.

*            Lugar RecepciÃ³n
*            "Shipment Group Madrid = 50, Shipment Group Barcelona = 62, Shipment Group Portugal = 53" (hard code)
*            CASE <entity>-PartyID.  " Shipment Group (Sendungsgruppe)
*                WHEN 'ECI VALDEMORO MADRID'.
*                    body = body && '50;'.
*                WHEN 'ECI MONTORNES BARCELONA'.
*                    body = body && '62;'.
*                WHEN OTHERS.
*                    body = body && ';'.
*            ENDCASE.
*           Benedikt Pecuch: "zoberte to z Customer master data zo shipment group Name 3"
            body = body && <entity>-OrganisationFormattedName3 && ';'. " 50

*           Empresa Destino
            body = body && '1' && ';'.

*            TODO - Taken from ByDesign:
*            IF ( <entity>-Response IS NOT INITIAL ).
*            {
*                var query = SalesOrder.QueryByElements;
*                var selectionParams = query.CreateSelectionParams();
*                selectionParams.Add(query.BuyerID.content, "I", "EQ", addedShipmentResponse.Response.ExternalReference);
*                var resultData = query.Execute(selectionParams);
*                var shopNumber : ID;
*                foreach(var salesOrder in resultData)
*                {
*                    if(salesOrder.BuyerParty.IsSet())
*                    {
*                        if(salesOrder.BuyerParty.PartyKey.PartyID.content.Substring(0,5) == "ES101")
*                        {
*                            var addressInfo;
*                            foreach(var i in salesOrder.BuyerParty.Party.Customer.AddressInformation)
*                            {
*                                if(i.AddressCurrentAddressDeterminationProcesses.IsSet())
*                                {
*                                    if(i.AddressCurrentAddressDeterminationProcesses.DefaultAddressDeterminationProcessRelevanceIndicator == true)
*                                    {
*                                        addressInfo = i;
*                                    }
*                                }
*                            }
*                            if(addressInfo.Address.IsSet())
*                            {
*                                if(addressInfo.Address.DefaultPostalAddressRepresentation.IsSet())
*                                {
*                                    shopNumber = addressInfo.Address.DefaultPostalAddressRepresentation.StreetPrefixName.Substring(0,3);
*                                    shopNumber = shopNumber.RemoveLeadingZeros();
*                                }
*                            }
*                            break;
*                        }
*                    }
*
*                }
*                body = body + shopNumber + ";";
*
*                body = body + "110;";
*                body = body + addedShipmentResponse.Response.ExternalReference + ";";
*                body = body + addedShipmentResponse.Response.ODRequestID.RemoveLeadingZeros() + ";";
*                body = body + addedShipmentResponse.Response.NumberOfPackages.RoundToString(0) + ";";
*            }
*            ELSE.
*                body = body && ';100;'.
*            ENDIF.

*           Lugar destino ("customer master data -> Main Adress -> Adress Line 1 -> first 3 digits")
            body = body && businessPartnerAddress-StreetPrefixName(3) && ';'. " 994

*           Uneco (always 110)
            body = body && '110' && ';'. " 110

* New Change
*           Pedido (External Reference (from SO))
            body = body && |{ salesOrder-PurchaseOrderByCustomer ALPHA = OUT }| && ';'. " Fiege 16.5

*           AlbarÃ¡n (delivery note)
            body = body && |{ available-OutboundDelivery ALPHA = OUT }| && ';'. " 80000120

*           Bultos (number of packages)
            body = body && |{ outboundDelivery-UnloadingPointName ALPHA = OUT }| && ';'. " 1

*           Embalaje
            body = body && 'b;'.

*           Transportista
            body = body && 'Senator;'.

*           ExpediciĂłn
            body = body && '0'.

            body = body && cl_abap_char_utilities=>cr_lf.

        ENDLOOP.

*       Convert string To Xstring (binary)
        DATA(ev_csv) = cl_web_http_utility=>encode_utf8( body ).

        DATA(filename) = 'ECI' && '_' && <entity>-ShipmentID && '.CSV'.
        DATA(mimetype) = 'text/csv'.

*       Add a New Outbound
        APPEND VALUE #(
            %is_draft   = <entity>-%is_draft
            ShipmentUUID = <entity>-ShipmentUUID
            %target = VALUE #( (
                %is_draft       = <entity>-%is_draft
                %cid            = '1'
                ShipmentUUID    = <entity>-ShipmentUUID
                Attachment      = ev_csv
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
*    ENDLOOP.

  ENDMETHOD. " on_create

*  METHOD on_save_customer.
*  ENDMETHOD. " on_save_customer

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
                    %tky        = <entity>-%tky
                    PartyID     = partyID
                ) )
                MAPPED DATA(mapped1)
                FAILED DATA(failed1)
                REPORTED DATA(reported1).

        ENDIF.

        " Read the Customer
        SELECT SINGLE * FROM I_Customer WHERE ( Customer = @partyID ) INTO @DATA(ls_customer).

        IF ( sy-subrc = 0 ).

            " Read a Customer Sales Area (first met)
            SELECT SINGLE * FROM I_Customer\_CustomerSalesArea as CustomerSalesArea WHERE ( Customer = @partyID ) INTO @DATA(customerSalesArea).

            DATA(tx03) = get_texts_internal(
                EXPORTING
                    i_customer             = CONV string( ls_customer-Customer )
                    i_sales_organization   = CONV string( customerSalesArea-SalesOrganization )     " '1000'
                    i_distribution_channel = CONV string( customerSalesArea-DistributionChannel )   " '10'
                    i_division             = CONV string( customerSalesArea-Division )              " '00'
                    i_language             = 'EN'
                    i_long_text_id         = 'TX03'
            ).

            DATA(zfw1) = get_texts_internal(
                EXPORTING
                    i_customer             = CONV string( ls_customer-Customer )
                    i_sales_organization   = CONV string( customerSalesArea-SalesOrganization ) " '1000'
                    i_distribution_channel = CONV string( customerSalesArea-DistributionChannel )   " '10'
                    i_division             = CONV string( customerSalesArea-Division )              " '00'
                    i_language             = 'EN'
                    i_long_text_id         = 'ZFW1'
            ).

            DATA(zlvs) = get_texts_internal(
                EXPORTING
                    i_customer             = CONV string( ls_customer-Customer )
                    i_sales_organization   = CONV string( customerSalesArea-SalesOrganization )     " '1000'
                    i_distribution_channel = CONV string( customerSalesArea-DistributionChannel )   " '10'
                    i_division             = CONV string( customerSalesArea-Division )              " '00'
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

*       Link to Party
        DATA(partyURL) = |/ui#Customer-displayFactSheet?sap-ui-tech-hint=GUI&/C_CustomerOP('| && condense( val = |{ <entity>-PartyID ALPHA = OUT }| ) && |')|.

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
                PartyURL
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
                PartyURL                     = partyURL
            ) )
            MAPPED DATA(mapped2)
            FAILED DATA(failed2)
            REPORTED DATA(reported2).


    ENDLOOP.

  ENDMETHOD. " on_modify_customer

  METHOD on_modify_recipient.

    DATA importInvoiceRecipient TYPE zi_shipment_003-ImportInvoiceRecipient.

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

        importInvoiceRecipient = |{ <entity>-ImportInvoiceRecipient ALPHA = IN }|. " Add leading zeros

        IF ( importInvoiceRecipient <> <entity>-ImportInvoiceRecipient ).

            MODIFY ENTITIES OF zi_shipment_003 IN LOCAL MODE
                ENTITY Shipment
                UPDATE FIELDS (
                    ImportInvoiceRecipient
                )
                WITH VALUE #( (
                    %tky                    = <entity>-%tky
                    ImportInvoiceRecipient  = importInvoiceRecipient
                ) )
                MAPPED DATA(mapped1)
                FAILED DATA(failed1)
                REPORTED DATA(reported1).

        ENDIF.

        " Read the Customer
        SELECT SINGLE * FROM I_Customer WHERE ( Customer = @importInvoiceRecipient ) INTO @DATA(customer).

        IF ( sy-subrc = 0 ).
        ENDIF.

*       Link to Import Invoice Recipient
        DATA(importInvoiceRecipientURL) = |/ui#Customer-displayFactSheet?sap-ui-tech-hint=GUI&/C_CustomerOP('| && condense( val = |{ <entity>-importInvoiceRecipient ALPHA = OUT }| ) && |')|.

        MODIFY ENTITIES OF zi_shipment_003 IN LOCAL MODE
            ENTITY Shipment
            UPDATE FIELDS (
                ImportInvoiceRecipientURL
            )
            WITH VALUE #( (
                %is_draft                   = <entity>-%is_draft
                %key                        = <entity>-%key
                ImportInvoiceRecipientURL   = importInvoiceRecipientURL
            ) )
            MAPPED DATA(mapped2)
            FAILED DATA(failed2)
            REPORTED DATA(reported2).

    ENDLOOP.

  ENDMETHOD. " on_modify_recipient

  METHOD get_texts_internal.

* https://my404907.s4hana.cloud.sap/sap/opu/odata/sap/API_BUSINESS_PARTNER/A_CustomerSalesAreaText(Customer='GKK',SalesOrganization='1000',DistributionChannel='10',Division='00',Language='EN',LongTextID='ZFW1')

    TRY.

*  DATA(i_url) = 'https://my404898-api.s4hana.cloud.sap/sap/opu/odata/sap/API_BUSINESS_PARTNER/A_CustomerSalesAreaText(Customer=''10001722'',SalesOrganization=''1000'',DistributionChannel=''10'',Division=''00'',Language=''EN'',LongTextID=''ZLVS'')'.
        DATA(system_url)            = cl_abap_context_info=>get_system_url( ).
        DATA(customer)              = '''' && i_customer && ''','.
        DATA(salesOrganization)     = '''' && i_sales_organization && ''','.
        DATA(distributionChannel)   = '''' && i_distribution_channel && ''','.
        DATA(division)              = '''' && i_division && ''','.
        DATA(long_text_id)          = '''' && i_long_text_id && ''')'.
        CONCATENATE
                'https://'
                system_url(8) " my404898
                '-api.s4hana.cloud.sap/sap/opu/odata/sap/API_BUSINESS_PARTNER/A_CustomerSalesAreaText('
                'Customer='
                customer " '''10001722'','
                'SalesOrganization='
                salesOrganization " '''1000'','
                'DistributionChannel='
                distributionChannel " '''10'','
                'Division='
                division " '''00'','
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

  METHOD get_components_internal. " get components of material

    o_components = ''.

*   Item
    SELECT * FROM I_BillOfMaterialItemTP_2 WHERE ( Material = @i_product ) INTO TABLE @DATA(it_billofmaterialitem).

    IF ( sy-subrc = 0 ).
        LOOP AT it_billofmaterialitem INTO DATA(billofmaterialitem).
            DATA(componentDescription)          = billofmaterialitem-ComponentDescription.
            DATA(billOfMaterialItemQuantity)    = |{ billofmaterialitem-BillOfMaterialItemQuantity DECIMALS = 0 }|.
            DATA(billOfMaterialItemUnit)        = billofmaterialitem-BillOfMaterialItemUnit.
            CONCATENATE componentDescription billOfMaterialItemQuantity billOfMaterialItemUnit INTO DATA(component) SEPARATED BY space.
            IF ( o_components IS NOT INITIAL ).
                o_components = o_components && cl_abap_char_utilities=>cr_lf.
            ENDIF.
            o_components = o_components  && component.
        ENDLOOP.
    ENDIF.

  ENDMETHOD. " get_components_internal

  METHOD split_string_internal. " Split string into fix length substrings

    DATA input  TYPE string.
    DATA output TYPE string.
    DATA fix    TYPE I.

    input   = i_str.
    output  = ''.
    fix     = 50.

    IF ( i_len IS SUPPLIED ).
        IF ( i_len > 0 ).
            fix = i_len.
        ENDIF.
    ENDIF.

*   Split by LEN
    DATA l TYPE I.      " total length
    DATA p TYPE I.      " starting position
    DATA s TYPE string. " substring C(50)

    l = STRLEN( input ).
    DO 10000 TIMES.
        IF      ( ( p + fix ) < l ).
            s = input+p(fix).
        ELSEIF  ( ( p + 0  ) < l ).
            s = input+p.
        ELSE.
            EXIT.
        ENDIF.
        output = output && s && cl_abap_char_utilities=>cr_lf.
        p = p + 50.
    ENDDO.

  ENDMETHOD. " split_string_internal

  METHOD get_commodity_code_internal. " Get Commodity Code/Description By Code (output Code is for checking)

*   Hard Code:
    o_description   = ''.
    CASE i_code.
        WHEN '33043000'.  o_description = 'Manicure or pedicure preparations'.
        WHEN '34022090'.  o_description = 'Washing preparations, incl. auxiliary washing preparations and cleaning preparations put up for retail sale (excl. organic surface-active agents, soap and surface-active preparations, and products and prepa' &&
                                          'rations for washing the skin in the form of liquid or cream)'.
        WHEN '34060000'.  o_description = 'Candles, tapers and the like'.
        WHEN '39199080'.  o_description = 'Self-adhesive plates, sheets, film, foil, tape, strip and other flat shapes, of plastics, in rolls <= 20 cm wide (excl. plastic strips coated with unvulcanised natural or synthetic rubber)'.
        WHEN '39205990'.  o_description = 'Plates, sheets, foil, film and strip of non-cellular acrylic polymers, not reinforced, coated, laminated or similarly combined with other materials, without backing, unworked or merely surface-worked or mer' &&
                                          'ely cut into squares or rectangles (excl. those of polymethyl methacrylate, self-adhesive products and floor, wall and ceiling coverings of heading 3918, and copolymer of acrylic and methacrylic esters in t' &&
                                          'he form of film of a thickness of <= 150 micrometres)'.
        WHEN '39232100'.  o_description = 'Sacks and bags, incl. cones, of polymers of ethylene'.
        WHEN '39234090'.  o_description = 'Spools, cops, bobbins and similar supports, of plastics (excl. those for photographic and cinematographic film or for tapes, films and the like, for sound or video recordings or the recording of signals, da' &&
                                          'ta or programmes)'.
        WHEN '39239000'.  o_description = 'Articles for the conveyance or packaging of goods, of plastics (excl. boxes, cases, crates and similar articles; sacks and bags, incl. cones; carboys, bottles, flasks and similar articles; spools, spindles' &&
                                          ', bobbins and similar supports; stoppers, lids, caps and other closures)'.
        WHEN '39269097'.  o_description = 'Articles of plastics and articles of other materials of heading 3901 to 3914, n.e.s.'.
        WHEN '44201900'.  o_description = 'Statuettes and other ornaments, of wood (excl. okoumé, obeche, sapelli, sipo, acajou d''Afrique, makoré, iroko, tiama, mansonia, ilomba, dibétou, limba, azobé, dark red meranti, light red meranti, meranti b' &&
                                          'akau, white lauan, white meranti, white seraya, yellow meranti, alan, keruing, ramin, kapur, teak, jongkong, merbau, jelutong, kempas, virola, mahogany [Swietenia spp.], imbuia, balsa, palissandre de Rio, p' &&
                                          'alissandre du Brésil and palissandre de Rose; wood marquetry and inlaid wood)'.
        WHEN '48114120'.  o_description = 'Self-adhesive paper and paperboard, surface-coloured, surface-decorated or printed, in strips, rolls or sheets of a width of <= 10 cm, coated with unvulcanised natural or synthetic rubber'.
        WHEN '48191000'.  o_description = 'Cartons, boxes and cases, of corrugated paper or paperboard'.
        WHEN '48193000'.  o_description = 'Sacks and bags, of paper, paperboard, cellulose wadding or webs of cellulose fibres, having a base of a width of >= 40 cm'.
        WHEN '48196000'.  o_description = 'Box files, letter trays, storage boxes and similar articles, of paperboard, of a kind used in offices, shops or the like (excl. packing containers)'.
        WHEN '48201090'.  o_description = 'Writing pads and the like, of paper or paperboard'.
        WHEN '48211090'.  o_description = 'Paper or paperboard labels of all kinds, printed (excl. self-adhesive)'.
        WHEN '48219010'.  o_description = 'Self-adhesive paper or paperboard labels of all kinds, non-printed'.
        WHEN '49111010'.  o_description = 'Printed catalogs, price lists or trade notices, relating to offers, by a person whose principal place of business or bonafide residence is in a foreign country, to sell or rent products of a foreign country'.
        WHEN '49111090'.  o_description = 'Other printed trade advertising material, posters and the like'.
        WHEN '49119100'.  o_description = 'Pictures, prints and photographs, n.e.s.'.
        WHEN '61044300'.  o_description = 'Women''s or girls'' dresses of synthetic fibres, knitted or crocheted (excl. petticoats)'.
        WHEN '61081100'.  o_description = 'Women''s or girls'' slips and petticoats of man-made fibres, knitted or crocheted (excl. T-shirts and vests)'.
        WHEN '61082200'.  o_description = 'Women''s or girls'' briefs and panties'.
        WHEN '61083100'.  o_description = 'Women''s or girls'' nightdresses and pyjamas of cotton, knitted or crocheted (excl. T-shirts, vests and négligés)'.
        WHEN '61083200'.  o_description = 'Women''s or girls'' nightdresses and pyjamas of man-made fibres, knitted or crocheted (excl. T-shirts, vests and négligés)'.
        WHEN '61089200'.  o_description = 'Women''s or girls'' négligés, bathrobes, dressing gowns, housejackets and similar articles of man-made fibres, knitted or crocheted (excl. vests, slips, petticoats, briefs and panties, nightdresses, pyjamas' &&
                                          ', brassiéres, girdles, corsets and similar articles)'.
        WHEN '61091000'.  o_description = 'T-shirts, singlets and other vests of cotton, knitted or crocheted'.
        WHEN '61099020'.  o_description = 'T-shirts, singlets and other vests of wool or fine animal hair or man-made fibres, knitted or crocheted'.
        WHEN '61099090'.  o_description = 'T-shirts, singlets and other vests of textile materials, knitted or crocheted (excl. of wool, fine animal hair, cotton or man-made fibres)'.
        WHEN '61124190'.  o_description = 'Women''s or girls'' swimwear of synthetic fibres, knitted or crocheted (excl. containing >= 5% by weight of rubber thread)'.
        WHEN '61143000'.  o_description = 'Special garments for professional, sporting or other purposes, n.e.s., of man-made fibres, knitted or crocheted'.
        WHEN '62044200'.  o_description = 'Women''s or girls'' dresses of cotton (excl. knitted or crocheted and petticoats)'.
        WHEN '62121090'.  o_description = 'Brassieres for ladies'.
        WHEN '62122000'.  o_description = 'Girdles and panty girdles'.
        WHEN '62123000'.  o_description = 'Corsets of man-made fibers'.
        WHEN '62129000'.  o_description = 'Corsets, braces, garters, suspenders and similar articles and parts thereof, incl. parts of brassieres, girdles, panty girdles and corselettes, of all types of textile materials, whether or not elasticated' &&
                                          ', incl. knitted or crocheted (excl. complete brassieres, girdles, panty girdles and corselettes)'.
        WHEN '62143000'.  o_description = 'Shawls, scarves, mufflers, mantillas, veils and similar articles of synthetic fibres (excl. knitted or crocheted)'.
        WHEN '62149000'.  o_description = 'Shawls, scarves, mufflers, mantillas, veils and similar articles of textile materials (excl. of silk, silk waste, wool, fine animal hair or man-made fibres, knitted or crocheted)'.
        WHEN '63029390'.  o_description = 'Toilet linen and kitchen linen of man-made fibres (excl. nonwovens, floorcloths, polishing cloths, dishcloths and dusters)'.
        WHEN '63059000'.  o_description = 'Sacks and bags, for the packing of goods, of textile materials (excl. man-made, cotton, jute or other textile bast fibres of heading 5303)'.
        WHEN '63079098'.  o_description = 'Made-up articles of textile materials, incl. dress patterns, n.e.s. (excl. of felt, knitted or crocheted, single-use drapes used during surgical procedures made up of nonwovens, and protective face masks)'.
        WHEN '90178010'.  o_description = 'Measuring rods and tapes and divided scales'.
        WHEN '94032080'.  o_description = 'Metal furniture (excl. for offices, medical, surgical, dental or veterinary furniture, beds and seats)'.
        WHEN '94036030'.  o_description = 'Wooden furniture for shops (excl. seats)'.
    ENDCASE.
    o_code = i_code.
    RETURN.

*   ...till better times:
    DATA system_url TYPE string.

    DATA i_username TYPE string VALUE 'INBOUND_USER'.
    DATA i_password TYPE string VALUE 'rtrVDDgelabtTjUiybRX}tVD3JksqqfvPpBdJRaL'.

    DATA text   TYPE string.
    DATA s1     TYPE string.
    DATA s2     TYPE string.
    DATA s3     TYPE string.

    TRY.

* DATA(i_url) = 'https://my404898.s4hana.cloud.sap/sap/opu/odata/sap/YY1_COMMODITYCODE_CDS/YY1_COMMODITYCODE'.

        system_url = cl_abap_context_info=>get_system_url( ).

*       Read list of objects and get UUID of the first
        CONCATENATE
                'https://'
                system_url(8) " my404898
                '-api.s4hana.cloud.sap/sap/opu/odata/sap/YY1_COMMODITYCODE_CDS/YY1_COMMODITYCODE'
            INTO DATA(i_url).

        DATA(http_destination) = cl_http_destination_provider=>create_by_url( i_url = i_url ).

        DATA(lo_http_client) = cl_web_http_client_manager=>create_by_http_destination( http_destination ).

        lo_http_client->get_http_request( )->set_authorization_basic(
            i_username = i_username
            i_password = i_password
        ).

        DATA(lo_http_request) = lo_http_client->get_http_request( ).

        DATA(lo_http_response) = lo_http_client->execute(
            i_method   = if_web_http_client=>get
        ).

        text                          = lo_http_response->get_text( ).
        DATA(status)                  = lo_http_response->get_status( ).
        DATA(response_header_fields)  = lo_http_response->get_header_fields( ).

        REPLACE '<d:SAP_UUID>'    IN text WITH '******'.
        REPLACE '</d:SAP_UUID>'   IN text WITH '******'.
        SPLIT text AT '******' INTO s1 s2 s3.

        DATA(sap_uuid) = s2.

        CONCATENATE
                'https://'
                system_url(8) " my404898
                '-api.s4hana.cloud.sap/sap/opu/odata/sap/YY1_COMMODITYCODE_CDS/YY1_COMMODITYCODE'
                '(guid''' sap_uuid ''')' " '91bf6b38-1c0f-1ede-b2cf-0d3f0b77f0ff'
            INTO i_url.

        http_destination = cl_http_destination_provider=>create_by_url( i_url = i_url ).

        lo_http_client = cl_web_http_client_manager=>create_by_http_destination( http_destination ).

        lo_http_client->get_http_request( )->set_authorization_basic(
            i_username = i_username
            i_password = i_password
        ).

        lo_http_request = lo_http_client->get_http_request( ).

*       Get Token:

        lo_http_request->set_header_field(
            i_name  = 'x-csrf-token'
            i_value = 'fetch'
        ).

        lo_http_response = lo_http_client->execute(
            i_method   = if_web_http_client=>get
        ).

        text                   = lo_http_response->get_text( ).
        status                 = lo_http_response->get_status( ).
        response_header_fields = lo_http_response->get_header_fields( ).

*        DATA token TYPE string.
        READ TABLE response_header_fields WITH KEY name = 'x-csrf-token' INTO DATA(field).
        IF ( sy-subrc = 0 ).
            DATA(token) = field-value.
        ENDIF.

*       Update Code:

        DATA i_fields TYPE if_web_http_request=>name_value_pairs.
        APPEND VALUE #(
            name  = 'x-csrf-token'
            value = token " '5iGZK1qT45Vi4UfHYazbPQ=='
        )
        TO i_fields.
        APPEND VALUE #(
            name  = 'Content-Type'
            value = 'application/json'
        )
        TO i_fields.

        lo_http_request->set_header_fields(
          EXPORTING
            i_fields = i_fields
        ).

        lo_http_request->set_text(
            i_text   = '{"CODE":"' && i_code && '"}' " '62149000'
        ).

        lo_http_response = lo_http_client->execute(
            i_method   = if_web_http_client=>put
        ).

        text                      = lo_http_response->get_text( ).
        status                    = lo_http_response->get_status( ).
        response_header_fields    = lo_http_response->get_header_fields( ).

*       Read Description

        lo_http_response = lo_http_client->execute(
            i_method   = if_web_http_client=>get
        ).

        text                    = lo_http_response->get_text( ).
        status                  = lo_http_response->get_status( ).
        response_header_fields  = lo_http_response->get_header_fields( ).

        REPLACE '<d:CODE>'    IN text WITH '***CODE***'.
        REPLACE '</d:CODE>'   IN text WITH '***CODE***'.
        SPLIT text AT '***CODE***' INTO s1 s2 s3.
        o_code = s2.

        REPLACE '<d:DESCRIPTION>'    IN text WITH '***DESCRIPTION***'.
        REPLACE '</d:DESCRIPTION>'   IN text WITH '***DESCRIPTION***'.
        SPLIT text AT '***DESCRIPTION***' INTO s1 s2 s3.
        o_description = s2.

    CATCH cx_web_message_error INTO DATA(lx_web_message_error).
      " Handle Exception
*      RAISE SHORTDUMP lx_web_message_error.

    CATCH cx_abap_context_info_error INTO DATA(lx_abap_context_info_error).
      " Handle Exception
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

  ENDMETHOD. " get_commodity_code_internal

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

*           Link to Outbound Delivery
            DATA(outboundDeliveryURL) = |/ui#OutboundDelivery-displayFactSheet?sap-app-origin-hint=&/C_OutboundDeliveryFs('| && condense( val = |{ <entity>-OutboundDelivery ALPHA = OUT }| ) && |')|. " '80000000'

            MODIFY ENTITIES OF zi_shipment_003 IN LOCAL MODE
                ENTITY Available
                UPDATE FIELDS (
                    OutboundDelivery
                    OutboundDeliveryURL
                )
                WITH VALUE #( (
                    %tky                = <entity>-%tky
                    OutboundDelivery    = outboundDelivery
                    OutboundDeliveryURL = outboundDeliveryURL
                ) )
                MAPPED DATA(mapped1)
                FAILED DATA(failed1)
                REPORTED DATA(reported1).

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
