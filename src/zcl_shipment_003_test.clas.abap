CLASS zcl_shipment_003_test DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.

CLASS zcl_shipment_003_test IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.

*    SELECT
*       \_COMMODITYCODETEXT-TRDCLASSFCTNNMBRSCHMCNTNT AS TRDCLASSFCTNNMBRSCHMCNTNT ,
*       \_COMMODITYCODETEXT-TRDCLASSFCTNNMBR AS TRDCLASSFCTNNMBR ,
*       \_COMMODITYCODETEXT-VALIDITYSTARTDATE AS VALIDITYSTARTDATE ,
*       \_COMMODITYCODETEXT-TRDCLASSFCTNNMBRTEXTTYPE AS TRDCLASSFCTNNMBRTEXTTYPE ,
*       \_COMMODITYCODETEXT-LANGUAGE AS LANGUAGE ,
*       \_COMMODITYCODETEXT-VALIDITYENDDATE AS VALIDITYENDDATE ,
*       \_COMMODITYCODETEXT-TRDCLASSFCTNNMBRNAME AS TRDCLASSFCTNNMBRNAME ,
*       \_COMMODITYCODETEXT-TRDCLASSFCTNNMBRTEXT AS TRDCLASSFCTNNMBRTEXT ,
*       \_COMMODITYCODETEXT-TRDCLASSFCTNNMBRSCHMTYPE AS TRDCLASSFCTNNMBRSCHMTYPE
*     FROM
*      C_PRODCOMMODITYCODEFORKEYDATE( P_KEYDATE = '20240129' )
*     WHERE
*      \_COMMODITYCODETEXT-TRDCLASSFCTNNMBRSCHMCNTNT = 'EU01'
*     AND \_COMMODITYCODETEXT-VALIDITYSTARTDATE = '20230101'
*     AND \_COMMODITYCODETEXT-LANGUAGE = 'E'
*     AND C_PRODCOMMODITYCODEFORKEYDATE~TRDCLASSFCTNNMBRSCHM = 'EU01'
*     AND C_PRODCOMMODITYCODEFORKEYDATE~TRDCLASSFCTNNMBRSCHMCNTNT = 'EU01'
*     AND C_PRODCOMMODITYCODEFORKEYDATE~PRODUCT = '0000555-006-C-075'
*     AND C_PRODCOMMODITYCODEFORKEYDATE~VALIDITYSTARTDATE = '20230101'
*     AND \_COMMODITYCODETEXT-TRDCLASSFCTNNMBRSCHMCNTNT IS NOT NULL
*     INTO TABLE @DATA(LT_RESULT)
*     UP TO 100 ROWS .

*     SELECT
*           \_OFFICIALDESC-LANGUAGE AS LANGUAGE ,
*           \_OFFICIALDESC-TRDCLASSFCTNNMBRSCHMCNTNT AS TRDCLASSFCTNNMBRSCHMCNTNT ,
*           \_OFFICIALDESC-TRDCLASSFCTNNMBR AS TRDCLASSFCTNNMBR ,
*           \_OFFICIALDESC-VALIDITYSTARTDATE AS VALIDITYSTARTDATE ,
*           \_OFFICIALDESC-TRDCLASSFCTNNMBROFFICIALDESC AS TRDCLASSFCTNNMBROFFICIALDESC
*        FROM
*          C_COMMODITYCODEFORKEYDATE( P_KEYDATE = '20240124' )
*        WHERE
*          C_COMMODITYCODEFORKEYDATE~TRDCLASSFCTNNMBRSCHM = 'EU01'
*        AND C_COMMODITYCODEFORKEYDATE~COMMODITYCODE = '62121090'
*        AND \_OFFICIALDESC-LANGUAGE IS NOT NULL
*        INTO TABLE @DATA(LT_RESULT)
*        UP TO 100 ROWS .

*        SELECT
*           \_OFFICIALDESC-LANGUAGE AS LANGUAGE ,
*           \_OFFICIALDESC-TRDCLASSFCTNNMBROFFICIALDESC AS TRDCLASSFCTNNMBROFFICIALDESC
*        FROM
*          C_COMMODITYCODEFORKEYDATE( P_KEYDATE = '20240124' )
*        WHERE
*          C_COMMODITYCODEFORKEYDATE~TRDCLASSFCTNNMBRSCHM = 'EU01'
*        AND C_COMMODITYCODEFORKEYDATE~COMMODITYCODE = '62121090'
*        AND \_OFFICIALDESC-LANGUAGE = 'E'
*        INTO TABLE @DATA(LT_RESULT)
*        UP TO 100 ROWS .

*    SELECT SINGLE * FROM I_TrdClassfctnNmbrText INTO @DATA(commodity_text).

*     SELECT
*           \_OFFICIALDESC-TRDCLASSFCTNNMBROFFICIALDESC AS TRDCLASSFCTNNMBROFFICIALDESC
*        FROM
*          C_COMMODITYCODEFORKEYDATE( P_KEYDATE = '20240124' )
*        WHERE
*          C_COMMODITYCODEFORKEYDATE~TRDCLASSFCTNNMBRSCHM = 'EU01'
*        AND C_COMMODITYCODEFORKEYDATE~COMMODITYCODE = '62121090'
*        AND \_OFFICIALDESC-LANGUAGE IS NOT NULL
*        INTO TABLE @DATA(LT_RESULT)
*        UP TO 100 ROWS .

*    SELECT SINGLE * FROM I_TrdClassfctnNmbrOfficialDesc INTO @DATA(commodity_desc).  " I_TrdClassfctnNmbrOfficialDesc not permitted
*    SELECT SINGLE * FROM YY1_COLOR_V WITH PRIVILEGED ACCESS WHERE CODE = '003' INTO @DATA(color). " YY1_COLOR_V not permitted
*    SELECT SINGLE * FROM YY1_COLOR_W WITH PRIVILEGED ACCESS WHERE CODE = '003' INTO @DATA(color). " YY1_COLOR_W not permitted

    SELECT SINGLE * FROM C_COMMODITYCODEFORKEYDATE( P_KEYDATE = '20240124' ) INTO @DATA(commoditycode).

  ENDMETHOD.

ENDCLASS.
