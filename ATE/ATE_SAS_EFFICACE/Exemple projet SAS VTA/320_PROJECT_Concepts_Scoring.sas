/*=============================================================================*/
/*-- Program name : 320_PROJECT_Concepts_Scoring.sas                         --*/
/*-- Project name : PROJECT                                                  --*/                            
/*-- Author(s) :                  - SAS                                      --*/
/*-- Update date :  11/09/2025                                               --*/
/*-- Creation date : 11/09/2025                                              --*/                            
/*-- Description : NLP scoring : concepts extraction                         --*/
/*-- Prerequisites : 01_PROJECT_Init_Params.sas                              --*/
/*=============================================================================*/

/* Session opening */
cas PROJECT_Concept sessopts=(caslib=casuser timeout=3600 locale="en_US" metrics=true);

/* Libname creation for caslib defined in 01_PROJECT_Init_Params.sas */
libname &caslib_lib cas caslib=&caslib_name;

/**
 * For special characters
 */
options VALIDVARNAME=ANY;

/*--------------------------------*/
/* Delete output tables if needed */
/*--------------------------------*/
proc cas;
 session PROJECT_Concept; 
 table.tableexists result=r /  caslib=&caslib_name name="PROJECT_CONCEPTS_OUT_TX"; 
 print r;
 if r gt 0 then do;
  table.droptable / caslib=&caslib_name name="PROJECT_CONCEPTS_OUT_TX";
 end;
quit;

proc casutil;
   deletesource casdata="PROJECT_CONCEPTS_OUT_TX.sashdat" incaslib=&caslib_name quiet;
run;

proc cas;
 session PROJECT_Concept; 
 table.tableexists result=r /  caslib=&caslib_name name="PROJECT_FACTS_OUT_TX"; 
 print r;
 if r gt 0 then do;
  table.droptable / caslib=&caslib_name name="PROJECT_FACTS_OUT_TX";
 end;
quit;

proc casutil;
   deletesource casdata="PROJECT_FACTS_OUT_TX.sashdat" incaslib=&caslib_name quiet;
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

/* specifies the concepts output CAS table to produce */
%let output_concepts_table_name = "out_concepts_DOCS";

/* specifies the facts output CAS table to produce */
%let output_facts_table_name = "out_facts_DOCS";

/* specifies the CAS library information for the LITI binary table. This should be set automatically to the CAS library for the associated SAS Visual Text Analytics project. */
/* TO BE COPIED FROM VTA CONCEPT NODE RESULTS */
%let liti_binary_caslib = "Analytics_Project_XXXXXXX";

/* specifies the name of the LITI binary table. This should be set automatically to the Concepts node model table for the associated SAS Visual Text Analytics project. */
/* TO BE COPIED FROM VTA CONCEPT NODE RESULTS */
%let liti_binary_table_name = "XXXXXXX_CONCEPT_BINARY";

/* calls the scoring action */
proc cas;
  /*   session PROJECT_Concept;*/
   loadactionset "textRuleScore";

    action applyConcept;
        param
            model={caslib=&liti_binary_caslib, name=&liti_binary_table_name}
            table={caslib=&caslib_name, name=&input_table_name}
        	matchType=&match_type.     
		    docId=&key_column
            text=&document_column
            casOut={caslib=&caslib_name, name=&output_concepts_table_name, replace=TRUE}
            factOut={caslib=&caslib_name, name=&output_facts_table_name, replace=TRUE}
        ;
    run;
quit;

data _null_;
	time=sleep(10, 1);
	/* sec */
run;

/*--------------------------*/
/* Concepts Post-Processing */
/*--------------------------*/

/* Deduplicate preparation */
data %sysfunc(dequote(&caslib_name)).EXTRACT_concepts_DOCS;
	set %sysfunc(dequote(&caslib_name)).%sysfunc(dequote(&output_concepts_table_name));
/* Add filter here : for instance to filter the predefined concepts */
/* 	where (_path_ contains 'MY_CONCEPT'); */

	length _matchlength_ 8.; 					/* Length of the matching result */
	_matchlength_ = -1*length(_match_text_); 	/* Multiply by -1 for the orderBy in CAS */

	length pk_concept $200.; 					/* Deduplicate key */
 	pk_concept = strip(chunk_id) || '_' || _concept_ ; 
