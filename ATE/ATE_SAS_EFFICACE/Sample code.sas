/* Parquet import load promote : all VXPF files */
/* Region: Read-me */

    
/***************************************************************************
        to do: 
        recuperer les tables depuis git, 
        charger les données en mémoire, 
        changer les formats dates si necessaire, 
        promovoir et sauvegarder les tables dans CASUSER

        INPUT (in GIT cloned to &_USERHOME):
            /VXPF/data/VXPF_ANALYSIS_TABLE.parquet
            /VXPF/data/VXPF_PRIX_HEBDO.parquet
            /VXPF/data/VXPF_VENTES_HEBDO.parquet
            /VXPF/data/calendar.csv
        OUTPUT:
            casuser.M5_CALENDAR
            casuser.VXPF_VENTES_HEBDO
            casuser.VXPF_PRIX_HEBDO
            CASUSER.VXPF_ANALYSIS_TABLE

****************************************************************************/


/* endregion */

/* Region: Import files */
cas filesimport;
%let workinglib= lib="casuser"; *added after proc cas;

/* Create VXPF folder if doesn't exist */
options dlcreatedir;
libname newdir "&_USERHOME/VXPF";
libname newdir clear;

/* !!!!!!Manually delete VXPF folder and its contents if exist!!!! */

/* download parquet files from git(=clone) to a new VXPF directory */
data _null_; *clone files from git to the new folder;
    rc = git_clone (                  /*1*/
     'https://github.com/yulia-paramonova/Viya_Experience_Forecasting.git',                     /*2*/
     "&_USERHOME/VXPF");             /*3*/
    put rc=;
run;

/* endregion: Import files */

/* Region: Load files in memory, promote and save */
proc cas; *add a new temporary caslib that points to VXPF files;
y="VXPF";
	table.queryCaslib result=r / caslib=y;
	if r.VXPF=TRUE then do;	
		TABLE.DROPCASLIB / caslib=y;
	end;
    table.addCaslib result=r / 
         name=y,
			dataSource={srcType="PATH"}
         path="&_USERHOME/VXPF/data",
         description="Newly added caslib for VXPF _USERHOME/VXPF/data";
quit;

proc cas;
&workinglib;
	table.fileInfo result=rt/ caslib="VXPF";
	filelist_t=rt.fileInfo[, {"Name"}].where(Name contains ".parquet");
	filelist=filelist_t[,"Name"];

    do x over filelist;
        *Import tblnm.parquet;
        table.loadTable / caslib="VXPF", path=x, importOptions={filetype="parquet"}, 
                            casout={name=scan(x, 1), caslib=lib, replace=True};
        *Apply format to date;
        table.altertable / columns={{format="yymmdd10.", name="date"}}, name=scan(x, 1), caslib=lib;
        *Save for easy load if session restart;
        table.save / caslib=lib name=scan(x, 1)||".sashdat" table={name=scan(x, 1), caslib=lib} replace=true;
        *Promote to see through all sessions;
        table.promote / name=scan(x, 1), caslib=lib, target=scan(x, 1), targetLib=lib;
	end;    
quit; 

proc cas;
    &workinglib;
            table.loadTable /   caslib="VXPF", path="calendar.csv",                                        
                importOptions={filetype="csv", getNames=True},
                casout={name="M5_CALENDAR_", caslib=lib, replace=True};

        *Change Date from character to Numeric+format date;
            datastep.runcode / code="DATA casuser.M5_CALENDAR (drop=date_);
                                        FORMAT date yymmdd10.;/*mmddyy10.*/
                                        SET CASUSER.M5_CALENDAR_ (rename=(date=date_));
                                        date=input(Date_, yymmdd10.);/*mmddyy10.*/
                                    RUN;";
            table.promote / name="M5_CALENDAR", caslib=lib, target="M5_CALENDAR", targetLib=lib;
            table.save / caslib=lib name="M5_CALENDAR"||".sashdat" table={name="M5_CALENDAR", caslib=lib} replace=true;
quit; 

/* endregion: Load files in memory, promote and save */
 
/* Region: Clean up */
proc cas; *drop temp caslib VXPF;
    table.dropCaslib / caslib="VXPF", deleteDirectory="NONE", quiet= FALSE;
quit; 

/* terminate import and load session */
cas filesimport terminate;

/* endregion: Clean up */