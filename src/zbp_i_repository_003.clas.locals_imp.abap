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

*   read transfered instances
    READ ENTITIES OF zi_repository_003 IN LOCAL MODE
      ENTITY Repository
      ALL FIELDS
      WITH CORRESPONDING #( keys )
      RESULT DATA(entities).

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).

        IF ( <entity>-%is_draft = '00' ). " Saved
        ENDIF.

        IF ( <entity>-%is_draft = '01' ). " Draft
        ENDIF.

        DATA lv_xml_data        TYPE xstring.
        DATA lv_xdp             TYPE xstring.
        DATA ls_options         TYPE cl_fp_ads_util=>ty_gs_options_pdf.
        DATA ev_pdf             TYPE xstring.
        DATA ev_pages           TYPE int4.
        DATA ev_trace_string    TYPE string.

        TRY.

*           XML
            DATA(xml_data) =
            '<?xml version="1.0" encoding="UTF-8"?>' &&
            '<form1>' &&
            '<RepositoryID>' && <entity>-RepositoryID && '</RepositoryID>' &&
            '<Comments>' && <entity>-Comments && '</Comments>' &&
            '</form1>'.

            lv_xml_data = cl_abap_message_digest=>string_to_xstring( xml_data ).

*           XDP - Xstring (binary) format
            lv_xdp = <entity>-xdp. " cl_abap_message_digest=>string_to_xstring( text ). "

            DATA base64_xdp TYPE string.
            IF ( 1 = 0 ).
*               " Take XDP from attachment
                base64_xdp = cl_web_http_utility=>encode_x_base64( lv_xdp ). " convert Xstring (binary) into Base64 (string)
            ELSE.
                " take XDP directly as the hard code (test.xdp):
                base64_xdp =
'PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPD94ZmEgZ2VuZXJhdG9yPSJBZG9iZUxpdmVDeWNsZURlc2lnbmVyX1YxMS4wLjEuMjAxNDAyMTguMS45MDcxNjJfU0FQIiBBUElWZXJzaW9uPSIzLjYuMTMzMjQuMCI/Pg0KPHhkcDp4ZHAgeG1sbnM6eGRwPSJodHRwOi8vbnMuYWRvYmUuY29tL3hkcC8iIHRpbW' &&
'VTdGFtcD0iMjAyMy0xMi0yMFQxNDozNDo1NloiIHV1aWQ9IjFjNDg2YmE1LTM2Y2YtNDMwMy04OTAyLTVjMjEwNGE0MTFlOCI+DQo8dGVtcGxhdGUgeG1sbnM6eGxpZmY9InVybjpvYXNpczpuYW1lczp0Yzp4bGlmZjpkb2N1bWVudDoxLjEiIHhtbG5zPSJodHRwOi8vd3d3LnhmYS5vcmcvc2NoZW1hL3hmYS10ZW1wbGF0ZS8zLjMv' &&
'Ij4NCiAgIDw/Zm9ybVNlcnZlciBkZWZhdWx0UERGUmVuZGVyRm9ybWF0IGFjcm9iYXQxMC4wZHluYW1pYz8+DQogICA8P2Zvcm1TZXJ2ZXIgYWxsb3dSZW5kZXJDYWNoaW5nIDA/Pg0KICAgPD9mb3JtU2VydmVyIGZvcm1Nb2RlbCBib3RoPz4NCiAgIDxzdWJmb3JtIG5hbWU9ImZvcm0xIiBsYXlvdXQ9InRiIiBsb2NhbGU9InNrX1' &&
'NLIiByZXN0b3JlU3RhdGU9ImF1dG8iPg0KICAgICAgPHBhZ2VTZXQ+DQogICAgICAgICA8cGFnZUFyZWEgbmFtZT0iUGFnZTEiIGlkPSJQYWdlMSI+DQogICAgICAgICAgICA8Y29udGVudEFyZWEgeD0iMC4yNWluIiB5PSIwLjI1aW4iIHc9IjE5Ny4zbW0iIGg9IjI4NC4zbW0iLz4NCiAgICAgICAgICAgIDxtZWRpdW0gc3RvY2s9' &&
'ImE0IiBzaG9ydD0iMjEwbW0iIGxvbmc9IjI5N21tIi8+DQogICAgICAgICAgICA8P3RlbXBsYXRlRGVzaWduZXIgZXhwYW5kIDE/PjwvcGFnZUFyZWE+DQogICAgICAgICA8P3RlbXBsYXRlRGVzaWduZXIgZXhwYW5kIDE/PjwvcGFnZVNldD4NCiAgICAgIDxzdWJmb3JtIHc9IjE5Ny4zbW0iIGg9IjI4NC4zbW0iPg0KICAgICAgIC' &&
'AgPGZpZWxkIG5hbWU9IlJlcG9zaXRvcnlJRCIgeT0iNDEuMjc1bW0iIHg9IjY2LjY3NW1tIiB3PSI2Mm1tIiBoPSI5bW0iIGFjY2Vzcz0icmVhZE9ubHkiPg0KICAgICAgICAgICAgPHVpPg0KICAgICAgICAgICAgICAgPHRleHRFZGl0Pg0KICAgICAgICAgICAgICAgICAgPGJvcmRlcj4NCiAgICAgICAgICAgICAgICAgICAgIDxl' &&
'ZGdlIHN0cm9rZT0ibG93ZXJlZCIvPg0KICAgICAgICAgICAgICAgICAgPC9ib3JkZXI+DQogICAgICAgICAgICAgICAgICA8bWFyZ2luLz4NCiAgICAgICAgICAgICAgIDwvdGV4dEVkaXQ+DQogICAgICAgICAgICA8L3VpPg0KICAgICAgICAgICAgPGZvbnQgdHlwZWZhY2U9IkFyaWFsIi8+DQogICAgICAgICAgICA8bWFyZ2luIH' &&
'RvcEluc2V0PSIxbW0iIGJvdHRvbUluc2V0PSIxbW0iIGxlZnRJbnNldD0iMW1tIiByaWdodEluc2V0PSIxbW0iLz4NCiAgICAgICAgICAgIDxwYXJhIHZBbGlnbj0ibWlkZGxlIi8+DQogICAgICAgICAgICA8Y2FwdGlvbiByZXNlcnZlPSIyNW1tIj4NCiAgICAgICAgICAgICAgIDxwYXJhIHZBbGlnbj0ibWlkZGxlIi8+DQogICAg' &&
'ICAgICAgICAgICA8dmFsdWU+DQogICAgICAgICAgICAgICAgICA8dGV4dCB4bGlmZjpyaWQ9IkJBOTVFMjkxLUVGN0UtNEE5RC04QTFFLTgwNzAzQTE0ODU3MiI+UmVwb3NpdG9yeSBJRDwvdGV4dD4NCiAgICAgICAgICAgICAgIDwvdmFsdWU+DQogICAgICAgICAgICA8L2NhcHRpb24+DQogICAgICAgICAgICA8YmluZCBtYXRjaD' &&
'0iZGF0YVJlZiIgcmVmPSIkLlJlcG9zaXRvcnlJRCIvPg0KICAgICAgICAgPC9maWVsZD4NCiAgICAgICAgIDxmaWVsZCBuYW1lPSJDb21tZW50IiB5PSI1My45NzVtbSIgeD0iNjYuNjc1bW0iIHc9IjkyLjA3NW1tIiBoPSI5bW0iIGFjY2Vzcz0icmVhZE9ubHkiPg0KICAgICAgICAgICAgPHVpPg0KICAgICAgICAgICAgICAgPHRl' &&
'eHRFZGl0IG11bHRpTGluZT0iMSI+DQogICAgICAgICAgICAgICAgICA8Ym9yZGVyPg0KICAgICAgICAgICAgICAgICAgICAgPGVkZ2Ugc3Ryb2tlPSJsb3dlcmVkIi8+DQogICAgICAgICAgICAgICAgICA8L2JvcmRlcj4NCiAgICAgICAgICAgICAgICAgIDxtYXJnaW4vPg0KICAgICAgICAgICAgICAgPC90ZXh0RWRpdD4NCiAgIC' &&
'AgICAgICAgIDwvdWk+DQogICAgICAgICAgICA8Zm9udCB0eXBlZmFjZT0iQXJpYWwiLz4NCiAgICAgICAgICAgIDxtYXJnaW4gdG9wSW5zZXQ9IjFtbSIgYm90dG9tSW5zZXQ9IjFtbSIgbGVmdEluc2V0PSIxbW0iIHJpZ2h0SW5zZXQ9IjFtbSIvPg0KICAgICAgICAgICAgPHBhcmEgdkFsaWduPSJtaWRkbGUiLz4NCiAgICAgICAg' &&
'ICAgIDxjYXB0aW9uIHJlc2VydmU9IjI1bW0iPg0KICAgICAgICAgICAgICAgPHBhcmEgdkFsaWduPSJtaWRkbGUiLz4NCiAgICAgICAgICAgICAgIDx2YWx1ZT4NCiAgICAgICAgICAgICAgICAgIDx0ZXh0IHhsaWZmOnJpZD0iRDlENTQ0ODItRkEzMi00Nzk0LUJCMkEtNTNCNjNGQ0NCMEMyIj5Db21tZW50czwvdGV4dD4NCiAgIC' &&
'AgICAgICAgICAgIDwvdmFsdWU+DQogICAgICAgICAgICA8L2NhcHRpb24+DQogICAgICAgICAgICA8YmluZCBtYXRjaD0iZGF0YVJlZiIgcmVmPSIkLkNvbW1lbnRzIi8+DQogICAgICAgICA8L2ZpZWxkPg0KICAgICAgICAgPD90ZW1wbGF0ZURlc2lnbmVyIGV4cGFuZCAxPz48L3N1YmZvcm0+DQogICAgICA8cHJvdG8vPg0KICAg' &&
'ICAgPGRlc2M+DQogICAgICAgICA8dGV4dCBuYW1lPSJ2ZXJzaW9uIj4xMS4wLjEuMjAxNDAyMTguMS45MDcxNjIuOTAzODAxPC90ZXh0Pg0KICAgICAgPC9kZXNjPg0KICAgICAgPD90ZW1wbGF0ZURlc2lnbmVyIEh5cGhlbmF0aW9uIGV4Y2x1ZGVJbml0aWFsQ2FwOjEsIGV4Y2x1ZGVBbGxDYXBzOjEsIHdvcmRDaGFyQ250OjcsIH' &&
'JlbWFpbkNoYXJDbnQ6MywgcHVzaENoYXJDbnQ6Mz8+DQogICAgICA8P3RlbXBsYXRlRGVzaWduZXIgZXhwYW5kIDE/Pg0KICAgICAgPD9yZW5kZXJDYWNoZS5zdWJzZXQgIkFyaWFsIiAwIDAgVVRGLTE2IDIgODAgMDAwMzAwMjYwMDI3MDAyQzAwMzEwMDM1MDA0NTAwNDYwMDQ4MDA0QzAwNTAwMDUxMDA1MjAwNTMwMDU1MDA1NjAw' &&
'NTcwMDU4MDA1OTAwNUM/Pjwvc3ViZm9ybT4NCiAgIDw/dGVtcGxhdGVEZXNpZ25lciBEZWZhdWx0UHJldmlld0R5bmFtaWMgMT8+DQogICA8P3RlbXBsYXRlRGVzaWduZXIgR3JpZCBzaG93OjEsIHNuYXA6MSwgdW5pdHM6MCwgY29sb3I6ZmY4MDgwLCBvcmlnaW46KDAsMCksIGludGVydmFsOigxMjUwMDAsMTI1MDAwKT8+DQogIC' &&
'A8P3RlbXBsYXRlRGVzaWduZXIgV2lkb3dPcnBoYW5Db250cm9sIDA/Pg0KICAgPD90ZW1wbGF0ZURlc2lnbmVyIFNhdmVQREZXaXRoTG9nIDA/Pg0KICAgPD90ZW1wbGF0ZURlc2lnbmVyIFpvb20gNjk/Pg0KICAgPD90ZW1wbGF0ZURlc2lnbmVyIEZvcm1UYXJnZXRWZXJzaW9uIDMzPz4NCiAgIDw/b3JpZ2luYWxYRkFWZXJzaW9u' &&
'IGh0dHA6Ly93d3cueGZhLm9yZy9zY2hlbWEveGZhLXRlbXBsYXRlLzMuMy8/Pg0KICAgPD90ZW1wbGF0ZURlc2lnbmVyIERlZmF1bHRMYW5ndWFnZSBGb3JtQ2FsYz8+DQogICA8P3RlbXBsYXRlRGVzaWduZXIgRGVmYXVsdFJ1bkF0IGNsaWVudD8+DQogICA8P2Fjcm9iYXQgSmF2YVNjcmlwdCBzdHJpY3RTY29waW5nPz4NCiAgID' &&
'w/UERGUHJpbnRPcHRpb25zIGVtYmVkVmlld2VyUHJlZnMgMD8+DQogICA8P1BERlByaW50T3B0aW9ucyBlbWJlZFByaW50T25Gb3JtT3BlbiAwPz4NCiAgIDw/UERGUHJpbnRPcHRpb25zIHNjYWxpbmdQcmVmcyAwPz4NCiAgIDw/UERGUHJpbnRPcHRpb25zIGVuZm9yY2VTY2FsaW5nUHJlZnMgMD8+DQogICA8P1BERlByaW50T3B0' &&
'aW9ucyBwYXBlclNvdXJjZSAwPz4NCiAgIDw/UERGUHJpbnRPcHRpb25zIGR1cGxleE1vZGUgMD8+DQogICA8P3RlbXBsYXRlRGVzaWduZXIgRGVmYXVsdFByZXZpZXdUeXBlIGludGVyYWN0aXZlPz4NCiAgIDw/dGVtcGxhdGVEZXNpZ25lciBEZWZhdWx0UHJldmlld1BhZ2luYXRpb24gc2ltcGxleD8+DQogICA8P3RlbXBsYXRlRG' &&
'VzaWduZXIgWERQUHJldmlld0Zvcm1hdCAyMD8+DQogICA8P3RlbXBsYXRlRGVzaWduZXIgRGVmYXVsdFByZXZpZXdEYXRhRmlsZU5hbWUgLlx0ZXN0LnhtbD8+DQogICA8P3RlbXBsYXRlRGVzaWduZXIgRGVmYXVsdENhcHRpb25Gb250U2V0dGluZ3MgZmFjZTpBcmlhbDtzaXplOjEwO3dlaWdodDpub3JtYWw7c3R5bGU6bm9ybWFs' &&
'Pz4NCiAgIDw/dGVtcGxhdGVEZXNpZ25lciBEZWZhdWx0VmFsdWVGb250U2V0dGluZ3MgZmFjZTpBcmlhbDtzaXplOjEwO3dlaWdodDpub3JtYWw7c3R5bGU6bm9ybWFsPz4NCiAgIDw/dGVtcGxhdGVEZXNpZ25lciBTYXZlVGFnZ2VkUERGIDA/Pg0KICAgPD90ZW1wbGF0ZURlc2lnbmVyIFNhdmVQREZXaXRoRW1iZWRkZWRGb250cy' &&
'AwPz4NCiAgIDw/dGVtcGxhdGVEZXNpZ25lciBSdWxlcnMgaG9yaXpvbnRhbDoxLCB2ZXJ0aWNhbDoxLCBndWlkZWxpbmVzOjEsIGNyb3NzaGFpcnM6MD8+PC90ZW1wbGF0ZT4NCjxjb25maWcgeG1sbnM9Imh0dHA6Ly93d3cueGZhLm9yZy9zY2hlbWEveGNpLzMuMC8iPg0KICAgPGFnZW50IG5hbWU9ImRlc2lnbmVyIj4NCiAgICAg' &&
'IDwhLS0gIFswLi5uXSAgLS0+DQogICAgICA8ZGVzdGluYXRpb24+cGRmPC9kZXN0aW5hdGlvbj4NCiAgICAgIDxwZGY+DQogICAgICAgICA8IS0tICBbMC4ubl0gIC0tPg0KICAgICAgICAgPGZvbnRJbmZvLz4NCiAgICAgIDwvcGRmPg0KICAgPC9hZ2VudD4NCiAgIDxwcmVzZW50Pg0KICAgICAgPCEtLSAgWzAuLm5dICAtLT4NCi' &&
'AgICAgIDxwZGY+DQogICAgICAgICA8IS0tICBbMC4ubl0gIC0tPg0KICAgICAgICAgPHZlcnNpb24+MS43PC92ZXJzaW9uPg0KICAgICAgICAgPGFkb2JlRXh0ZW5zaW9uTGV2ZWw+ODwvYWRvYmVFeHRlbnNpb25MZXZlbD4NCiAgICAgIDwvcGRmPg0KICAgICAgPGNvbW1vbj4NCiAgICAgICAgIDxkYXRhPg0KICAgICAgICAgICAg' &&
'PHhzbD4NCiAgICAgICAgICAgICAgIDx1cmkvPg0KICAgICAgICAgICAgPC94c2w+DQogICAgICAgICAgICA8b3V0cHV0WFNMPg0KICAgICAgICAgICAgICAgPHVyaS8+DQogICAgICAgICAgICA8L291dHB1dFhTTD4NCiAgICAgICAgIDwvZGF0YT4NCiAgICAgIDwvY29tbW9uPg0KICAgICAgPHhkcD4NCiAgICAgICAgIDxwYWNrZX' &&
'RzPio8L3BhY2tldHM+DQogICAgICA8L3hkcD4NCiAgIDwvcHJlc2VudD4NCjwvY29uZmlnPg0KPHhmYTpkYXRhc2V0cyB4bWxuczp4ZmE9Imh0dHA6Ly93d3cueGZhLm9yZy9zY2hlbWEveGZhLWRhdGEvMS4wLyI+DQogICA8eGZhOmRhdGEgeGZhOmRhdGFOb2RlPSJkYXRhR3JvdXAiLz4NCiAgIDxkZDpkYXRhRGVzY3JpcHRpb24g' &&
'eG1sbnM6ZGQ9Imh0dHA6Ly9ucy5hZG9iZS5jb20vZGF0YS1kZXNjcmlwdGlvbi8iIGRkOm5hbWU9ImZvcm0xIj4NCiAgICAgIDxmb3JtMT4NCiAgICAgICAgIDxSZXBvc2l0b3J5SUQvPg0KICAgICAgICAgPENvbW1lbnRzLz4NCiAgICAgIDwvZm9ybTE+DQogICA8L2RkOmRhdGFEZXNjcmlwdGlvbj4NCjwveGZhOmRhdGFzZXRzPg' &&
'0KPGNvbm5lY3Rpb25TZXQgeG1sbnM9Imh0dHA6Ly93d3cueGZhLm9yZy9zY2hlbWEveGZhLWNvbm5lY3Rpb24tc2V0LzIuOC8iPg0KICAgPHhtbENvbm5lY3Rpb24gbmFtZT0iRGF0YUNvbm5lY3Rpb24iIGRhdGFEZXNjcmlwdGlvbj0iZm9ybTEiPg0KICAgICAgPHVyaT4uXHRlc3QueG1sPC91cmk+DQogICAgICA8P3RlbXBsYXRl' &&
'RGVzaWduZXIgZmlsZURpZ2VzdCBzaGFIYXNoPSJRSVFzK3Y5dmRhbXRJR1NPd0cwWFBadytQT1U9Ij8+PC94bWxDb25uZWN0aW9uPg0KPC9jb25uZWN0aW9uU2V0Pg0KPGxvY2FsZVNldCB4bWxucz0iaHR0cDovL3d3dy54ZmEub3JnL3NjaGVtYS94ZmEtbG9jYWxlLXNldC8yLjcvIj4NCiAgIDxsb2NhbGUgbmFtZT0ic2tfU0siIG' &&
'Rlc2M9IlNsb3ZhayAoU2xvdmFraWEpIj4NCiAgICAgIDxjYWxlbmRhclN5bWJvbHMgbmFtZT0iZ3JlZ29yaWFuIj4NCiAgICAgICAgIDxtb250aE5hbWVzPg0KICAgICAgICAgICAgPG1vbnRoPmphbnXDoXI8L21vbnRoPg0KICAgICAgICAgICAgPG1vbnRoPmZlYnJ1w6FyPC9tb250aD4NCiAgICAgICAgICAgIDxtb250aD5tYXJl' &&
'YzwvbW9udGg+DQogICAgICAgICAgICA8bW9udGg+YXByw61sPC9tb250aD4NCiAgICAgICAgICAgIDxtb250aD5tw6FqPC9tb250aD4NCiAgICAgICAgICAgIDxtb250aD5qw7puPC9tb250aD4NCiAgICAgICAgICAgIDxtb250aD5qw7psPC9tb250aD4NCiAgICAgICAgICAgIDxtb250aD5hdWd1c3Q8L21vbnRoPg0KICAgICAgIC' &&
'AgICAgPG1vbnRoPnNlcHRlbWJlcjwvbW9udGg+DQogICAgICAgICAgICA8bW9udGg+b2t0w7NiZXI8L21vbnRoPg0KICAgICAgICAgICAgPG1vbnRoPm5vdmVtYmVyPC9tb250aD4NCiAgICAgICAgICAgIDxtb250aD5kZWNlbWJlcjwvbW9udGg+DQogICAgICAgICA8L21vbnRoTmFtZXM+DQogICAgICAgICA8bW9udGhOYW1lcyBh' &&
'YmJyPSIxIj4NCiAgICAgICAgICAgIDxtb250aD5qYW48L21vbnRoPg0KICAgICAgICAgICAgPG1vbnRoPmZlYjwvbW9udGg+DQogICAgICAgICAgICA8bW9udGg+bWFyPC9tb250aD4NCiAgICAgICAgICAgIDxtb250aD5hcHI8L21vbnRoPg0KICAgICAgICAgICAgPG1vbnRoPm3DoWo8L21vbnRoPg0KICAgICAgICAgICAgPG1vbn' &&
'RoPmrDum48L21vbnRoPg0KICAgICAgICAgICAgPG1vbnRoPmrDumw8L21vbnRoPg0KICAgICAgICAgICAgPG1vbnRoPmF1ZzwvbW9udGg+DQogICAgICAgICAgICA8bW9udGg+c2VwPC9tb250aD4NCiAgICAgICAgICAgIDxtb250aD5va3Q8L21vbnRoPg0KICAgICAgICAgICAgPG1vbnRoPm5vdjwvbW9udGg+DQogICAgICAgICAg' &&
'ICA8bW9udGg+ZGVjPC9tb250aD4NCiAgICAgICAgIDwvbW9udGhOYW1lcz4NCiAgICAgICAgIDxkYXlOYW1lcz4NCiAgICAgICAgICAgIDxkYXk+TmVkZcS+YTwvZGF5Pg0KICAgICAgICAgICAgPGRheT5Qb25kZWxvazwvZGF5Pg0KICAgICAgICAgICAgPGRheT5VdG9yb2s8L2RheT4NCiAgICAgICAgICAgIDxkYXk+U3RyZWRhPC' &&
'9kYXk+DQogICAgICAgICAgICA8ZGF5PsWgdHZydG9rPC9kYXk+DQogICAgICAgICAgICA8ZGF5PlBpYXRvazwvZGF5Pg0KICAgICAgICAgICAgPGRheT5Tb2JvdGE8L2RheT4NCiAgICAgICAgIDwvZGF5TmFtZXM+DQogICAgICAgICA8ZGF5TmFtZXMgYWJicj0iMSI+DQogICAgICAgICAgICA8ZGF5Pk5lPC9kYXk+DQogICAgICAg' &&
'ICAgICA8ZGF5PlBvPC9kYXk+DQogICAgICAgICAgICA8ZGF5PlV0PC9kYXk+DQogICAgICAgICAgICA8ZGF5PlN0PC9kYXk+DQogICAgICAgICAgICA8ZGF5PsWgdDwvZGF5Pg0KICAgICAgICAgICAgPGRheT5QYTwvZGF5Pg0KICAgICAgICAgICAgPGRheT5TbzwvZGF5Pg0KICAgICAgICAgPC9kYXlOYW1lcz4NCiAgICAgICAgID' &&
'xtZXJpZGllbU5hbWVzPg0KICAgICAgICAgICAgPG1lcmlkaWVtPkFNPC9tZXJpZGllbT4NCiAgICAgICAgICAgIDxtZXJpZGllbT5QTTwvbWVyaWRpZW0+DQogICAgICAgICA8L21lcmlkaWVtTmFtZXM+DQogICAgICAgICA8ZXJhTmFtZXM+DQogICAgICAgICAgICA8ZXJhPnByZWQgbi5sLjwvZXJhPg0KICAgICAgICAgICAgPGVy' &&
'YT5uLmwuPC9lcmE+DQogICAgICAgICA8L2VyYU5hbWVzPg0KICAgICAgPC9jYWxlbmRhclN5bWJvbHM+DQogICAgICA8ZGF0ZVBhdHRlcm5zPg0KICAgICAgICAgPGRhdGVQYXR0ZXJuIG5hbWU9ImZ1bGwiPkVFRUUsIEQuIE1NTU0gWVlZWTwvZGF0ZVBhdHRlcm4+DQogICAgICAgICA8ZGF0ZVBhdHRlcm4gbmFtZT0ibG9uZyI+RC' &&
'4gTU1NTSBZWVlZPC9kYXRlUGF0dGVybj4NCiAgICAgICAgIDxkYXRlUGF0dGVybiBuYW1lPSJtZWQiPkQuTS5ZWVlZPC9kYXRlUGF0dGVybj4NCiAgICAgICAgIDxkYXRlUGF0dGVybiBuYW1lPSJzaG9ydCI+RC5NLllZWVk8L2RhdGVQYXR0ZXJuPg0KICAgICAgPC9kYXRlUGF0dGVybnM+DQogICAgICA8dGltZVBhdHRlcm5zPg0K' &&
'ICAgICAgICAgPHRpbWVQYXR0ZXJuIG5hbWU9ImZ1bGwiPkg6TU06U1MgWjwvdGltZVBhdHRlcm4+DQogICAgICAgICA8dGltZVBhdHRlcm4gbmFtZT0ibG9uZyI+SDpNTTpTUyBaPC90aW1lUGF0dGVybj4NCiAgICAgICAgIDx0aW1lUGF0dGVybiBuYW1lPSJtZWQiPkg6TU06U1M8L3RpbWVQYXR0ZXJuPg0KICAgICAgICAgPHRpbW' &&
'VQYXR0ZXJuIG5hbWU9InNob3J0Ij5IOk1NPC90aW1lUGF0dGVybj4NCiAgICAgIDwvdGltZVBhdHRlcm5zPg0KICAgICAgPGRhdGVUaW1lU3ltYm9scz5HYW5qa0htc1NFREZ3V3hoS3paPC9kYXRlVGltZVN5bWJvbHM+DQogICAgICA8bnVtYmVyUGF0dGVybnM+DQogICAgICAgICA8bnVtYmVyUGF0dGVybiBuYW1lPSJudW1lcmlj' &&
'Ij56LHp6OS56eno8L251bWJlclBhdHRlcm4+DQogICAgICAgICA8bnVtYmVyUGF0dGVybiBuYW1lPSJjdXJyZW5jeSI+eix6ejkuOTkgJDwvbnVtYmVyUGF0dGVybj4NCiAgICAgICAgIDxudW1iZXJQYXR0ZXJuIG5hbWU9InBlcmNlbnQiPnoseno5JTwvbnVtYmVyUGF0dGVybj4NCiAgICAgIDwvbnVtYmVyUGF0dGVybnM+DQogIC' &&
'AgICA8bnVtYmVyU3ltYm9scz4NCiAgICAgICAgIDxudW1iZXJTeW1ib2wgbmFtZT0iZGVjaW1hbCI+LDwvbnVtYmVyU3ltYm9sPg0KICAgICAgICAgPG51bWJlclN5bWJvbCBuYW1lPSJncm91cGluZyI+wqA8L251bWJlclN5bWJvbD4NCiAgICAgICAgIDxudW1iZXJTeW1ib2wgbmFtZT0icGVyY2VudCI+JTwvbnVtYmVyU3ltYm9s' &&
'Pg0KICAgICAgICAgPG51bWJlclN5bWJvbCBuYW1lPSJtaW51cyI+LTwvbnVtYmVyU3ltYm9sPg0KICAgICAgICAgPG51bWJlclN5bWJvbCBuYW1lPSJ6ZXJvIj4wPC9udW1iZXJTeW1ib2w+DQogICAgICA8L251bWJlclN5bWJvbHM+DQogICAgICA8Y3VycmVuY3lTeW1ib2xzPg0KICAgICAgICAgPGN1cnJlbmN5U3ltYm9sIG5hbW' &&
'U9InN5bWJvbCI+U2s8L2N1cnJlbmN5U3ltYm9sPg0KICAgICAgICAgPGN1cnJlbmN5U3ltYm9sIG5hbWU9Imlzb25hbWUiPlNLSzwvY3VycmVuY3lTeW1ib2w+DQogICAgICAgICA8Y3VycmVuY3lTeW1ib2wgbmFtZT0iZGVjaW1hbCI+LDwvY3VycmVuY3lTeW1ib2w+DQogICAgICA8L2N1cnJlbmN5U3ltYm9scz4NCiAgICAgIDx0' &&
'eXBlZmFjZXM+DQogICAgICAgICA8dHlwZWZhY2UgbmFtZT0iTXlyaWFkIFBybyIvPg0KICAgICAgICAgPHR5cGVmYWNlIG5hbWU9Ik1pbmlvbiBQcm8iLz4NCiAgICAgICAgIDx0eXBlZmFjZSBuYW1lPSJDb3VyaWVyIFN0ZCIvPg0KICAgICAgICAgPHR5cGVmYWNlIG5hbWU9IkFkb2JlIFBpIFN0ZCIvPg0KICAgICAgICAgPHR5cG' &&
'VmYWNlIG5hbWU9IkFkb2JlIEhlYnJldyIvPg0KICAgICAgICAgPHR5cGVmYWNlIG5hbWU9IkFkb2JlIEFyYWJpYyIvPg0KICAgICAgICAgPHR5cGVmYWNlIG5hbWU9IkFkb2JlIFRoYWkiLz4NCiAgICAgICAgIDx0eXBlZmFjZSBuYW1lPSJLb3p1a2EgR290aGljIFByby1WSSBNIi8+DQogICAgICAgICA8dHlwZWZhY2UgbmFtZT0i' &&
'S296dWthIE1pbmNobyBQcm8tVkkgUiIvPg0KICAgICAgICAgPHR5cGVmYWNlIG5hbWU9IkFkb2JlIE1pbmcgU3RkIEwiLz4NCiAgICAgICAgIDx0eXBlZmFjZSBuYW1lPSJBZG9iZSBTb25nIFN0ZCBMIi8+DQogICAgICAgICA8dHlwZWZhY2UgbmFtZT0iQWRvYmUgTXl1bmdqbyBTdGQgTSIvPg0KICAgICAgICAgPHR5cGVmYWNlIG' &&
'5hbWU9IkFkb2JlIERldmFuYWdhcmkiLz4NCiAgICAgIDwvdHlwZWZhY2VzPg0KICAgPC9sb2NhbGU+DQo8L2xvY2FsZVNldD4NCjx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuNC1jMDA1IDc4LjE1MDA1NSwgMjAxMy8wOC8wNy0yMjo1ODo0NyAgICAgICAgIj4NCiAg' &&
'IDxyZGY6UkRGIHhtbG5zOnJkZj0iaHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyI+DQogICAgICA8cmRmOkRlc2NyaXB0aW9uIHhtbG5zOnhtcD0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wLyIgeG1sbnM6cGRmPSJodHRwOi8vbnMuYWRvYmUuY29tL3BkZi8xLjMvIiB4bWxuczp4bXBNTT0iaH' &&
'R0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6ZGVzYz0iaHR0cDovL25zLmFkb2JlLmNvbS94ZmEvcHJvbW90ZWQtZGVzYy8iIHJkZjphYm91dD0iIj4NCiAgICAgICAgIDx4bXA6TWV0YWRhdGFEYXRlPjIwMjMtMTItMjBUMTQ6MzQ6NTZaPC94bXA6TWV0YWRhdGFEYXRlPg0KICAgICAgICAgPHhtcDpDcmVhdG9y' &&
'VG9vbD5BZG9iZSBMaXZlQ3ljbGUgRGVzaWduZXIgMTEuMDwveG1wOkNyZWF0b3JUb29sPg0KICAgICAgICAgPHBkZjpQcm9kdWNlcj5BZG9iZSBMaXZlQ3ljbGUgRGVzaWduZXIgMTEuMDwvcGRmOlByb2R1Y2VyPg0KICAgICAgICAgPHhtcE1NOkRvY3VtZW50SUQ+dXVpZDoxYzQ4NmJhNS0zNmNmLTQzMDMtODkwMi01YzIxMDRhND' &&
'ExZTg8L3htcE1NOkRvY3VtZW50SUQ+DQogICAgICAgICA8ZGVzYzp2ZXJzaW9uIHJkZjpwYXJzZVR5cGU9IlJlc291cmNlIj4NCiAgICAgICAgICAgIDxyZGY6dmFsdWU+MTEuMC4xLjIwMTQwMjE4LjEuOTA3MTYyLjkwMzgwMTwvcmRmOnZhbHVlPg0KICAgICAgICAgICAgPGRlc2M6cmVmPi90ZW1wbGF0ZS9zdWJmb3JtWzFdPC9k' &&
'ZXNjOnJlZj4NCiAgICAgICAgIDwvZGVzYzp2ZXJzaW9uPg0KICAgICAgPC9yZGY6RGVzY3JpcHRpb24+DQogICA8L3JkZjpSREY+DQo8L3g6eG1wbWV0YT48L3hkcDp4ZHA+DQo='.
            ENDIF.
            lv_xdp = cl_web_http_utility=>decode_x_base64( base64_xdp ). " convert Base64 (string) into Xstring (binary)

*           Render PDF
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

*               Convert Xstring (binary) into Base64 (string) (for testing)
                DATA(base64_pdf) = cl_web_http_utility=>encode_x_base64( ev_pdf ).

                DATA(filename2) = <entity>-FileName1.
                REPLACE ALL OCCURRENCES OF '.xdp' IN filename2 WITH '.pdf'.
                DATA(mimetype2) = 'application/pdf'.

                MODIFY ENTITIES OF zi_repository_003 IN LOCAL MODE
                    ENTITY Repository
                    UPDATE FIELDS ( pdf FileName2 MimeType2 )
                    WITH VALUE #( (
                        %tky        = <entity>-%tky
                        pdf         = ev_pdf
                        FileName2   = filename2
                        MimeType2   = mimetype2
                    ) )
                    FAILED DATA(failed2)
                    MAPPED DATA(mapped2)
                    REPORTED DATA(reported2).
            ENDIF.

        CATCH cx_fp_ads_util.
        CATCH cx_abap_message_digest.

        ENDTRY.

    ENDLOOP.

  ENDMETHOD. " make_pdf

  METHOD on_create.

  ENDMETHOD. " on_create

ENDCLASS.
