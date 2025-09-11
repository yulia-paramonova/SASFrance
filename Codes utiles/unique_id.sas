/* Simple */
data casuser.EN_TEXTDATA;
    set casuser.EN_TEXTDATA_TMP;
    Unique_Id = strip(put(_threadid_,8.))||'_'||strip(Put(_n_,8.));
run; 


/* Text Analytics  */
/* Specifies the unique id variable name to create*/
/* %let uid_name_base="Unique_Id"; */

proc cas;
  loadactionset "textManagement";
  textManagement.generateIds;
  param
    casOut={name=&output_table_tmp caslib=&caslib_name, replace=TRUE}
    id="Unique_Id_N"
    table={name=&input_table caslib=&caslib_name}
  ;
run;

data %sysfunc(dequote(&caslib_name)).%sysfunc(dequote(&output_table))(drop=Unique_Id_N);
    set %sysfunc(dequote(&caslib_name)).%sysfunc(dequote(&output_table_tmp));
    Unique_Id = PUT(Unique_Id_N, 8.);
run;
