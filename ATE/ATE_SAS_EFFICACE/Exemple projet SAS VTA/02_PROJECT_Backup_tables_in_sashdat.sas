/*=============================================================================*/
/*-- Program name : 02_PROJECT_Backup_tables.sas                             --*/
/*-- Project name : PROJECT                                                  --*/                            
/*-- Author(s) :                                                             --*/
/*-- Update date : 28/07/2025                                                --*/
/*-- Creation date : 28/07/2025                                              --*/                            
/*-- Description : backup tables in sashdat for future reload                --*/
/*-- Prerequisites : 01_PROJECT_Init_Params.sas                              --*/
/*=============================================================================*/

cas backup;

/* Libname creation for the caslib defined in 01_Climate_Init_Params.sas */
libname &caslib_lib cas caslib=&caslib_name;

/* Backup of sashdat datasets */
%macro save_hdat(dsname,dslib);
proc casutil;
	save casdata="&dsname" 
         incaslib="&dslib" 
         outcaslib="&dslib" 
		 casout="&dsname" 
replace;
run;
%mend;

/* Save the in-memory datasets into sashdat format */
%save_hdat(dsname=PROJECT_CONCEPTS_VA,dslib=CASUSER);
%save_hdat(dsname=PROJECT_CATEGS_OUT_TX,dslib=CASUSER);

data _null_;
	time=sleep(10, 1);
	/* sec */
run;

/* Terminate the session */
cas backup terminate;