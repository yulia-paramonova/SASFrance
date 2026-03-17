/*=============================================================================*/
/*-- Program name : 01_PROJECT_Init_Params.sas                               --*/
/*-- Project name : PROJECT                                                  --*/                            
/*-- Author(s) :                  - SAS                                      --*/
/*-- Update date :  11/09/2025                                               --*/
/*-- Creation date : 11/09/2025                                              --*/                            
/*-- Update date :  11/09/2025                                               --*/
/*-- Description : parameters initialization                                 --*/
/*-- Prerequisites : none                                                    --*/
/*=============================================================================*/

/*
 * SAS libraries for the programs' output.
 * !!!!! TO BE CUSTOMIZED FOR TARGET ENVIRONMENT !!!!!
 */
%let caslib_name="MYCASLIB_HERE"; 
%let caslib_lib=MYCASLIB_HERE;

/* CAS server options */
option castimeout=3600; /* time out for the session in seconds */
options casdatalimit= all;

/* 
 * NLP scoring options for concept matching in SAS Visual Text Analytics: BEST, ALL or LONGEST. 
 */
%let match_type="ALL";

/**
 * For special characters treatment.
 */
options VALIDVARNAME=ANY;

