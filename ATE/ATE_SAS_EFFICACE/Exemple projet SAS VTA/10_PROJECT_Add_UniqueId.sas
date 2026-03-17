/*=============================================================================*/
/*-- Program name : 10_PROJECT_Add_UniqueId.sas                              --*/
/*-- Project name : PROJECT                                                  --*/                            
/*-- Author(s) :                  - SAS                                      --*/
/*-- Update date :  11/09/2025                                               --*/
/*-- Creation date : 11/09/2025                                              --*/                            
/*-- Update date :  11/09/2025                                               --*/
/*-- Description : Add a unique id variable to a dataset                     --*/
/*-- Prerequisites : 01_PROJECT_Init_Params                                  --*/
/*=============================================================================*/

/* Session opening */
cas Sess_Id sessopts=(caslib=casuser timeout=3600 locale="en_US" metrics=true);

/* Libname creation for caslib */
libname &caslib_lib cas caslib=&caslib_name;

/*------------------------------------*/
/* TO BE CUSTOMIZED FOR YOUR DATA !!! */
/*------------------------------------*/
/* Specifies the input data */
%let input_table="MY_INPUT_DATA";

/* Specifies the output data */
%let output_table="MY_INPUT_DATA_ID";

/* Specifies the temporaray data */
%let output_table_tmp="MY_INPUT_DATA_TMP";

/*--------------------------------*/
/* Delete output tables if needed */
/*--------------------------------*/
proc cas;
 session Sess_Id; 
 table.tableexists result=r /  caslib=&caslib_name name="MY_INPUT_DATA_ID"; 
 print r;
 if r gt 0 then do;
  table.droptable / caslib=&caslib_name name="MY_INPUT_DATA_ID";
 end;
quit;

proc casutil;
   deletesource casdata="MY_INPUT_DATA_ID.sashdat" incaslib=&caslib_name quiet;
run;

/* Generate the unique id using a SAS CAS Action */
proc cas;
  loadactionset "textManagement";
  textManagement.generateIds;
  param
    casOut={name=&output_table_tmp caslib=&caslib_name, replace=TRUE}
    id="Unique_Id_N" /* num */
    table={name=&input_table caslib=&caslib_name}
  ;
run;

/* Change Unique Id format for later use */
data %sysfunc(dequote(&caslib_name)).%sysfunc(dequote(&output_table))(drop=Unique_Id_N);
    set %sysfunc(dequote(&caslib_name)).%sysfunc(dequote(&output_table_tmp));
    /* Specifies the unique id variable name to create*/
    Unique_Id = PUT(Unique_Id_N, 8.); /* change to character */
run;

/* Promotion of the results dataset */
proc casutil;
    promote casdata=&output_table casout=&output_table
        incaslib=&caslib_name outcaslib=&caslib_name;
    /* save incaslib=&caslib_name casdata=&output_table outcaslib=&caslib_name casout=&output_table replace;*/
quit;

/* Drop temporary tables */
proc cas;
	session Sess_Id;
	table.droptable / caslib=&caslib_name name=&output_table_tmp quiet=true;
quit;

/* Terminate the CAS session */
cas Sess_Id terminate;
