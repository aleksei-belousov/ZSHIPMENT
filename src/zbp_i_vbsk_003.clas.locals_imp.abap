CLASS lhc_CollectiveProcessing DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR CollectiveProcessing RESULT result.

    METHODS Activate FOR MODIFY
      IMPORTING keys FOR ACTION CollectiveProcessing~Activate.

    METHODS Edit FOR MODIFY
      IMPORTING keys FOR ACTION CollectiveProcessing~Edit.

    METHODS Resume FOR MODIFY
      IMPORTING keys FOR ACTION CollectiveProcessing~Resume.

ENDCLASS.

CLASS lhc_CollectiveProcessing IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD Activate.
  ENDMETHOD.

  METHOD Edit.
  ENDMETHOD.

  METHOD Resume.
  ENDMETHOD.

ENDCLASS.

CLASS lsc_ZI_VBSK_003 DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_ZI_VBSK_003 IMPLEMENTATION.

  METHOD save_modified.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
