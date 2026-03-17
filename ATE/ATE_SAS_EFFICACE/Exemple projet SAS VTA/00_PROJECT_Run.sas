/*=============================================================================*/
/*-- Program name : 00_PROJECT_Run.sas                                       --*/
/*-- Project name : PROJECT                                                  --*/                            
/*-- Author(s) :                                                             --*/
/*-- Update date : 15/09/2025                                                --*/
/*-- Creation date : 15/09/2025                                              --*/                            
/*-- Description : main execution of the project                             --*/
/*=============================================================================*/

/* Init param : TO BE CUSTOMIZED FOR TARGET ENVIRONMENT */
filename myfldr2 filesrvc folderPath = '/Users/YOUR_ACCOUNT_HERE/My Folder/VERBATIM';

/*-------------------------------------*/
/* Parameters initialization           */
/*-------------------------------------*/
%include myfldr2 ('01_PROJECT_Init_Params.sas') / source2;

/*--------------------------------------*/
/* NLP-VTA Scoring                      */   
/*--------------------------------------*/

/* VTA Concepts Scoring */
%include myfldr2 ("320_PROJECT_Concepts_Scoring.sas") / source2;

/* VTA Categories Scoring */
%include myfldr2 ("410_PROJECT_Categs_Scoring.sas") / source2;

/*--------------------------*/
/* Backup physical datasets */
/*--------------------------*/
%include myfldr2 ("02_PROJECT_Backup_Tables_in_sashdat.sas") / source2;
%include myfldr2 ("03_PROJECT_Backup_Tables_in_files.sas") / source2;

