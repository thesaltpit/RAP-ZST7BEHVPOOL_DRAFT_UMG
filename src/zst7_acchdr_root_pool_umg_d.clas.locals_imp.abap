* This class definition is to be manually added to read the updated values in Create
* and CBA methods, which will then passed to the Save method to update the values
CLASS lhc_buffer DEFINITION.

* Defining static variables
  PUBLIC SECTION.
    CLASS-DATA: mt_acc_hdr TYPE TABLE OF zst7acchdr_dftum,
                mt_acc_itm TYPE TABLE OF zst7accitm_dftum.

ENDCLASS.

CLASS lhc_accountingheader DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS create FOR MODIFY
      IMPORTING hdr_details FOR CREATE accountingheader.

    METHODS delete FOR MODIFY
      IMPORTING values FOR DELETE accountingheader.

    METHODS update FOR MODIFY
      IMPORTING hdr_details FOR UPDATE accountingheader.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK accountingheader.

    METHODS read FOR READ
      IMPORTING keys FOR READ accountingheader RESULT result.

* Create by association ( CBA )
    METHODS cba_items FOR MODIFY
      IMPORTING line_items FOR CREATE accountingheader\_items.

* Read by association ( RBA )
    METHODS rba_items FOR READ
      IMPORTING keys_rba FOR READ accountingheader\_items FULL result_requested RESULT result LINK association_links.

    METHODS get_features FOR FEATURES
      IMPORTING keys REQUEST requested_features FOR accountingheader RESULT result.

    METHODS authority_check FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_autohrizations FOR accountingheader RESULT result.

    METHODS generateonload FOR DETERMINE ON MODIFY
      IMPORTING values FOR accountingheader~generateonload.

* Defining custom copy button
    METHODS copyaccdoc FOR MODIFY
      IMPORTING values FOR ACTION accountingheader~copyaccdoc RESULT oresult.

ENDCLASS.

CLASS lhc_accountingheader IMPLEMENTATION.

  METHOD create.

    DATA: ls_zst7acchdr_dftum TYPE zst7acchdr_dftum.

    LOOP AT hdr_details ASSIGNING FIELD-SYMBOL(<hdr_details_wa>).
      MOVE-CORRESPONDING <hdr_details_wa> TO ls_zst7acchdr_dftum.

      CONVERT DATE sy-datum TIME sy-uzeit
    INTO TIME STAMP DATA(time_stamp) TIME ZONE sy-zonlo.
      ls_zst7acchdr_dftum-createddt_time = time_stamp.
* Move the corresponding updated data to the transactional buffer
* For this we will define a buffer class above here which can then be accessed here
      APPEND ls_zst7acchdr_dftum TO lhc_buffer=>mt_acc_hdr.

      APPEND VALUE #( %cid = <hdr_details_wa>-%cid
                      con_uuid = ls_zst7acchdr_dftum-con_uuid
                    )
                    TO mapped-accountingheader.
    ENDLOOP.

  ENDMETHOD.

  METHOD delete.

    READ TABLE values INTO DATA(ls_accdata) INDEX 1.
    IF sy-subrc EQ 0.
* Deleting the header entry from the header table ZST7ACCHDR_DFTUM
      DELETE FROM zst7acchdr_dftum WHERE con_uuid = ls_accdata-con_uuid.
*  Deleting the line items from the item table ZST7ACCITM_DFTUM
      DELETE FROM zst7accitm_dftum WHERE con_uuid = ls_accdata-con_uuid.
    ENDIF.


  ENDMETHOD.

  METHOD update.

    DATA: lt_acc_hdr TYPE TABLE OF zst7acchdr_dftum,
          ls_acc_hdr TYPE zst7acchdr_dftum.


* In Update I do not get access to the lhc_buffer=>mt_acc_hdr or lhc_buffer=>mt_acc_itm
* and hence we will update the header and line item table here itself and not in the
* Save method.

****** Start of logic to update the Header table *********
** Picking the header details from table zst7acchdr_dftum
    SELECT *
    FROM zst7acchdr_dftum
    INTO TABLE lt_acc_hdr
    FOR ALL ENTRIES IN hdr_details
    WHERE con_uuid = hdr_details-con_uuid
      AND bukrs = hdr_details-bukrs
      AND belnr = hdr_details-belnr
      AND gjahr = hdr_details-gjahr.

    IF sy-subrc EQ 0.

