CLASS zcl_rap_shipment_003_test DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.

    DATA i_url         TYPE string. " VALUE 'https://my404930.s4hana.cloud.sap'.
    DATA i_username    TYPE string. " VALUE 'INBOUND_USER'.
    DATA i_password    TYPE string. " VALUE 'rtrVDDgelabtTjUiybRX}tVD3JksqqfvPpBdJRaL'.

    METHODS read_list.
    METHODS read_shipment.
    METHODS create_shipment.
    METHODS delete_shipment.
    METHODS update_shipment.

ENDCLASS. " zcl_rap_shipment_003_test DEFINITION

CLASS zcl_rap_shipment_003_test IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.

    TRY.
        i_url       = 'https://' && cl_abap_context_info=>get_system_url( ).
        i_username  = 'INBOUND_USER'.
        i_password  = 'rtrVDDgelabtTjUiybRX}tVD3JksqqfvPpBdJRaL'.
    CATCH cx_abap_context_info_error INTO DATA(lx_abap_context_info_error).
        "handle exception
    ENDTRY.

*    read_list( ).
*    read_shipment( ).
*    create_shipment( ).
*    delete_shipment( ).
    update_shipment( ).

  ENDMETHOD. " if_oo_adt_classrun~main

  METHOD read_list.

    DATA lt_business_data TYPE TABLE OF zrap_zc_shipment_003.
    DATA lo_http_client   TYPE REF TO if_web_http_client.
    DATA lo_client_proxy  TYPE REF TO /iwbep/if_cp_client_proxy.
    DATA lo_request       TYPE REF TO /iwbep/if_cp_request_read_list.
    DATA lo_response      TYPE REF TO /iwbep/if_cp_response_read_lst.

    TRY.

        DATA(http_destination) = cl_http_destination_provider=>create_by_url( i_url = i_url ).

        lo_http_client = cl_web_http_client_manager=>create_by_http_destination( i_destination = http_destination ).

        lo_http_client->accept_cookies( i_allow = abap_true ).

        lo_http_client->get_http_request( )->set_authorization_basic( i_username = i_username i_password = i_password ).

        lo_client_proxy = cl_web_odata_client_factory=>create_v2_remote_proxy(
             EXPORTING
*                iv_do_fetch_csrf_token      = abap_true
                iv_service_definition_name  = 'ZSC_SHIPMENT_003'
                io_http_client              = lo_http_client
                iv_relative_service_root    = '/sap/opu/odata/sap/ZSB_SHIPMENT_003_ODATA/' ).

        " Navigate to the resource and create a request for the read operation
        lo_request = lo_client_proxy->create_resource_for_entity_set( 'ZC_SHIPMENT_003' )->create_request_for_read( ).

        lo_request->set_top( 50 )->set_skip( 0 ).

        " Execute the request and retrieve the business data
        lo_response = lo_request->execute( ).

        lo_response->get_business_data( IMPORTING et_business_data = lt_business_data ).

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

  ENDMETHOD. " read_list

  METHOD read_shipment.
  ENDMETHOD. " read_shipment

  METHOD create_shipment.
  ENDMETHOD. " create_shipment

  METHOD delete_shipment.
  ENDMETHOD. " delete_shipment

  METHOD update_shipment.

    DATA ls_key_data        TYPE zrap_zc_shipment_003.
    DATA ls_business_data   TYPE zrap_zc_shipment_003.
    DATA lo_client_proxy    TYPE REF TO /iwbep/if_cp_client_proxy.
    DATA lo_request1        TYPE REF TO /iwbep/if_cp_request_read.
    DATA lo_response1       TYPE REF TO /iwbep/if_cp_response_read.
    DATA lo_request2        TYPE REF TO /iwbep/if_cp_request_update.
    DATA lo_response2       TYPE REF TO /iwbep/if_cp_response_update.
    DATA lo_http_client     TYPE REF TO if_web_http_client.

    TRY.

        DATA(http_destination) = cl_http_destination_provider=>create_by_url( i_url = i_url ).

        lo_http_client = cl_web_http_client_manager=>create_by_http_destination( i_destination = http_destination ).

        lo_http_client->accept_cookies( i_allow = abap_true ).

        lo_http_client->get_http_request( )->set_authorization_basic( i_username = i_username i_password = i_password ).

        lo_client_proxy = cl_web_odata_client_factory=>create_v2_remote_proxy(
*                iv_do_fetch_csrf_token      = abap_true
                iv_service_definition_name  = 'ZSC_SHIPMENT_003'
                io_http_client              = lo_http_client
                iv_relative_service_root    = '/sap/opu/odata/sap/ZSB_SHIPMENT_003_ODATA/'
        ).

*       Prepare key data (matrix)
        ls_key_data = VALUE #(
*            ShipmentUUID                    = '775FF137FDF71EDEA2C0CBCAB96C0FC3' " ID = 1 (dev-dev)
            ShipmentUUID                    = '1342473CC1B41EDEA0DEE5AABBA04FAD' " ID = 2 (dev-cust)

            IsActiveEntity                  = abap_true
        ).

        " Navigate to the resource
        lo_request1 = lo_client_proxy->create_resource_for_entity_set( 'ZC_SHIPMENT_003' )->navigate_with_key( ls_key_data )->create_request_for_read( ).

        " Execute the request and retrieve the business data
        lo_response1 = lo_request1->execute( ).

        " Get business data
        lo_response1->get_business_data( IMPORTING es_business_data = ls_business_data ).


        ls_business_data-ConfirmationDate  = 20231122000000.

        " Navigate to the resource
        lo_request2 = lo_client_proxy->create_resource_for_entity_set( 'ZC_SHIPMENT_003' )->navigate_with_key( ls_key_data )->create_request_for_update( /iwbep/if_cp_request_update=>gcs_update_semantic-put ).

        " Set the business data for the created entity
        lo_request2->set_business_data( ls_business_data ).

        " Execute the request (Update)
        lo_response2 = lo_request2->execute( ).

        " Get the after image
*        lo_response2->get_business_data( IMPORTING es_business_data = ls_business_data ).

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


  ENDMETHOD. " delete_shipment

ENDCLASS. " zcl_rap_shipment_003_test IMPLEMENTATION
