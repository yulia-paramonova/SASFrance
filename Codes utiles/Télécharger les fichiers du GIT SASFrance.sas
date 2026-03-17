/* Créer un dossier vide dans votre Home */
%let NOM_DU_DOSSIER=Nom du dossier sans quotes ou espaces;

options dlcreatedir;
libname newdir "&_USERHOME/&NOM_DU_DOSSIER";
libname newdir clear;

/* Télécharger tous les fichiers de ce répertoire git dans votre dossier */
data _null_;
    rc = git_clone (
     'https://github.com/yulia-paramonova/SASFrance.git',
     "&_USERHOME/&NOM_DU_DOSSIER");
    put rc=;
run;