* <control> will list out all the fields where a change has been made.
* If the value is 00 then no change has been made, else if it 01 then the field
* value has been changed.
      READ TABLE hdr_details INTO DATA(ls_hdr_details) INDEX 1.
      IF sy-subrc EQ 0.
        ASSIGN ls_hdr_details-%control TO FIELD-SYMBOL(<control>).
        IF sy-subrc EQ 0.
          READ TABLE lt_acc_hdr INTO ls_acc_hdr WITH KEY con_uuid = ls_hdr_details-con_uuid
                                                         bukrs = ls_hdr_details-bukrs
                                                         belnr = ls_hdr_details-belnr
                                                         gjahr = ls_hdr_details-gjahr.
          IF sy-subrc EQ 0 AND <control>-blart EQ '01'.
            ls_acc_hdr-blart = ls_hdr_details-blart.
          ENDIF.
          IF sy-subrc EQ 0 AND <control>-bldat EQ '01'.
            ls_acc_hdr-bldat = ls_hdr_details-bldat.
          ENDIF.
          IF sy-subrc EQ 0 AND <control>-tcode EQ '01'.
            ls_acc_hdr-tcode = ls_hdr_details-tcode.
          ENDIF.
          IF sy-subrc EQ 0 AND <control>-xblnr EQ '01'.
            ls_acc_hdr-xblnr = ls_hdr_details-xblnr.
          ENDIF.
          IF sy-subrc EQ 0 AND <control>-bktxt EQ '01'.
            ls_acc_hdr-bktxt = ls_hdr_details-bktxt.
          ENDIF.
        ENDIF.
      ENDIF.


*Updating the header table. After this the Save method is called where
*lhc_buffer=>mt_acc_hdr is called and the line item from the header buffer table will
*be deleted by the system.
      MODIFY zst7acchdr_dftum FROM ls_acc_hdr.

    ENDIF.


* For the line items the changed data is getting captured in the lhc_buffer=>mt_acc_itm
* table and hence gets updated in the Save method below
* So no need to add any custom logic for line items here in Update

  ENDMETHOD.

  METHOD lock.

  ENDMETHOD.

  METHOD read.

  ENDMETHOD.

  METHOD cba_items.

    DATA: ls_lines_output TYPE zst7accitm_dftum,
          ls_dochdr       TYPE zst7acchdr_dftum.

    LOOP AT line_items INTO DATA(ls_line_data).
      LOOP AT ls_line_data-%target ASSIGNING FIELD-SYMBOL(<ls_line_target>).
        MOVE-CORRESPONDING <ls_line_target> TO ls_lines_output.
        READ TABLE lhc_buffer=>mt_acc_hdr INTO DATA(tmp_hdr) WITH KEY con_uuid = ls_lines_output-con_uuid.
        IF sy-subrc EQ 0.
          ls_lines_output-bukrs = tmp_hdr-bukrs.
          ls_lines_output-belnr = tmp_hdr-belnr.
          ls_lines_output-gjahr = tmp_hdr-gjahr.
        ELSE.
* If a new line item is added to an already saved document, then this line
* is read and bukrs, belnr & gjahr are updated in the Z table
          SELECT SINGLE *
          FROM zst7acchdr_dftum
          INTO ls_dochdr
          WHERE con_uuid = <ls_line_target>-con_uuid.

          IF sy-subrc EQ 0.
            ls_lines_output-bukrs = ls_dochdr-bukrs.
            ls_lines_output-belnr = ls_dochdr-belnr.
            ls_lines_output-gjahr = ls_dochdr-gjahr.
          ENDIF.

        ENDIF.

        CONVERT DATE sy-datum TIME sy-uzeit
            INTO TIME STAMP DATA(time_stamp) TIME ZONE sy-zonlo.
        ls_lines_output-changed_dt_time = time_stamp.
*  Move the corresponding updated data to the transactional buffer
* For this we will define a buffer class above here which can then be accessed here
        APPEND ls_lines_output TO lhc_buffer=>mt_acc_itm.

        APPEND VALUE #( %cid = <ls_line_target>-%cid
                        item_uuid = <ls_line_target>-item_uuid
                      ) TO mapped-accountinglines.
      ENDLOOP.
    ENDLOOP.


  ENDMETHOD.

  METHOD rba_items.

  ENDMETHOD.

  METHOD get_features.

  ENDMETHOD.

  METHOD authority_check.

  ENDMETHOD.

  METHOD generateonload.

    DATA: lv_numrg    TYPE nrnr VALUE '1',
          lv_year     TYPE nryear,
          lv_newdocno TYPE char10,
          lv_retcode  TYPE nrreturn.

