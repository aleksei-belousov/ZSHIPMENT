CLASS lhc_repository DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR repository RESULT result.

    METHODS make_pdf FOR MODIFY
      IMPORTING keys FOR ACTION repository~make_pdf.

    METHODS on_create FOR DETERMINE ON MODIFY
      IMPORTING keys FOR repository~on_create.

ENDCLASS.

CLASS lhc_repository IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD make_pdf.
  ENDMETHOD.

  METHOD on_create.
  ENDMETHOD.

ENDCLASS.
