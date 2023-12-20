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

    METHODS retrieve FOR MODIFY
      IMPORTING keys FOR ACTION Shipment~retrieve.

    METHODS release FOR MODIFY
      IMPORTING keys FOR ACTION Shipment~release.

    METHODS on_create FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Shipment~on_create.

    METHODS on_save_customer FOR DETERMINE ON SAVE
      IMPORTING keys FOR Shipment~on_save_customer.
    METHODS on_modify_customer FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Shipment~on_modify_customer.
    METHODS create_tariff_document FOR MODIFY
      IMPORTING keys FOR ACTION Shipment~create_tariff_document.

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
  ENDMETHOD.

  METHOD Resume.
  ENDMETHOD.

* Retrieve Outbound Delivery
  METHOD retrieve.

    DATA it_available_create TYPE TABLE FOR CREATE zi_shipment_003\_Available.

*   read transfered instances
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

*       Read Available Table
        READ ENTITIES OF zi_shipment_003 IN LOCAL MODE
            ENTITY Shipment
            BY \_Available
            ALL FIELDS WITH VALUE #( (
                %tky = <entity>-%tky
            ) )
            RESULT DATA(lt_available)
            FAILED DATA(failed1)
            REPORTED DATA(reported1).

*       Delete Actual Size Table
        LOOP AT lt_available INTO DATA(ls_available).
            MODIFY ENTITIES OF zi_shipment_003 IN LOCAL MODE
                ENTITY Available
                DELETE FROM VALUE #( ( %tky = ls_available-%tky ) )
                MAPPED DATA(mapped2)
                FAILED DATA(failed2)
                REPORTED DATA(reported2).
        ENDLOOP.

        DATA(collective_processing) = <entity>-CollectiveProcessing. " '1'

*       Read Collective Processing (header) (via SQL)
        SELECT SINGLE * FROM zi_vbsk_003 WHERE ( CollectiveProcessing = @collective_processing ) INTO @DATA(ls_collective_processing).

*       Read Collective Processing Document (items) (via CDS)
        READ ENTITIES OF zi_vbsk_003
            ENTITY CollectiveProcessing BY \_CollectiveProcessingDocument
            ALL FIELDS WITH VALUE #( (
*                %is_draft = <entity>-%is_draft
                ZvbskUUID = ls_collective_processing-ZvbskUUID
            ) )
            RESULT DATA(lt_document)
            FAILED DATA(failed3)
            REPORTED DATA(reported3).

        SORT lt_document STABLE BY CollectiveProcessingDocument.

        LOOP AT lt_document INTO DATA(ls_document).
            APPEND VALUE #(
                %is_draft           = <entity>-%is_draft
                ShipmentUUID        = <entity>-ShipmentUUID
                %target = VALUE #( (
                    %is_draft           = <entity>-%is_draft
                    ShipmentUUID        = <entity>-ShipmentUUID
                    OutboundDelivery    = ls_document-CollectiveProcessingDocument
                ) )
            ) TO it_available_create.
        ENDLOOP.

*       Create Available Rows
        MODIFY ENTITIES OF zi_shipment_003 IN LOCAL MODE
            ENTITY Shipment CREATE BY \_Available
            AUTO FILL CID FIELDS (
*                AvailableUUID
                ShipmentUUID
                OutboundDelivery
            )
            WITH it_available_create
            MAPPED DATA(mapped4)
            FAILED DATA(failed4)
            REPORTED DATA(reporeted4).

    ENDLOOP.

  ENDMETHOD. " retrieve

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

            READ ENTITIES OF zi_shipment_003 IN LOCAL MODE
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

            DATA request_body TYPE string VALUE ''.

*           Make body as an XML
            request_body = request_body && '<ShipmentBinding>' && cl_abap_char_utilities=>cr_lf.
            request_body = request_body && '<ID>' && <entity>-ShipmentID && '</ID>' && cl_abap_char_utilities=>cr_lf.
            request_body = request_body && '<ConfirmationDate>' && <entity>-ConfirmationDate && '</ConfirmationDate>' && cl_abap_char_utilities=>cr_lf.
            request_body = request_body && '<Tour>' && <entity>-Tour && '</Tour>' && cl_abap_char_utilities=>cr_lf.
            request_body = request_body && '<TransportationType>' && <entity>-TransportationType && '</TransportationType>' && cl_abap_char_utilities=>cr_lf.
            request_body = request_body && '<FreightForwarderClient>' && <entity>-FreightForwarderClient && '</FreightForwarderClient>' && cl_abap_char_utilities=>cr_lf.
            request_body = request_body && '<PartyID>' && <entity>-PartyID && '</PartyID>' && cl_abap_char_utilities=>cr_lf.
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
                DATA(outboundDelivery) = |{ ls_available-OutboundDelivery ALPHA = IN }|.
                request_body = request_body && '<OutboundDelivery>' && cl_abap_char_utilities=>cr_lf.
                request_body = request_body && '<ID>' && outboundDelivery && '</ID>' && cl_abap_char_utilities=>cr_lf.
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

**    Illegal Statement
*    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'.

  ENDMETHOD. " release

  METHOD create_tariff_document.

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

  ENDMETHOD. " create_tariff_document

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
*                ShipmentID  = shipmentid
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

        DATA(partyID) = |{ <entity>-PartyID ALPHA = IN }|.

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
            MAPPED DATA(mapped1)
            FAILED DATA(failed1)
            REPORTED DATA(reported1).


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
