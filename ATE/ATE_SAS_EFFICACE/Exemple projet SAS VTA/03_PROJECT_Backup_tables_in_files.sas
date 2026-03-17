/*=============================================================================*/
/*-- Program name : 03_PROJECT_Backup_tables_in_files.sas                    --*/
/*-- Project name : PROJECT                                                  --*/                            
/*-- Author(s) :                                                             --*/
/*-- Update date : 28/07/2025                                                --*/
/*-- Creation date : 28/07/2025                                              --*/                            
/*-- Description : backup sashdat tables in the files server                 --*/
/*-- Prerequisites : 01_PROJECT_Init_Params.sas                              --*/
/*=============================================================================*/

/* Session creation */
cas saveallh sessopts=(caslib=CASUSER timeout=3600 metrics=true);

/* Libname creation for the caslib defined in 01_PROJECT_Init_Params.sas */
libname &caslib_lib cas caslib=&caslib_name;

/* Location to backup the sashdat tables : TO BE CUSTOMIZED FOR TARGET ENVIRONMENT */
caslib CIBLE datasource=(srctype="path") path="&_USERHOME";

proc cas;
    table.fileinfo result=listfiles / caslib=&caslib_name;
    do row over listfiles.fileinfo[1:listfiles.fileinfo.nrows];
        if (index(row.Name,'PROJECT_')<>0) then do;
            datafile=row.Name;
            tablename=scan(row.Name,1);
/*             table.dropTable / caslib=&caslib_name name=tablename quiet=true; */
/*             table.loadTable / casout={caslib=&caslib_name name=tablename promote=true} caslib=&caslib_name path=datafile; */
			table.save / caslib="CIBLE" name=tablename||".sashdat" table={name=tablename, caslib=&caslib_name} replace=true;
;
        end;
    end;
quit;

/* Terminate the session*/
cas saveallh terminate;
