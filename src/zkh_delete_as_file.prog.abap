*&---------------------------------------------------------------------*
*& Report ZKH_DELETE_AS_FILE
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zkh_delete_as_file.


SELECTION-SCREEN BEGIN OF BLOCK B1 WITH FRAME TITLE TEXT-001.
PARAMETERS: p_path TYPE epsf-epsdirnam,
            p_days TYPE i,
            p_test TYPE abap_bool AS CHECKBOX.
SELECTION-SCREEN END OF BLOCK B1.

START-OF-SELECTION.

DATA: lo_file_handler TYPE REF TO zkh_file_handler.


CREATE OBJECT lo_file_handler.

CALL METHOD lo_file_handler->process_files
  EXPORTING
    iv_path = p_path
    iv_days = p_days
    iv_test = p_test.
