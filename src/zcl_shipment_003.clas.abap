CLASS zcl_shipment_003 DEFINITION PUBLIC FINAL CREATE PUBLIC .
  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.

  PRIVATE SECTION.
    DATA i_url         TYPE string VALUE 'https://felina-hu-scpi-test-eyjk96r2.it-cpi018-rt.cfapps.eu10-003.hana.ondemand.com/http/FiegeShipmentBindingRequest'.
    DATA i_username    TYPE string VALUE 'sb-1e950f89-c676-4acd-b0dc-24e58f8aab45!b143168|it-rt-felina-hu-scpi-test-eyjk96r2!b117912'.
    DATA i_password    TYPE string VALUE 'cc744b1f-5237-4a7e-ab44-858fdd00fb73$3wcTQpYfe1kbmjltnA8zSDb5ogj0TpaYon4WHM-TwfE='.

    METHODS http_call               importing out type ref to if_oo_adt_classrun_out.
    METHODS pdf_test                importing out type ref to if_oo_adt_classrun_out.
    METHODS business_object_access  importing out type ref to if_oo_adt_classrun_out.

ENDCLASS.

CLASS zcl_shipment_003 IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.

*    http_call( out ).
    business_object_access( out ).
  ENDMETHOD. " if_oo_adt_classrun~main

  METHOD http_call.

    TRY.

        DATA(http_destination) = cl_http_destination_provider=>create_by_url( i_url = i_url ).

        DATA(lo_http_client) = cl_web_http_client_manager=>create_by_http_destination( i_destination = http_destination ).

*        lo_http_client->accept_cookies( i_allow = abap_true ).

        lo_http_client->get_http_request( )->set_authorization_basic(
            i_username = i_username
            i_password = i_password
        ).

        lo_http_client->get_http_request( )->set_text( 'Hello, CPI!' ).

        DATA(lo_http_response) = lo_http_client->execute(
            i_method   = if_web_http_client=>get
*            i_timeout  = 0
        ).

        DATA(text) = lo_http_response->get_text( ).

        DATA(status) = lo_http_response->get_status( ).

        DATA(header_fields) = lo_http_response->get_header_fields( ).

        DATA(header_status) = lo_http_response->get_header_field( '~status_code' ).

        out->write( text )->write( status )->write( header_status ).

        " Whole Header
        out->write( cl_abap_char_utilities=>cr_lf && 'Whole Header:' && cl_abap_char_utilities=>cr_lf ).
        LOOP AT header_fields INTO DATA(header_field).
            out->write( cl_abap_char_utilities=>cr_lf ).
            out->write( header_field ).
        ENDLOOP.

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

  ENDMETHOD. " http_call

  METHOD pdf_test.

    DATA lv_xml_data        TYPE xstring.
    DATA lv_xdp             TYPE xstring.
    DATA ls_options         TYPE cl_fp_ads_util=>ty_gs_options_pdf.
    DATA ev_pdf             TYPE xstring.
    DATA ev_pages           TYPE int4.
    DATA ev_trace_string    TYPE string.

    TRY.

*       Render PDF
        cl_fp_ads_util=>render_pdf( EXPORTING iv_xml_data      = lv_xml_data
                                              iv_xdp_layout    = lv_xdp
                                              iv_locale        = 'de_DE'
                                              is_options       = ls_options
                                    IMPORTING ev_pdf           = ev_pdf
                                              ev_pages         = ev_pages
                                              ev_trace_string  = ev_trace_string
        ).

      CATCH cx_fp_ads_util INTO DATA(lx_fp_ads_util).

    ENDTRY.

  ENDMETHOD. " pdf_test

  METHOD business_object_access.

    TRY.

        i_url       = 'https://my404898-api.s4hana.cloud.sap/sap/opu/odata/sap/API_BUSINESS_PARTNER/A_CustomerSalesAreaText(Customer=''10001722'',SalesOrganization=''1000'',DistributionChannel=''10'',Division=''00'',Language=''EN'',LongTextID=''ZLVS'')'.
        i_username  = 'INBOUND_USER'.
        i_password  = 'rtrVDDgelabtTjUiybRX}tVD3JksqqfvPpBdJRaL'.

        DATA(http_destination) = cl_http_destination_provider=>create_by_url( i_url ).

        DATA(lo_http_client) = cl_web_http_client_manager=>create_by_http_destination( http_destination ).

        lo_http_client->get_http_request( )->set_authorization_basic(
            i_username = i_username
            i_password = i_password
        ).

        DATA(lo_http_response) = lo_http_client->execute(
            i_method   = if_web_http_client=>get
*            i_timeout  = 0
        ).

        DATA(text) = lo_http_response->get_text( ).

        DATA(status) = lo_http_response->get_status( ).

        out->write( text )->write( status ).


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

  ENDMETHOD. " business_object_access

ENDCLASS.