*   First read entity using EML
    READ ENTITIES OF zst7_acchdr_root_pool_umg_dft IN LOCAL MODE
    ENTITY accountingheader
    ALL FIELDS WITH CORRESPONDING #( values )
    RESULT DATA(lt_acchdr).

    lv_year = sy-datum+0(4).

* Generating the document number
    READ TABLE lt_acchdr INTO DATA(ls_acchdr_n) INDEX 1.
    IF sy-subrc EQ 0.
      IF ls_acchdr_n-belnr IS INITIAL.
        CALL FUNCTION 'NUMBER_GET_NEXT'
          EXPORTING
            nr_range_nr = lv_numrg
            object      = 'ZST7ACCNUM'
            subobject   = '1710'
            toyear      = lv_year
          IMPORTING
            number      = lv_newdocno
            returncode  = lv_retcode
                          EXCEPTIONS
                          interval_not_found
                          number_range_not_intern
                          object_not_found
                          quantity_is_0
                          quantity_is_not_1
                          interval_overflow
                          buffer_overflow.

        IF lv_newdocno IS NOT INITIAL.
          ls_acchdr_n-belnr = lv_newdocno.
        ENDIF.

      ENDIF.
    ENDIF.

*   Then modify the entity using EML
    MODIFY ENTITIES OF zst7_acchdr_root_pool_umg_dft IN LOCAL MODE
    ENTITY accountingheader
    UPDATE FIELDS ( bukrs belnr gjahr cpudt cputm usnam )
    WITH VALUE #( FOR ls_acchdr IN lt_acchdr INDEX INTO i (
                  %tky = ls_acchdr-%tky
                  bukrs = '1710'
                  belnr = ls_acchdr_n-belnr
                  gjahr = lv_year
                  cpudt = sy-datum
                  cputm = sy-uzeit
                  usnam = sy-uname
    ) )
    MAPPED DATA(mapped_data)
    FAILED DATA(failed_data)
    REPORTED DATA(reported_data).

* Moving to the output screen
    reported = CORRESPONDING #( DEEP reported_data ).

  ENDMETHOD.

  METHOD copyaccdoc.

    DATA: ls_acchdr    TYPE zst7acchdr_dftum,
          lt_accitm    TYPE STANDARD TABLE OF zst7accitm_dftum,
          ls_accitm    TYPE zst7accitm_dftum,
          lv_numrg     TYPE nrnr VALUE '1',
          lv_subobject TYPE char20,
          lv_year      TYPE nryear,
          lv_newdocno  TYPE char10,
          lv_retcode   TYPE nrreturn,
          lv_con_uuid  TYPE guid_16,
          lv_item_uuid TYPE guid_16.


    READ TABLE values INTO DATA(ls_values) INDEX 1.
    IF sy-subrc EQ 0.
      SELECT SINGLE *
          FROM zst7acchdr_dftum
          INTO ls_acchdr
          WHERE con_uuid = ls_values-con_uuid.

      IF sy-subrc EQ 0.

* Generating the new CON_UUID
        TRY.
            lv_con_uuid = cl_system_uuid=>if_system_uuid_static~create_uuid_x16( ).
          CATCH cx_uuid_error INTO DATA(lo_exc).
        ENDTRY.

        APPEND VALUE #( %cid = ls_values-%cid_ref
                        %is_draft = if_abap_behv=>mk-on
                        con_uuid = lv_con_uuid
                      )
                      TO mapped-accountingheader.

*        APPEND VALUE #( %cid = ls_values-%cid_ref
*                        %is_draft = if_abap_behv=>mk-on
*                        con_uuid = lv_con_uuid
*                      )
*                      TO reported-accountingheader.

        lv_subobject = ls_acchdr-bukrs.
        lv_year = ls_acchdr-gjahr.

