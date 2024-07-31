CLASS zkh_file_handler DEFINITION PUBLIC.
  PUBLIC SECTION.
    METHODS:
      process_files IMPORTING iv_path TYPE epsf-epsdirnam
                              iv_days TYPE i
                              iv_test TYPE abap_bool.

  PRIVATE SECTION.
    TYPES:
      tt_file_list TYPE STANDARD TABLE OF epsfili WITH EMPTY KEY.

    METHODS:
      retrieve_file_list IMPORTING iv_path             TYPE epsf-epsdirnam
                         RETURNING VALUE(rt_file_list) TYPE tt_file_list,
      retrieve_file_attributes IMPORTING iv_file_name         TYPE epsf-epsfilnam
                                         iv_path              TYPE epsf-epsdirnam
                               RETURNING VALUE(rv_file_mtime) TYPE string,
      remove_file IMPORTING iv_file_name TYPE epsf-epsfilnam
                            iv_path      TYPE epsf-epsdirnam,
      handle_file IMPORTING iv_file_entry TYPE epsfili
                            iv_path       TYPE epsf-epsdirnam
                            iv_days       TYPE i
                            iv_test       TYPE abap_bool.
ENDCLASS.



CLASS ZKH_FILE_HANDLER IMPLEMENTATION.


  METHOD process_files.
    DATA: lt_file_list  TYPE tt_file_list,
          ls_file_entry TYPE epsfili.

    lt_file_list = retrieve_file_list( iv_path ).

    LOOP AT lt_file_list INTO ls_file_entry.
      handle_file(
        iv_file_entry = ls_file_entry
        iv_path       = iv_path
        iv_days       = iv_days
        iv_test       = iv_test
      ).
    ENDLOOP.
  ENDMETHOD.


  METHOD retrieve_file_list.
    CALL FUNCTION 'EPS_GET_DIRECTORY_LISTING'
      EXPORTING
        dir_name = iv_path
      TABLES
        dir_list = rt_file_list
      EXCEPTIONS
        OTHERS   = 8.
    IF sy-subrc <> 0.
      WRITE: / 'Error getting directory listing.'.
      CLEAR rt_file_list.
    ENDIF.
  ENDMETHOD.


  METHOD retrieve_file_attributes.
    CALL FUNCTION 'EPS_GET_FILE_ATTRIBUTES'
      EXPORTING
        file_name  = iv_file_name
        dir_name   = iv_path
      IMPORTING
        file_mtime = rv_file_mtime
      EXCEPTIONS
        OTHERS     = 3.
    IF sy-subrc <> 0.
      WRITE: / 'Error getting file attributes for', iv_file_name.
      CLEAR rv_file_mtime.
    ENDIF.
  ENDMETHOD.


  METHOD remove_file.
    CALL FUNCTION 'EPS_DELETE_FILE'
      EXPORTING
        file_name = iv_file_name
        dir_name  = iv_path
      EXCEPTIONS
        OTHERS    = 2.
    IF sy-subrc = 0.
      WRITE: / 'File deleted:', iv_file_name.
    ELSE.
      WRITE: / 'Error deleting file:', iv_file_name.
    ENDIF.
  ENDMETHOD.


  METHOD handle_file.
    DATA: lv_file_mtime     TYPE string,
          lv_unix_time      TYPE i,
          lv_timestamp_msec TYPE string,
          lv_date           TYPE d,
          lv_current_date   TYPE d,
          lv_days_diff      TYPE i.

    lv_current_date = sy-datum.

    lv_file_mtime = retrieve_file_attributes( iv_file_name = iv_file_entry-name
                                              iv_path      = iv_path ).

    IF lv_file_mtime IS INITIAL.
      RETURN.
    ENDIF.

    " Convert file_mtime (string) to integer Unix time
    lv_unix_time = lv_file_mtime.

    " Convert Unix time to milliseconds
    lv_timestamp_msec = lv_unix_time * 1000.

    CALL METHOD cl_pco_utility=>convert_java_timestamp_to_abap
      EXPORTING
        iv_timestamp = lv_timestamp_msec
      IMPORTING
        ev_date      = lv_date.

    lv_days_diff = lv_current_date - lv_date.

    IF lv_days_diff > iv_days.
      IF iv_test = abap_false.
        remove_file( iv_file_name = iv_file_entry-name iv_path = iv_path ).
      ELSE.
        WRITE: / 'Test mode: File would be deleted:', iv_file_entry-name.
      ENDIF.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
