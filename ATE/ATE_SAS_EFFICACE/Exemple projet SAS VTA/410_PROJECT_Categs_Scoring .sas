/*=============================================================================*/
/*-- Program name : 410_PROJECT_Categs_Scoring.sas                           --*/
/*-- Project name : PROJECT                                                  --*/                            
/*-- Author(s) :                  - SAS                                      --*/
/*-- Update date :  11/09/2025                                               --*/
/*-- Creation date : 11/09/2025                                              --*/                            
/*-- Description : NLP scoring : categories extraction                       --*/
/*-- Prerequisites : 01_PROJECT_Init_Params.sas                              --*/
/*=============================================================================*/

/* Session opening */
cas PROJECT_Categ sessopts=(caslib=casuser timeout=3600 locale="en_US" metrics=true);

/* Libname creation for caslib defined in 01_Climate_Init_Params.sas */
libname &caslib_lib cas caslib=&caslib_name;

/*--------------------------------*/
/* Delete output tables if needed */
/*--------------------------------*/
proc cas;
 session PROJECT_Categ; 
 table.tableexists result=r /  caslib=&caslib_name name="PROJECT_CATEGS_OUT_MODEL"; 
 print r;
 if r gt 0 then do;
  table.droptable / caslib=&caslib_name name="PROJECT_CATEGS_OUT_MODEL";
 end;
quit;

proc casutil;
   deletesource casdata="PROJECT_CATEGS_OUT_MODEL.sashdat" incaslib=&caslib_name quiet;
run;

proc cas;
 session PROJECT_Categ; 
 table.tableexists result=r /  caslib=&caslib_name name="PROJECT_CATEGS_OUT_TX"; 
 print r;
 if r gt 0 then do;
  table.droptable / caslib=&caslib_name name="PROJECT_CATEGS_OUT_TX";
 end;
quit;

proc casutil;
   deletesource casdata="PROJECT_CATEGS_OUT_TX.sashdat" incaslib=&caslib_name quiet;
run;

/*-------------------------*/
/* VTA Scoring             */
/*-------------------------*/

/* specifies the CAS table you would like to score. You must modify the value to provide the name of the input table, such as "MyTable". Do not include an extension. */
%let input_table_name = "PROJECT_INPUT_DOCS";

/* specifies the column in the CAS table that contains a unique document identifier. You must modify the value to provide the name of the document identifer column in the table. */
%let key_column = "Unique_id";

/* specifies the column in the CAS table that contains the text data to score. You must modify the value to provide the name of the text column in the table. */
%let document_column = "text_variable";

/* specfies the categories output CAS table to produce */
%let output_categories_table_name = "categ_out_tx";

/* specifies the matches output CAS table to produce */
%let output_matches_table_name = "categ_out_match";

/* specifies the modeling ready output CAS table to produce */
%let output_modeling_ready_table_name = "categ_out_model";

/* specifies the CAS library information for the mco binary table. This should be set automatically to the CAS library for the associated SAS Visual Text Analytics project. */
/* TO BE COPIED FROM VTA CATEG NODE RESULTS */
%let mco_binary_caslib = "Analytics_Project_XXXXXX";

/* specifies the CAS table name of the mco binary table. This should be set automatically to the Categories node model table for the associated SAS Visual Text Analytics project. */
/* TO BE COPIED FROM VTA CATEG NODE RESULTS */
%let mco_binary_table_name = "XXXXX_CATEGORY_BINARY";

/* calls the scoring action */
proc cas;
    session PROJECT_Categ;
    loadactionset "textRuleScore";

    action applyCategory;
        param
            model={caslib=&mco_binary_caslib, name=&mco_binary_table_name}
            table={caslib=&caslib_name, name=&input_table_name}
            docId=&key_column
            text=&document_column
            casOut={caslib=&caslib_name, name=&output_categories_table_name, replace=TRUE}
            matchOut={caslib=&caslib_name, name=&output_matches_table_name, replace=TRUE}
            modelOut={caslib=&caslib_name, name=&output_modeling_ready_table_name, replace=TRUE}
        ;
    run;
quit;

/* data _null_;
	time=sleep(10, 1);
run;
 */
/*----------------------------*/
/* Categories Post-Processing */
/*----------------------------*/
/* Transsactional output : join with origin data */
proc fedsql sessref=PROJECT_Categ;
	create table %sysfunc(dequote(&caslib_name)).PROJECT_CATEGS_OUT_MODEL {options replace=true} as 
	select  t1.category_1 as asset_class,
			t1.category_2 as hazard,
			t1.category_3 as materiality_threshold,
			t1.category_4 as methodology,
			t1.category_5 as data_source,
			t2.*
	from %sysfunc(dequote(&caslib_name)).%sysfunc(dequote(&output_modeling_ready_table_name)) t1 left join %sysfunc(dequote(&caslib_name)).%sysfunc(dequote(&input_table_name)) t2
	on upcase(t1.chunk_id)=upcase(t2.chunk_id);
quit;

/* Promotion of the results dataset */
proc casutil;
	promote casdata="PROJECT_CATEGS_OUT_MODEL" casout="PROJECT_CATEGS_OUT_MODEL" incaslib=&caslib_name outcaslib=&caslib_name;
    save incaslib=&caslib_name casdata="PROJECT_CATEGS_OUT_MODEL" outcaslib=&caslib_name casout="PROJECT_CATEGS_OUT_MODEL"  replace;
quit;

/* Model ready output : join with origin data */
proc fedsql sessref=PROJECT_Categ;
	create table %sysfunc(dequote(&caslib_name)).PROJECT_CATEGS_OUT_TX {options replace=true} as 
	select  t1._category_,
			t1._score_,
            t1._result_id_,
			t2.*
	from %sysfunc(dequote(&caslib_name)).%sysfunc(dequote(&output_categories_table_name)) t1 left join %sysfunc(dequote(&caslib_name)).%sysfunc(dequote(&input_table_name)) t2
	on upcase(t1.chunk_id)=upcase(t2.chunk_id);
quit;

/* Promotion of the results dataset */
proc casutil;
	promote casdata="PROJECT_CATEGS_OUT_TX" casout="PROJECT_CATEGS_OUT_TX" incaslib=&caslib_name outcaslib=&caslib_name;
    save incaslib=&caslib_name casdata="PROJECT_CATEGS_OUT_TX" outcaslib=&caslib_name casout="PROJECT_CATEGS_OUT_TX"  replace;
quit;

/* Drop temporary tables */
proc cas;
	session PROJECT_Categ;
	table.droptable / caslib=&caslib_name name="categ_out_tx" quiet=true;
	table.droptable / caslib=&caslib_name name="categ_out_match" quiet=true;
	table.droptable / caslib=&caslib_name name="categ_out_model" quiet=true;
quit;

/* Terminate the CAS session */
cas PROJECT_Categ terminate; 