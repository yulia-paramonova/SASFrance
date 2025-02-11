/* PART 1 : Extraction de 'dudate' (une date commençant par "DU") à partir de 'Libelle operation' */

data tests;
	set DEPDATA.ATE_REGEX_DEMO_DATA;
	format dudate ddmmyy10.;

  	re_date = prxparse('/DU\s\d\d\/\d\d/');  /* Définition de l'expression régulière pour le format "DU jj/mm" */
 	if prxmatch(re_date, 'Libelle operation'n) > 0 then do;  /* Correspondance pour "DU jj/mm" */
	   dudate = mdy(substr(prxposn(re_date, 0, 'Libelle operation'n), 7, 2),  /* Extrait le mois */
	                substr(prxposn(re_date, 0, 'Libelle operation'n), 4, 2),  /* Extrait le jour */
	                year(date));  /* Utilise l'année en cours */
	end;

	/* Ajuste 'dudate' si l'opération a eu lieu en décembre de l'année précédente */
	if month(date)=1 and month(dudate)=12 then dudate=mdy(month(dudate), day(dudate), (year(date) - 1));
	if dudate=. then dudate=date;
drop re_date;
rename dudate='Date réelle'n;
run;
proc print data=tests (obs=20) ; run; 

/* PART 2 : Extraction du Type de paiement */
data tests;
	set tests;
   length Type $ 20 ;
	Type = scan('Libelle operation'n,1); /* Extrait le premier mot dans 'Libelle operation' */
	if Type = "PAIEMENT" then Type = "PAIEMENT CB";
run; 
proc print data=tests (obs=20) ; run; 

/* PART 3 : Extraction de la ville */
data tests;
set tests (keep='Libelle operation'n 'Date'n uniqueID 'Date réelle'n 'Type'n);
   length ville $ 20 ;
/* Extraction de la 'ville' VERSION 1 */
   re_ville = prxparse('/ A\s\w+\s/');  * Définition de l'expression régulière pour correspondre à " A ville " ;
if Type in ("PAIEMENT CB", "RETRAIT") and (prxmatch(re_ville, 'Libelle operation'n) > 0) then do; 
   city = prxposn(re_ville, 0, 'Libelle operation'n);  * Extrait la correspondance entière, y compris 'A ville';
   ville = SCAN(city, 2);  * Extrait le nom de la ville (deuxième mot après "A");
end;
run;
proc print data=tests (obs=20) ; run; 

data tests;
set tests (keep='Libelle operation'n 'Date'n uniqueID 'Date réelle'n 'Type'n);
   length ville $ 20 ;
/* Extraction de la 'ville' VERSION 2 */
re_ville = prxparse('/\d\d\sA\s(.*?)\s\-/');
if prxmatch(re_ville, 'Libelle operation'n) then 
	ville =prxposn(re_ville, 1, 'Libelle operation'n);
	ville=strip(compress(ville,"1234567890+"));
drop re_ville; 
run;
proc print data=tests (obs=20) ; run; 

/* PART 4 : Extraction du pays */
data tests;
set tests;
   length pays $ 20 ;
   re_pays = prxparse('/\((.*?)\)/');  /* Définition de l'expression régulière pour trouver le texte entre parenthèses */
	if prxmatch(re_pays, 'Libelle operation'n) > 0 then  /* Vérifie si 'Libelle operation' contient des parenthèses */
	pays = prxposn(re_pays, 1, 'Libelle operation'n);   /* Extrait le texte entre parenthèses*/
	if ville = 'LUXEMBOURG' then pays = 'Luxembourg';
	else if ville ~= '' then pays = 'France';
drop re_pays;
run; 
proc print data=tests (obs=20) ; run; 

/* PART 5 : Nettoie la variable 'Libelle operation' pour supprimer les informations inutiles, en ne conservant que le nom de l'entreprise */
data tests;
set tests;
length libelle $ 100 ;
libelle = prxchange('s/\((.*?)\)/ /', -1, 'Libelle operation'n);  /* Supprime le texte entre parenthèses (pays) */
libelle = prxchange('s/REMBOURSEMENT CB|PAIEMENT CB/ /', -1, libelle);  /* Supprime "REMBOURSEMENT CB" ou "PAIEMENT CB" */
libelle = prxchange('s/DU\s\d\d\/\d\d\/\d\d\sA\s(.*?)\s\-/ /', -1, libelle);  /* Supprime les informations de ville comme "A Paris" */
libelle = prxchange('s/DU\s\d\d\/\d\d\sA\s(.*?)\s\-/ /', -1, libelle);  /* Supprime les informations de ville comme "A Paris" */
libelle = prxchange('s/DU\s\d\d\/\d\d\/\d\d|DU\s\d\d\/\d\d/ /', -1, libelle);  /* Supprime les dates au format "DU jj/mm/aa" ou "DU jj/mm" */
libelle = prxchange('s/ CARTE\d\d\d\d/ /', -1, libelle);  /* Supprime les informations de carte comme "CARTE*1234" */
libelle = prxchange('s/\s\-\s/ /', -1, libelle);  /* Supprime les - */
libelle = strip(libelle);  /* Supprime les espaces en début et fin de chaîne */
run;
proc print data=tests (obs=20) ; run; 

/* Pour ouvrir la table dans VA */
proc cas; table.dropTable / caslib="casuser" name="ATE_REGEX_DEMO_DATA" quiet=TRUE; quit;
data casuser.ATE_REGEX_DEMO_DATA(promote=yes);
set tests;
run;


/* Explanation helper */
/* data tests; */
/* 	set DEPDATA.ATE_REGEX_DEMO_DATA; */
/* 	format dudate ddmmyy10.; */
/*  */
/*   	re_date = prxparse('/DU\s\d\d\/\d\d/');  /* Définition de l'expression régulière pour le format "DU jj/mm" */
/*   	prxmatch_var_date = prxmatch(re_date, 'Libelle operation'n); */
/* 	prxposn_var_0_date = prxposn(re_date, 0, 'Libelle operation'n); */
/* 	prxposn_var_1_date = prxposn(re_date, 1, 'Libelle operation'n); */
/* 	 */
/* 	re_ville2 = prxparse('/\d\d\sA\s(.*?)\s\-/'); */
/* 	prxmatch_var_ville=  prxmatch(re_ville2, 'Libelle operation'n);  */
/* 	prxposn_var_0_ville =prxposn(re_ville2, 0, 'Libelle operation'n); */
/* 	prxposn_var_1_ville =prxposn(re_ville2, 1, 'Libelle operation'n); */
/* 	prxposn_var_2_ville =prxposn(re_ville2, 2, 'Libelle operation'n); */
/* run; */
