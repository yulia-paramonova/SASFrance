/* Pour charger les données dans une CASlib depuis une librarie SAS */

%macro upload_to_cas(in_lib, in_table, out_lib, out_table);
	cas session1;
	caslib _all_ assign;

	proc casutil incaslib="&out_lib." outcaslib="&out_lib.";
		DROPTABLE CASDATA="&out_table." quiet;
		load data=&in_lib..&in_table. casout="&out_table.";
		promote casdata="&out_table.";
		save CASDATA="&out_table." CASOUT="&out_table." replace;
	quit;

	/* cas session1 terminate; */
%mend upload_to_cas;

%upload_to_cas(sashelp, air, casuser, air_test);
