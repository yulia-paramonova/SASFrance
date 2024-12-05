/* Job SAS qui permet de recuperer la liste des rapports auxquels j'ai acces */

cas jobReport;

libname CASUSER cas caslib="CASUSER"; 

%let BASE_URL = %sysfunc(getoption(servicesbaseurl));
%put &BASE_URL;
%let report_url_1 = %substr(&BASE_URL,1,%sysfunc(FIND(&BASE_URL, :,-999))-1);
%put &=report_url_1;

filename outResp temp;

proc http method='GET'
	url="&BASE_URL./reports/reports?limit=1000"
	oauth_bearer=sas_services
	out=outResp;
	headers 'Accept'='application/vnd.sas.collection+json, application/json, application/vnd.sas.error+json';
    debug level=3;
quit;

LIBNAME outResp clear;
LIBNAME outResp json;
	
/* Suppression si la table de sortie existe déjà */
proc cas;
	table.droptable / caslib="CASUSER" name="REPORTS_FOR_ME" quiet=true;
quit;

data CASUSER.REPORTS_FOR_ME(promote=yes);
	set outResp.items(keep=id name createdby modifiedby description);
	url2=cat("&report_url_1./links/resources/report?uri=/reports/reports/",id);	
run;

cas jobReport terminate;

data _null_;
    file print;
    put "😊 Exécution terminée ✅";
run;
