/* Pour charger les données dans une CASlib depuis une librarie SAS */

%macro upload_to_cas(librairie_source, table_source, librairie_cible, table_cible);
	cas session1;
	caslib _all_ assign;

	proc casutil incaslib="&librairie_cible." outcaslib="&librairie_cible.";
		DROPTABLE CASDATA="&table_cible." quiet;
		load data=&librairie_source..&table_source. casout="&table_cible.";
		promote casdata="&table_cible.";
		save CASDATA="&table_cible." CASOUT="&table_cible." replace;
	quit;

	/* cas session1 terminate; */
%mend upload_to_cas;

%upload_to_cas(sashelp, air, casuser, air_test);