run;

/* proc casutil;
	promote casdata="EXTRACT_concepts_DOCS" casout="EXTRACT_concepts_DOCS" incaslib=&caslib_name outcaslib=&caslib_name;
quit; */

/* Deduplicate : keep the longest match by concept type */
proc cas;
    session PROJECT_Concept;
	loadactionset "deduplication";
	action deduplication.deduplicate / table={name="EXTRACT_concepts_DOCS" caslib=&caslib_name, 
		groupBy={name="pk_concept"}, orderBy={name="_matchlength_"}}, 
		casOut={name="EXTRACT_concepts_DOCS_dedup" caslib=&caslib_name replace=true}, 
		noDuplicateKeys=true, dupOut={name='EXTRACT_concepts_DOCS_dup' caslib=&caslib_name replace=true};
run;

/* Keep only useful variables */
proc cas; 
	table.alterTable  /
	caslib=&caslib_name,
	keep={"chunk_id","_path_", "_concept_", "_match_text_", "_matchlength_", "pk_concept"},
	name="EXTRACT_concepts_DOCS_dedup";
run;

/* Split _path_ by level and keep the hierarchy of concepts */
data %sysfunc(dequote(&caslib_name)).CONCEPTS_DOCS_NIV(drop=_path_ _concept_ _match_text_ _matchlength_ pk_concept);
	set %sysfunc(dequote(&caslib_name)).EXTRACT_concepts_DOCS_dedup;

	AUTO_Nom_Concept=_concept_;
	AUTO_Valeur_Concept= UPCASE(_match_text_);
    /* Number of levels depends on your VTA project */
	AUTO_Concept_N1 = scan(_path_,1,"/");
	AUTO_Concept_N2 = scan(_path_,2,"/");
	AUTO_Concept_N3 = scan(_path_,3,"/");
run;

/* Join with origin data */
proc fedsql sessref=PROJECT_Concept;
	create table %sysfunc(dequote(&caslib_name)).PROJECT_CONCEPTS_VA {options replace=true} as 
	select  t1.AUTO_Nom_Concept,
			t1.AUTO_Concept_N1,
			t1.AUTO_Concept_N2,
			t1.AUTO_Concept_N3,
			t1.AUTO_Valeur_Concept,
			t2.*
	from %sysfunc(dequote(&caslib_name)).CONCEPTS_DOCS_NIV t1 left join %sysfunc(dequote(&caslib_name)).%sysfunc(dequote(&input_table_name)) t2
	on upcase(t1.chunk_id)=upcase(t2.chunk_id);
quit;

/* Promotion of the results dataset */
proc casutil;
	promote casdata="PROJECT_CONCEPTS_VA" casout="PROJECT_CONCEPTS_VA" incaslib=&caslib_name outcaslib=&caslib_name;
    save incaslib=&caslib_name casdata="PROJECT_CONCEPTS_VA" outcaslib=&caslib_name casout="PROJECT_CONCEPTS_VA"  replace;
quit;

/* Drop temporary tables */
proc cas;
	session PROJECT_Concept;
	table.droptable / caslib=&caslib_name name="CONCEPTS_DOCS_NIV" quiet=true;
	table.droptable / caslib=&caslib_name name="PROJECT_CONC_VA_TMP" quiet=true;
	table.droptable / caslib=&caslib_name name="EXTRACT_CONCEPTS_DOCS" quiet=true;
	table.droptable / caslib=&caslib_name name="EXTRACT_CONCEPTS_DOCS_DEDUP" quiet=true;
	table.droptable / caslib=&caslib_name name="EXTRACT_CONCEPTS_DOCS_DUP" quiet=true;
	table.droptable / caslib=&caslib_name name="OUT_CONCEPTS_DOCS" quiet=true;
	table.droptable / caslib=&caslib_name name="OUT_FACTS_DOCS" quiet=true;
quit;

/*-----------------------------*/
/* TODO FACTS post-processing  */
/*-----------------------------*/

/* Terminate the CAS session */
cas PROJECT_Concept terminate; 