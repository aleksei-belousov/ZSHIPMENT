CLASS lhc_excluded DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION IMPORTING keys REQUEST requested_authorizations FOR excluded RESULT result.
    METHODS on_create FOR DETERMINE ON MODIFY IMPORTING keys FOR excluded~on_create.
    METHODS on_modify_delivery FOR DETERMINE ON MODIFY IMPORTING keys FOR excluded~on_modify_delivery.

ENDCLASS. " lhc_excluded DEFINITION

CLASS lhc_excluded IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD on_create.

     " Read transfered instances
    READ ENTITIES OF zi_excluded_003 IN LOCAL MODE
        ENTITY Excluded
        ALL FIELDS
        WITH CORRESPONDING #( keys )
        RESULT DATA(entities).

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).

        IF ( <entity>-%is_draft = '00' ). " Saved
        ENDIF.
        IF ( <entity>-%is_draft = '01' ). " Draft
        ENDIF.

    ENDLOOP.

  ENDMETHOD. " on_create

  METHOD on_modify_delivery.

    DATA outboundDelivery TYPE zi_excluded_003-OutboundDelivery.

     " Read transfered instances
    READ ENTITIES OF zi_excluded_003 IN LOCAL MODE
        ENTITY Excluded
        ALL FIELDS
        WITH CORRESPONDING #( keys )
        RESULT DATA(entities).

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).

        outboundDelivery = |{ <entity>-OutboundDelivery ALPHA = IN }|. " Add leading zeros

        DATA referenceSDDocument        TYPE I_SalesOrder-SalesOrder.
        DATA purchaseOrderByCustomer    TYPE I_SalesOrder-PurchaseOrderByCustomer.
        SELECT SINGLE * FROM I_OutboundDeliveryItem WHERE ( OutboundDelivery = @outboundDelivery ) INTO @DATA(outboundDeliveryItem).
        IF ( sy-subrc = 0 ).
            referenceSDDocument = outboundDeliveryItem-ReferenceSDDocument.
            SELECT SINGLE * FROM I_SalesOrder WHERE ( SalesOrder = @referenceSDDocument ) INTO @DATA(salesOrder).
            IF ( sy-subrc = 0 ).
                purchaseOrderByCustomer = salesOrder-PurchaseOrderByCustomer.
            ENDIF.
        ENDIF.

*       Prevent endless cycling and to fill URL
        IF ( ( outboundDelivery <> <entity>-OutboundDelivery ) OR ( <entity>-OutboundDeliveryURL IS INITIAL ) OR ( referenceSDDocument <> <entity>-SalesOrder ) OR ( <entity>-SalesOrderURL IS INITIAL ) ).

*           Link to Outbound Delivery>: https://my404898.s4hana.cloud.sap/ui#OutboundDelivery-displayFactSheet?sap-app-origin-hint=&/C_OutboundDeliveryFs('80000012')
            DATA(outboundDeliveryURL) = |/ui#OutboundDelivery-displayFactSheet?sap-app-origin-hint=&/C_OutboundDeliveryFs('| && condense( val = |{ outboundDelivery ALPHA = OUT }| ) && |')|. " '80000012'
*           Link to Sales Order: https://my404898.s4hana.cloud.sap/ui#SalesOrder-manageV2&/SalesOrderManage('19')
            DATA(salesOrderURL) = |/ui#SalesOrder-manageV2&/SalesOrderManage('| && condense( val = |{ referenceSDDocument ALPHA = OUT }| ) && |')|. " '19'

            MODIFY ENTITIES OF zi_excluded_003 IN LOCAL MODE
                ENTITY Excluded
                UPDATE FIELDS (
                    OutboundDelivery
                    SalesOrder
                    PurchaseOrderByCustomer
                    OutboundDeliveryURL
                    SalesOrderURL
                )
                WITH VALUE #( (
                    %tky                    = <entity>-%tky
                    OutboundDelivery        = outboundDelivery
                    SalesOrder              = referenceSDDocument
                    PurchaseOrderByCustomer = purchaseOrderByCustomer
                    OutboundDeliveryURL     = outboundDeliveryURL
                    SalesOrderURL           = salesOrderURL
                ) )
                MAPPED DATA(mapped1)
                FAILED DATA(failed1)
                REPORTED DATA(reported1).

        ENDIF.

    ENDLOOP.

  ENDMETHOD. " on_modify_delivery

ENDCLASS. " lhc_excluded IMPLEMENTATION.
