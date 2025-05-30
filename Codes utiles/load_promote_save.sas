/* Pour charger les données dans une CASlib depuis une librarie SAS */

%macro upload_to_cas(librairie_source, table_source, librairie_cible, table_cible);
	cas session_upload_to_cas;
	libname casuser cas caslib="&librairie_cible";

	proc casutil incaslib="&librairie_cible." outcaslib="&librairie_cible.";
		DROPTABLE CASDATA="&table_cible." quiet;
		load data=&librairie_source..&table_source. casout="&table_cible.";
		promote casdata="&table_cible.";
		save CASDATA="&table_cible." CASOUT="&table_cible." replace;
	quit;

	cas session_upload_to_cas terminate;
%mend upload_to_cas;

%upload_to_cas(librairie_source=sashelp, table_source=air, librairie_cible=casuser, table_cible=air_test);