* Generating the new document number
        CALL FUNCTION 'NUMBER_GET_NEXT'
          EXPORTING
            nr_range_nr = lv_numrg
            object      = 'ZST7ACCNUM'
            subobject   = lv_subobject
            toyear      = lv_year
          IMPORTING
            number      = lv_newdocno
            returncode  = lv_retcode
                          EXCEPTIONS
                          interval_not_found
                          number_range_not_intern
                          object_not_found
                          quantity_is_0
                          quantity_is_not_1
                          interval_overflow
                          buffer_overflow.

        IF lv_newdocno IS NOT INITIAL.
          ls_acchdr-con_uuid = lv_con_uuid.
          ls_acchdr-belnr = lv_newdocno.
          ls_acchdr-gjahr = sy-datum+0(4).
          ls_acchdr-bldat = sy-datum.
          ls_acchdr-cpudt = sy-datum.
          ls_acchdr-cputm = sy-uzeit.
          ls_acchdr-usnam = sy-uname.
        ENDIF.

        APPEND ls_acchdr TO lhc_buffer=>mt_acc_hdr.

* Picking the line items
        SELECT *
         FROM zst7accitm_dftum
         INTO TABLE lt_accitm
         WHERE con_uuid = ls_values-con_uuid.

        IF sy-subrc EQ 0.

          LOOP AT lt_accitm INTO DATA(ls_accitm_t).

* Generating the new items UUID
            TRY.
                lv_item_uuid = cl_system_uuid=>if_system_uuid_static~create_uuid_x16( ).
              CATCH cx_uuid_error INTO DATA(lvitmexc).
            ENDTRY.

            ls_accitm_t-item_uuid = lv_item_uuid.
            ls_accitm_t-con_uuid = lv_con_uuid.
            ls_accitm_t-belnr = lv_newdocno.
            ls_accitm_t-gjahr = sy-datum+0(4).

            APPEND VALUE #( %cid = ls_values-%cid_ref
                            %is_draft = if_abap_behv=>mk-on
                            item_uuid = lv_item_uuid
                          )
                          TO mapped-accountinglines.

*            APPEND VALUE #( %cid = ls_values-%cid_ref
*                            %is_draft = if_abap_behv=>mk-on
*                            item_uuid = lv_item_uuid
*                          )
*                          TO reported-accountinglines.

            APPEND ls_accitm_t TO lhc_buffer=>mt_acc_itm.

          ENDLOOP.

        ENDIF.

      ENDIF.

    ENDIF.

  ENDMETHOD.

ENDCLASS.

CLASS lhc_accountinglines DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE accountinglines.

    METHODS update FOR MODIFY
      IMPORTING line_items FOR UPDATE accountinglines.

    METHODS read FOR READ
      IMPORTING keys FOR READ accountinglines RESULT result.

    METHODS rba_header FOR READ
      IMPORTING keys_rba FOR READ accountinglines\_header FULL result_requested RESULT result LINK association_links.

ENDCLASS.

CLASS lhc_accountinglines IMPLEMENTATION.

  METHOD delete.

  ENDMETHOD.

  METHOD update.

* This method will be called if we make any changes to line item values
* and then save the entry
    DATA: ls_lines_output TYPE zst7accitm_dftum.

    LOOP AT line_items INTO DATA(line_data_wa).
      MOVE-CORRESPONDING line_data_wa TO ls_lines_output.
      APPEND ls_lines_output TO lhc_buffer=>mt_acc_itm.
    ENDLOOP.

  ENDMETHOD.

  METHOD read.

  ENDMETHOD.

  METHOD rba_header.

  ENDMETHOD.

ENDCLASS.

CLASS lsc_zst7_acchdr_root_pool_umg_ DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS check_before_save REDEFINITION.

    METHODS finalize          REDEFINITION.

    METHODS save              REDEFINITION.

ENDCLASS.

CLASS lsc_zst7_acchdr_root_pool_umg_ IMPLEMENTATION.

  METHOD check_before_save.
    DATA(lv_idx) = abap_true.
  ENDMETHOD.

  METHOD finalize.
    DATA(lv_idx) = abap_true.
  ENDMETHOD.

  METHOD save.

* For saving the data to the Z tables, we need to create a FM/BAPI or Class method
    CALL FUNCTION 'ZST7_ACCDATA_UPDATE'
      TABLES
        lt_acchdr = lhc_buffer=>mt_acc_hdr
        lt_accitm = lhc_buffer=>mt_acc_itm.

  ENDMETHOD.

ENDCLASS.
