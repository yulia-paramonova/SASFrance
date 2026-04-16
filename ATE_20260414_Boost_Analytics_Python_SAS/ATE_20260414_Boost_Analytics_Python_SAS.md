# Boostez vos analyses Python avec la puissance de SAS Viya (14/04/2026)

Ce dossier contient deux notebooks qui montrent un parcours progressif avec Python sur SAS Viya:

1. se connecter à CAS et manipuler des tables en mémoire,
2. construire et comparer des modèles de machine learning avec les actions CAS.

## Objectif pédagogique

Passer d'une utilisation "data management" de CAS à une utilisation "modélisation" complète, en restant dans un notebook Python.

## Fichiers et contenu

### 1_Travailler_avec_CAS.ipynb

Ce notebook couvre les bases d'utilisation de CAS avec SWAT:

- installation/import des bibliothèques et ouverture d'une session CAS;
- vérification des tables disponibles dans la caslib utilisateur;
- chargement d'un CSV externe (cars) depuis GitHub;
- exploration rapide des données (`head`, `describe`, `summary`);
- calcul de variables dérivées (exemple: moyenne des MPG via `computedVarsProgram`);
- filtres et tris (valeur max, top N);
- gestion de la persistance des tables CAS:
    - promotion d'une table,
    - sauvegarde en `.sashdat`,
    - suppression/rechargement pour illustrer le cycle de vie des données.

En bref, ce fichier explique comment travailler efficacement avec des tables CAS entre plusieurs sessions.

### 2_Machine_Learning_avec_Python_CAS.ipynb

Ce notebook applique un flux ML complet sur le jeu Titanic:

- connexion CAS et chargement du CSV Titanic dans une table CAS;
- exploration initiale (dimensions, colonnes, aperçu, statistiques);
- conversion en DataFrame pour visualisations locales (histogrammes, facettes, heatmap);
- traitement des valeurs manquantes avec l'action CAS `dataPreprocess.impute`;
- vérification de la qualité des données (totaux, manquants, pourcentages);
- création de variables (feature engineering), par exemple:
    - `Relatives`,
    - `Alone_on_Ship`,
    - `Age_Times_Class`,
    - `Fare_Per_Person`;
- rechargement dans CAS et partition train/test avec `sampling.srs`;
- entraînement de plusieurs modèles CAS:
    - Forest,
    - Decision Tree,
    - Gradient Boosting Tree;
- scoring sur le jeu test et production des tables de prédiction;
- évaluation des performances (ROC, lift, concordance) et comparaison des modèles;
- calcul/interprétation de l'AUC pour une synthèse lisible de la qualité prédictive.

En bref, ce fichier montre une chaîne ML de bout en bout, de la préparation des données à l'évaluation comparative des modèles.

## Compétences couvertes

- Utiliser CAS depuis Python avec SWAT.
- Alterner entre tables CAS et DataFrames Pandas selon le besoin.
- Préparer des données pour la modélisation (imputation, variables dérivées, partition).
- Entraîner, noter et comparer plusieurs algorithmes via les action sets CAS.
- Interpréter les indicateurs de performance (erreur, ROC, lift, AUC).

## Prérequis techniques visibles dans les notebooks

- Python avec les packages `swat`, `numpy`, `pandas`, `matplotlib`, `seaborn`.
- Accès à un serveur SAS Viya/CAS.
- Fichier d'authentification local (exemple: `.authinfo`) pour la connexion.
