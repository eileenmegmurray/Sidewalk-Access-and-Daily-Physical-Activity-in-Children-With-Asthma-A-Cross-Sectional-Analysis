/*================================================================*/
/*  PUBH 698                                   */
/*  Title: Neighborhood Sidewalk Presence and Daily Physical      */
/*         Activity Among Children with Current Asthma,          */
/*         2023 National Survey of Children's Health (NSCH)       */
/*                                                                */
/*  Author: Eileen Murray                                         */
/*  Date:   2026                                                  */
/*                                                                */
/*  File Organization:                                            */
/*    Section 1:  Library and Format Definitions                  */
/*    Section 2:  Data Cleaning and Variable Construction         */
/*    Section 3:  FPL Imputation and Dataset Stacking             */
/*    Section 4:  Table 1 - Descriptive Statistics                */
/*    Section 5:  Primary Logistic Regression Models (Table 2)    */
/*    Section 6:  Sensitivity Analyses (Table 3)                  */
/*    Section 7:  Effect Measure Modification (Table 4)           */
/*    Section 8:  Stratified Analyses (Table 5)                   */
/*    Section 9:  CI Calculations and Summary Output Tables       */
/*                                                                */
/*  Data: 2023 NSCH Topical Public Use File                       */
/*  Software: SAS Studio OnDemand for Academics                   */
/*================================================================*/


/*================================================================*/
/*  SECTION 1: LIBRARY AND FORMAT DEFINITIONS                     */
/*================================================================*/

libname rawdata "/home/u64168159/PUBH698/NSCHData";

proc format;

    /* Sidewalk presence: 1=Yes, 2=No */
    value sidewalkyn
        1 = '1 Sidewalk'
        2 = '2 No Sidewalk';

    /* Daily physical activity: 1=Daily (every day), 2=Non-daily */
    value dailyphys
        1 = 'Daily'
        2 = 'Nondaily';

    /* ACE count: 3-level categorical */
    value acemore
        1 = "No adverse childhood experiences"
        2 = "One adverse childhood experience"
        3 = "Two or more adverse childhood experiences"
        .M = "Missing to all 9 items";

    /* Neighborhood safety: dichotomous */
    value safeneigh
        1 = "Safe"
        2 = "Unsafe"
        .M = "Missing";

    /* Neighborhood detracting elements: dichotomous */
    value phys_comm
        1 = "Neighborhood does not have any detracting elements"
        2 = "Neighborhood has detracting elements"
        .M = "Missing to any of the question";

    /* Federal poverty level: 4-level categorical */
    value povertyfour
        1 = "0-99% of poverty level"
        2 = "100-199% of poverty level"
        3 = "200-399% of poverty level"
        4 = "400% or more of poverty level";

    /* Sex */
    value sexfm
        1 = "Male"
        2 = "Female";

    /* Age group: school-age children vs adolescents */
    value agegroups
        1 = "Children (6-10)"
        2 = "Adolescents(11-17)";

    /* Asthma status: 3-level */
    value condprev
        1 = "Does not have condition"
        2 = "Ever told, but does not currently have condition"
        3 = "Currently has condition"
        .M = "Missing";

run;


/*================================================================*/
/*  SECTION 2: DATA CLEANING AND VARIABLE CONSTRUCTION            */
/*                                                                */
/*  All variables derived from 2023 NSCH topical public use file  */
/*  Variable construction follows 2023 NSCH SAS codebook          */
/*================================================================*/

data clean23;
set rawdata.nsch_2023e_topical;

/*--- Asthma status (3-level) ---*/
/* 1 = Does not have asthma                                       */
/* 2 = Ever told but does not currently have asthma               */
/* 3 = Currently has asthma (analytic sample)                     */
asthma_23 = .;
if K2Q40A = 2 then asthma_23 = 1;
if K2Q40A = 1 and K2Q40B = 2 then asthma_23 = 2;
if K2Q40A = 1 and K2Q40B = 1 then asthma_23 = 3;
if K2Q40A = .M or K2Q40B = .M then asthma_23 = .M;
label asthma_23 = "Children who currently have asthma";

/*--- Physical activity (outcome) ---*/
/* Derived from PHYSACTIV: days per week with >= 60 min activity  */
/* 1 = Daily (every day of the week) -- analytic outcome          */
/* 2 = Non-daily (0-6 days per week)                              */
/* .N = Not applicable (children under age 6)                     */
PhysAct_23 = .;
if PHYSACTIV = 4 then PhysAct_23 = 1;
if PHYSACTIV in (1,2,3) then PhysAct_23 = 2;
if SC_AGE_YEARS < 6 then PhysAct_23 = .N;
label PhysAct_23 = "Physical activity (age 6-17)";

/*--- Age group (covariate) ---*/
/* 1 = Children (6-10 years)                                      */
/* 2 = Adolescents (11-17 years)                                  */
age_23 = .;
if 6 <= SC_AGE_YEARS <= 10 then age_23 = 1;
else if 11 <= SC_AGE_YEARS <= 17 then age_23 = 2;

/*--- Neighborhood sidewalk presence (exposure) ---*/
/* Derived from K10Q11: "In your neighborhood, is/are there:      */
/* Sidewalks, or walking paths?" Yes=1, No=2                      */
SideWlks_23 = K10Q11;

/*--- Neighborhood detracting elements (EMM variable) ---*/
/* Derived from 3 items: litter (K10Q20), rundown housing         */
/* (K10Q22), vandalism (K10Q23)                                   */
/* Dichotomized: 1=None present, 2=Any present                    */
/* Missing if any of the 3 items is missing                       */
litter_23  = K10Q20;
housing_23 = K10Q22;
vandal_23  = K10Q23;

NbhdDetract_23 = .;
validcomm = 0;
if K10Q20 in (1,2) then validcomm + 1;
if K10Q22 in (1,2) then validcomm + 1;
if K10Q23 in (1,2) then validcomm + 1;

comm_cond = 0;
if K10Q20 = 1 then comm_cond + 1;
if K10Q22 = 1 then comm_cond + 1;
if K10Q23 = 1 then comm_cond + 1;

if comm_cond in (1,2,3) then NbhdDetract_23 = 2;
if comm_cond = 0         then NbhdDetract_23 = 1;
if validcomm < 3         then NbhdDetract_23 = .M;

drop litter_23 housing_23 vandal_23 validcomm comm_cond;

/*--- Neighborhood safety (EMM variable) ---*/
/* Derived from K10Q40_R: "This child is safe in our              */
/* neighborhood" (4-point agreement scale)                        */
/* 1 = Safe (definitely/somewhat agree)                           */
/* 2 = Unsafe (somewhat/definitely disagree)                      */
NbhdSafe_23 = .;
if K10Q40_R in (1,2) then NbhdSafe_23 = 1;
if K10Q40_R in (3,4) then NbhdSafe_23 = 2;
if K10Q40_R = .M     then NbhdSafe_23 = .M;

/*--- Adverse Childhood Experiences (covariate) ---*/
/* 10-item composite following NSCH codebook construction         */
/* Economic hardship item recoded: somewhat/very often = yes      */
/* 1 = No ACEs, 2 = One ACE, 3 = Two or more ACEs                */
array acecnt10 {10}
    ACEincome2_23 ACE3 ACE4 ACE5 ACE6
    ACE7 ACE8 ACE9 ACE10 ACE11;

ACEcnt_23 = 0;
miss_ace_flag = 0;

do i = 1 to 10;
    if acecnt10[i] = .M then miss_ace_flag = 1;
    else if acecnt10[i] = 1 then ACEcnt_23 + 1;
end;

ACE2more_23 = .;
if miss_ace_flag = 1  then ACE2more_23 = .M;
else if ACEcnt_23 = 0 then ACE2more_23 = 1;
else if ACEcnt_23 = 1 then ACE2more_23 = 2;
else if ACEcnt_23 > 1 then ACE2more_23 = 3;

drop i miss_ace_flag ACEcnt_23;

/*--- Sex (covariate) ---*/
sex_23 = SC_SEX;

/*--- Missing indicators for sensitivity analyses ---*/
/* These are used in Section 6 sensitivity models only            */
/* 0 = non-missing, 1 = missing for each variable                 */

miss_asthma_23 = (asthma_23 = .M);
asthma_23_imp = asthma_23;
if asthma_23 = .M then asthma_23_imp = 1;

miss_physact_23 = (PhysAct_23 in (.M, .N));
physact_23_imp = PhysAct_23;
if PhysAct_23 in (.M, .N) then physact_23_imp = 1;

miss_nbhdSafe_23 = (NbhdSafe_23 = .M);
NbhdSafe_23_imp = NbhdSafe_23;
if NbhdSafe_23 = .M then NbhdSafe_23_imp = 1;

miss_nbhdDetract_23 = (NbhdDetract_23 = .M);
NbhdDetract_23_imp = NbhdDetract_23;
if NbhdDetract_23 = .M then NbhdDetract_23_imp = 0;

miss_ACE2more_23 = (ACE2more_23 = .M);
ACE2more_23_imp = ACE2more_23;
if ACE2more_23 = .M then ACE2more_23_imp = 1;

miss_sidewalk_23 = (SideWlks_23 = .M);
SideWlks_23_imp = SideWlks_23;
if SideWlks_23 = .M then SideWlks_23_imp = 1;

miss_age_23 = (age_23 = .M);
age_23_imp = age_23;
if age_23 = . then age_23_imp = 1;

miss_sex_23 = (sex_23 = .M);
sex_23_imp = sex_23;
if sex_23 = .M then sex_23_imp = 1;

/*--- Apply formats ---*/
format
    asthma_23     condprev.
    PhysAct_23    dailyphys.
    SideWlks_23   sidewalkyn.
    ACE2more_23   acemore.
    NbhdSafe_23   safeneigh.
    NbhdDetract_23 phys_comm.
    sex_23        sexfm.
    age_23        agegroups.;

run;


/*================================================================*/
/*  SECTION 3: FPL IMPUTATION AND DATASET STACKING                */
/*                                                                */
/*  The Census Bureau provides 6 multiply imputed FPL variables   */
/*  (fpl_i1 through fpl_i6) within the NSCH dataset.             */
/*  Each child is stacked 6 times (one row per implicate).        */
/*  All models are run by _Imputation_ and pooled via             */
/*  Rubin's Rules using proc mianalyze.                           */
/*  Final stacked dataset: n = 21,840 obs (3,640 children x 6)   */
/*================================================================*/

data stacked;
set clean23;

array fpli{6} fpl_i1-fpl_i6;

do _Imputation_ = 1 to 6;
    fpl_i = fpli{_Imputation_};

    /* Categorize FPL into 4 levels */
    if fpl_i < 100       then povcat_i = 1;
    else if 100 <= fpl_i < 200 then povcat_i = 2;
    else if 200 <= fpl_i < 400 then povcat_i = 3;
    else if fpl_i >= 400 then povcat_i = 4;

    output;
end;

format povcat_i povertyfour.;
run;

proc sort data=stacked;
    by _Imputation_;
run;


/*================================================================*/
/*  SECTION 4: TABLE 1 - DESCRIPTIVE STATISTICS                   */
/*                                                                */
/*  Analytic sample: children with current asthma (asthma_23=3)  */
/*  and non-missing sidewalk data (SideWlks_23 ne .)              */
/*  n = 3,640 unique children; 21,258 with non-missing PA data    */
/*                                                                */
/*  All tables use survey-weighted column percentages and 95% CIs */
/*  Rao-Scott chi-square tests assess group differences           */
/*  FPL pooled across 6 implicates via proc mianalyze             */
/*================================================================*/

/*--- 4a. Analytic sample missingness ---*/
/* Restricted to asthma=3 and non-missing sidewalk                */
/* _Imputation_=1 used as non-imputed variables do not            */
/* vary across implicates                                         */
proc surveyfreq data=stacked;
    strata STRATUM;
    cluster HHID;
    weight FWC;
    where asthma_23 = 3
          and SideWlks_23 ne .
          and _Imputation_ = 1;
    tables miss_ACE2more_23
           miss_nbhdSafe_23
           miss_nbhdDetract_23
           miss_physact_23
           miss_sidewalk_23
           miss_age_23
           miss_sex_23;
    title "Table 1a: Analytic Sample Missingness";
run;
title;

/*--- 4b. Overall sidewalk distribution ---*/
/* Source of 77.2% sidewalk prevalence cited in results           */
proc surveyfreq data=stacked;
    strata STRATUM;
    cluster HHID;
    weight FWC;
    where asthma_23 = 3
          and _Imputation_ = 1;
    tables SideWlks_23 / col cl;
    title "Table 1b: Overall Sidewalk Distribution Among Children with Current Asthma";
run;
title;

/*--- 4c. Physical activity by sidewalk ---*/
proc surveyfreq data=stacked;
    strata STRATUM;
    cluster HHID;
    weight FWC;
    where asthma_23 = 3
          and SideWlks_23 ne .
          and _Imputation_ = 1;
    tables physact_23 * SideWlks_23 / col cl chisq;
    ods output CrossTabs = mi_table_physact
               ChiSq     = chisq_physact;
    title "Table 1c: Physical Activity by Sidewalk Presence";
run;
title;

/*--- 4d. Age group by sidewalk ---*/
proc surveyfreq data=stacked;
    strata STRATUM;
    cluster HHID;
    weight FWC;
    where asthma_23 = 3
          and SideWlks_23 ne .
          and _Imputation_ = 1;
    tables age_23 * SideWlks_23 / col cl chisq;
    ods output CrossTabs = mi_table_age
               ChiSq     = chisq_age;
    title "Table 1d: Age Group by Sidewalk Presence";
run;
title;

/*--- 4e. Sex by sidewalk ---*/
proc surveyfreq data=stacked;
    strata STRATUM;
    cluster HHID;
    weight FWC;
    where asthma_23 = 3
          and SideWlks_23 ne .
          and _Imputation_ = 1;
    tables sex_23 * SideWlks_23 / col cl chisq;
    ods output CrossTabs = mi_table_sex
               ChiSq     = chisq_sex;
    title "Table 1e: Sex by Sidewalk Presence";
run;
title;

/*--- 4f. FPL by sidewalk (multiply imputed â pooled across 6 implicates) ---*/
/* Run across all 6 implicates, then pool column percentages      */
/* using proc mianalyze (Rubin's Rules)                           */
/* Chi-square reported from implicate 1 as representative         */
ods output CrossTabs = mi_table_fpl_raw
           ChiSq     = chisq_fpl_raw;
proc surveyfreq data=stacked;
    by _Imputation_;
    strata STRATUM;
    cluster HHID;
    weight FWC;
    where asthma_23 = 3
          and SideWlks_23 ne .;
    tables povcat_i * SideWlks_23 / col cl chisq;
    title "Table 1f: FPL by Sidewalk Presence (by imputation)";
run;
title;

/* Remove marginal rows before pooling */
data mi_table_fpl_clean;
    set mi_table_fpl_raw;
    where povcat_i not in (.) and SideWlks_23 not in (.);
run;

proc sort data=mi_table_fpl_clean;
    by povcat_i SideWlks_23 _Imputation_;
run;

/* Pool column percentages across implicates */
proc mianalyze data=mi_table_fpl_clean;
    by povcat_i SideWlks_23;
    modeleffects ColPercent;
    stderr ColStdErr;
    ods output ParameterEstimates = mi_table_fpl_pooled;
    title "Table 1f: FPL Pooled Column Percentages";
run;
title;

/* Chi-square from implicate 1 only */
data chisq_fpl;
    set chisq_fpl_raw;
    where _Imputation_ = 1;
run;

/*--- 4g. ACEs by sidewalk (complete case â excludes missing ACEs) ---*/
proc surveyfreq data=stacked;
    strata STRATUM;
    cluster HHID;
    weight FWC;
    where asthma_23 = 3
          and ACE2more_23 in (1,2,3)
          and SideWlks_23 ne .
          and _Imputation_ = 1;
    tables ACE2more_23 * SideWlks_23 / col cl chisq;
    ods output CrossTabs = mi_table_ace
               ChiSq     = chisq_ace;
    title "Table 1g: ACEs by Sidewalk Presence (Complete Case)";
run;
title;

/*--- 4h. Neighborhood safety by sidewalk ---*/
proc surveyfreq data=stacked;
    strata STRATUM;
    cluster HHID;
    weight FWC;
    where asthma_23 = 3
          and NbhdSafe_23 in (1,2)
          and SideWlks_23 ne .
          and _Imputation_ = 1;
    tables NbhdSafe_23 * SideWlks_23 / col cl chisq;
    ods output CrossTabs = mi_table_safety
               ChiSq     = chisq_safety;
    title "Table 1h: Neighborhood Safety by Sidewalk Presence";
run;
title;

/*--- 4i. Neighborhood detracting elements by sidewalk ---*/
proc surveyfreq data=stacked;
    strata STRATUM;
    cluster HHID;
    weight FWC;
    where asthma_23 = 3
          and NbhdDetract_23 in (1,2)
          and SideWlks_23 ne .
          and _Imputation_ = 1;
    tables NbhdDetract_23 * SideWlks_23 / col cl chisq;
    ods output CrossTabs = mi_table_detract
               ChiSq     = chisq_detract;
    title "Table 1i: Neighborhood Detracting Elements by Sidewalk Presence";
run;
title;


/*================================================================*/
/*  SECTION 5: PRIMARY LOGISTIC REGRESSION MODELS (TABLE 2)       */
/*                                                                */
/*  Exposure: SideWlks_23 (ref = 2, No Sidewalk)                 */
/*  Outcome:  PhysAct_23  (ref = 2, Non-Daily; models daily PA)   */
/*  All models run by _Imputation_ and pooled via mianalyze       */
/*                                                                */
/*  Crude:   Unadjusted                                           */
/*  Model 1: + age_23, sex_23                                     */
/*  Model 2: + povcat_i (FPL, imputed)                            */
/*  Model 3: + ACE2more_23 (complete case)                        */
/*  Model 4: Fully adjusted (all covariates, complete case ACEs)  */
/*================================================================*/

/*--- Crude Model ---*/
ods output ParameterEstimates = pe_crude;
proc surveylogistic data=stacked;
    by _Imputation_;
    strata STRATUM;
    cluster HHID;
    weight FWC;
    format sidewlks_23 physact_23;
    where asthma_23 = 3;
    class SideWlks_23 (ref='2');
    model PhysAct_23 (order=internal) = SideWlks_23 / link=logit;
run;

data pe_crude;
    set pe_crude;
    where Variable ne "Intercept";
run;

proc sort data=pe_crude; by Variable _Imputation_; run;

proc mianalyze data=pe_crude;
    by Variable;
    modeleffects Estimate;
    stderr StdErr;
    ods output ParameterEstimates = final_crude;
    title "Crude Model: Pooled Estimates";
run;
title;

/*--- Model 1: Age and Sex ---*/
ods output ParameterEstimates = pe_m1;
proc surveylogistic data=stacked;
    by _Imputation_;
    strata STRATUM;
    cluster HHID;
    weight FWC;
    format physact_23 age_23 sex_23 sidewlks_23;
    where asthma_23 = 3;
    class SideWlks_23 (ref='2')
          age_23      (ref='1')
          sex_23      (ref='1');
    model PhysAct_23 (order=internal) =
          SideWlks_23 age_23 sex_23 / link=logit;
run;

data pe_m1;
    set pe_m1;
    where Variable ne "Intercept";
run;

proc sort data=pe_m1; by Variable _Imputation_; run;

proc mianalyze data=pe_m1;
    by Variable;
    modeleffects Estimate;
    stderr StdErr;
    ods output ParameterEstimates = final_m1;
    title "Model 1: Age and Sex - Pooled Estimates";
run;
title;

/*--- Model 2: FPL (imputed, pooled across 6 implicates) ---*/
ods output ParameterEstimates = pe_m2;
proc surveylogistic data=stacked;
    by _Imputation_;
    strata STRATUM;
    cluster HHID;
    weight FWC;
    format povcat_i sidewlks_23 physact_23;
    where asthma_23 = 3;
    class SideWlks_23 (ref='2')
          povcat_i    (ref='4');
    model PhysAct_23 (order=internal) =
          SideWlks_23 povcat_i / link=logit;
run;

data pe_m2;
    set pe_m2;
    where Variable ne "Intercept";
run;

proc sort data=pe_m2; by Variable _Imputation_; run;

proc mianalyze data=pe_m2;
    by Variable;
    modeleffects Estimate;
    stderr StdErr;
    ods output ParameterEstimates = final_m2;
    title "Model 2: FPL - Pooled Estimates";
run;
title;

/*--- Model 3: ACEs (complete case â excludes missing ACEs) ---*/
ods output ParameterEstimates = pe_m3;
proc surveylogistic data=stacked;
    by _Imputation_;
    strata STRATUM;
    cluster HHID;
    weight FWC;
    class SideWlks_23   (ref='2')
          ACE2more_23   (ref='1');
    format sidewlks_23 ace2more_23 physact_23;
    where asthma_23 = 3
          and ACE2more_23 in (1,2,3); /* complete case */
    model PhysAct_23 (order=internal) =
          SideWlks_23 ACE2more_23 / link=logit;
run;

data pe_m3;
    set pe_m3;
    where Variable ne "Intercept";
run;

proc sort data=pe_m3; by Variable _Imputation_; run;

proc mianalyze data=pe_m3;
    by Variable;
    modeleffects Estimate;
    stderr StdErr;
    ods output ParameterEstimates = final_m3;
    title "Model 3: ACEs (Complete Case) - Pooled Estimates";
run;
title;

/*--- Model 4: Fully Adjusted (complete case for ACEs) ---*/
ods output ParameterEstimates = pe_m4;
proc surveylogistic data=stacked;
    by _Imputation_;
    strata STRATUM;
    cluster HHID;
    weight FWC;
    class SideWlks_23 (ref='2')
          age_23      (ref='1')
          sex_23      (ref='1')
          povcat_i    (ref='4')
          ACE2more_23 (ref='1');
    format ace2more_23 sex_23 age_23 povcat_i physact_23 sidewlks_23;
    where asthma_23 = 3
          and ACE2more_23 in (1,2,3); /* complete case */
    model PhysAct_23 (order=internal) =
          SideWlks_23 age_23 sex_23 povcat_i ACE2more_23
          / link=logit;
run;

data pe_m4;
    set pe_m4;
    where Variable ne "Intercept";
run;

proc sort data=pe_m4; by Variable _Imputation_; run;

proc mianalyze data=pe_m4;
    by Variable;
    modeleffects Estimate;
    stderr StdErr;
    ods output ParameterEstimates = final_m4;
    title "Model 4: Fully Adjusted (Complete Case) - Pooled Estimates";
run;
title;


/*================================================================*/
/*  SECTION 6: SENSITIVITY ANALYSES (TABLE 3)                     */
/*                                                                */
/*  Purpose: Assess robustness of primary findings to missing     */
/*  data assumptions by incorporating missing indicator variables  */
/*                                                                */
/*  S1: Model 1 + missing indicators for age and sex              */
/*      (zero variance â identical to primary Model 1)            */
/*  S2: Model 2 (FPL) â identical to primary Model 2             */
/*  S3: ACE2more_23_imp + miss_ACE2more_23 (retains all obs)      */
/*      Tests whether complete-case ACE exclusion influenced      */
/*      primary results                                           */
/*  S4: Fully adjusted + all missing indicators (retains all obs) */
/*      Uses ACE2more_23_imp; no ACE restriction in where clause  */
/*================================================================*/

/*--- Sensitivity Model 1: Age, Sex + Missing Indicators ---*/
ods output ParameterEstimates = pe_s1;
proc surveylogistic data=stacked;
    by _Imputation_;
    strata STRATUM;
    cluster HHID;
    weight FWC;
    class SideWlks_23  (ref='2')
          age_23       (ref='1')
          sex_23       (ref='1')
          miss_age_23  (ref='0')
          miss_sex_23  (ref='0');
    format age_23 sex_23 miss_age_23 miss_sex_23 sidewlks_23 physact_23;
    where asthma_23 = 3;
    model PhysAct_23 (order=internal) =
          SideWlks_23 age_23 sex_23
          miss_age_23 miss_sex_23
          / link=logit;
run;

data pe_s1;
    set pe_s1;
    where Variable ne "Intercept";
run;

proc sort data=pe_s1; by Variable _Imputation_; run;

proc mianalyze data=pe_s1;
    by Variable;
    modeleffects Estimate;
    stderr StdErr;
    ods output ParameterEstimates = final_s1;
    title "Sensitivity Model 1: Age Sex + Missing Indicators - Pooled Estimates";
run;
title;

/*--- Sensitivity Model 2: FPL (identical to primary Model 2) ---*/
ods output ParameterEstimates = pe_s2;
proc surveylogistic data=stacked;
    by _Imputation_;
    strata STRATUM;
    cluster HHID;
    weight FWC;
    class SideWlks_23 (ref='2')
          povcat_i    (ref='4');
    format povcat_i sidewlks_23 physact_23;
    where asthma_23 = 3;
    model PhysAct_23 (order=internal) =
          SideWlks_23 povcat_i / link=logit;
run;

data pe_s2;
    set pe_s2;
    where Variable ne "Intercept";
run;

proc sort data=pe_s2; by Variable _Imputation_; run;

proc mianalyze data=pe_s2;
    by Variable;
    modeleffects Estimate;
    stderr StdErr;
    ods output ParameterEstimates = final_s2;
    title "Sensitivity Model 2: FPL - Pooled Estimates";
run;
title;

/*--- Sensitivity Model 3: ACE Single-Value Substitution ---*/
/* Uses ACE2more_23_imp (missing coded to category 1) +           */
/* miss_ACE2more_23 indicator to retain all observations          */
/* Contrasts with primary Model 3 which uses complete case        */
ods output ParameterEstimates = pe_s3;
proc surveylogistic data=stacked;
    by _Imputation_;
    strata STRATUM;
    cluster HHID;
    weight FWC;
    class SideWlks_23       (ref='2')
          ACE2more_23_imp   (ref='1')
          miss_ACE2more_23  (ref='0');
    format physact_23 sidewlks_23;
    where asthma_23 = 3; /* no ACE restriction â retains all obs */
    model PhysAct_23 (order=internal) =
          SideWlks_23 ACE2more_23_imp miss_ACE2more_23
          / link=logit;
run;

data pe_s3;
    set pe_s3;
    where Variable ne "Intercept";
run;

proc sort data=pe_s3; by Variable _Imputation_; run;

proc mianalyze data=pe_s3;
    by Variable;
    modeleffects Estimate;
    stderr StdErr;
    ods output ParameterEstimates = final_s3;
    title "Sensitivity Model 3: ACE Missing Indicator - Pooled Estimates";
run;
title;

/*--- Sensitivity Model 4: Fully Adjusted + All Missing Indicators ---*/
/* Uses ACE2more_23_imp to retain missing-ACE observations            */
/* No ACE restriction in where clause                                 */
ods output ParameterEstimates = pe_s4;
proc surveylogistic data=stacked;
    by _Imputation_;
    strata STRATUM;
    cluster HHID;
    weight FWC;
    class SideWlks_23       (ref='2')
          age_23            (ref='1')
          sex_23            (ref='1')
          povcat_i          (ref='4')
          ACE2more_23_imp   (ref='1')
          miss_age_23       (ref='0')
          miss_sex_23       (ref='0')
          miss_ACE2more_23  (ref='0')
          miss_sidewalk_23  (ref='0')
          miss_physact_23   (ref='0');
    format sidewlks_23 physact_23 povcat_i sex_23 age_23;
    where asthma_23 = 3; /* no ACE restriction â retains all obs */
    model PhysAct_23 (order=internal) =
          SideWlks_23 age_23 sex_23 povcat_i ACE2more_23_imp
          miss_age_23 miss_sex_23 miss_ACE2more_23
          miss_sidewalk_23 miss_physact_23
          / link=logit;
run;

data pe_s4;
    set pe_s4;
    where Variable ne "Intercept";
run;

proc sort data=pe_s4; by Variable _Imputation_; run;

proc mianalyze data=pe_s4;
    by Variable;
    modeleffects Estimate;
    stderr StdErr;
    ods output ParameterEstimates = final_s4;
    title "Sensitivity Model 4: Fully Adjusted + Missing Indicators - Pooled Estimates";
run;
title;


/*================================================================*/
/*  SECTION 7: EFFECT MEASURE MODIFICATION (TABLE 4)              */
/*                                                                */
/*  Tests whether neighborhood safety (EMM1) or neighborhood      */
/*  detracting elements (EMM2) modify the association between     */
/*  sidewalk presence and daily physical activity on the          */
/*  multiplicative scale                                          */
/*                                                                */
/*  Both models are fully adjusted and use complete case for ACEs */
/*  ACE restriction added for consistency with primary models     */
/*================================================================*/

/*--- EMM Model 1: Neighborhood Safety x Sidewalk Interaction ---*/
ods output ParameterEstimates = pe_emm_safe;
proc surveylogistic data=stacked;
    by _Imputation_;
    strata STRATUM;
    cluster HHID;
    weight FWC;
    where PhysAct_23 not in (., .M, .N)
          and NbhdSafe_23 not in (., .M)
          and asthma_23 = 3
          and ACE2more_23 in (1,2,3); /* complete case for ACEs */
    class
        SideWlks_23 (ref='2')
        NbhdSafe_23 (ref='1')
        age_23      (ref='1')
        sex_23      (ref='1')
        povcat_i    (ref='4')
        ACE2more_23 (ref='1');
    format sidewlks_23 physact_23 nbhdsafe_23 age_23 sex_23 ace2more_23 povcat_i;
    model PhysAct_23 (order=internal) =
        SideWlks_23 NbhdSafe_23 age_23 sex_23 povcat_i ACE2more_23
        SideWlks_23*NbhdSafe_23
        / link=logit;
run;

data pe_emm_safe;
    set pe_emm_safe;
    where Variable ne "Intercept";
run;

proc sort data=pe_emm_safe; by Variable _Imputation_; run;

proc mianalyze data=pe_emm_safe;
    by Variable;
    modeleffects Estimate;
    stderr StdErr;
    ods output ParameterEstimates = final_emm_safe;
    title "EMM Model 1: Safety x Sidewalk Interaction - Pooled Estimates";
run;
title;

/*--- EMM Model 2: Neighborhood Detracting Elements x Sidewalk ---*/
/* Significant interaction found (p=0.018) â justifies Section 8  */
ods output ParameterEstimates = pe_emm_det;
proc surveylogistic data=stacked;
    by _Imputation_;
    strata STRATUM;
    cluster HHID;
    weight FWC;
    where PhysAct_23 not in (., .M, .N)
          and NbhdDetract_23 not in (., .M)
          and asthma_23 = 3
          and ACE2more_23 in (1,2,3); /* complete case for ACEs */
    format sidewlks_23 physact_23 NbhdDetract_23 age_23 sex_23 ace2more_23 povcat_i;
    class
        SideWlks_23    (ref='2')
        NbhdDetract_23 (ref='1')
        age_23         (ref='1')
        sex_23         (ref='1')
        povcat_i       (ref='4')
        ACE2more_23    (ref='1');
    model PhysAct_23 (order=internal) =
        SideWlks_23 NbhdDetract_23 age_23 sex_23 povcat_i ACE2more_23
        SideWlks_23*NbhdDetract_23
        / link=logit;
run;

data pe_emm_det;
    set pe_emm_det;
    where Variable ne "Intercept";
run;

proc sort data=pe_emm_det; by Variable _Imputation_; run;

proc mianalyze data=pe_emm_det;
    by Variable;
    modeleffects Estimate;
    stderr StdErr;
    ods output ParameterEstimates = final_emm_det;
    title "EMM Model 2: Detracting Elements x Sidewalk Interaction - Pooled Estimates";
run;
title;


/*================================================================*/
/*  SECTION 8: STRATIFIED ANALYSES (TABLE 5)                      */
/*                                                                */
/*  Conducted following statistically significant interaction in  */
/*  EMM Model 2 (detracting elements x sidewalk, p=0.018)         */
/*  Stratified by NbhdDetract_23: no detracting vs has detracting */
/*  Both strata use fully adjusted model with complete case ACEs  */
/*================================================================*/

/*--- Stratum 1: No Detracting Elements (NbhdDetract_23 = 1) ---*/
ods output ParameterEstimates = pe_strat_nodet;
proc surveylogistic data=stacked;
    by _Imputation_;
    strata STRATUM;
    cluster HHID;
    weight FWC;
    where asthma_23 = 3
          and NbhdDetract_23 = 1
          and ACE2more_23 in (1,2,3); /* complete case */
    class SideWlks_23 (ref='2')
          age_23      (ref='1')
          sex_23      (ref='1')
          povcat_i    (ref='4')
          ACE2more_23 (ref='1');
    format sidewlks_23 physact_23 age_23 sex_23 ace2more_23 povcat_i;
    model PhysAct_23 (order=internal) =
          SideWlks_23 age_23 sex_23 povcat_i ACE2more_23
          / link=logit;
run;

data pe_strat_nodet;
    set pe_strat_nodet;
    where Variable ne "Intercept";
run;

proc sort data=pe_strat_nodet; by Variable _Imputation_; run;

proc mianalyze data=pe_strat_nodet;
    by Variable;
    modeleffects Estimate;
    stderr StdErr;
    ods output ParameterEstimates = final_strat_nodet;
    title "Stratified Model: No Detracting Elements - Pooled Estimates";
run;
title;

/*--- Stratum 2: Has Detracting Elements (NbhdDetract_23 = 2) ---*/
ods output ParameterEstimates = pe_strat_det;
proc surveylogistic data=stacked;
    by _Imputation_;
    strata STRATUM;
    cluster HHID;
    weight FWC;
    where asthma_23 = 3
          and NbhdDetract_23 = 2
          and ACE2more_23 in (1,2,3); /* complete case */
    class SideWlks_23 (ref='2')
          age_23      (ref='1')
          sex_23      (ref='1')
          povcat_i    (ref='4')
          ACE2more_23 (ref='1');
    format sidewlks_23 physact_23 age_23 sex_23 ace2more_23 povcat_i;
    model PhysAct_23 (order=internal) =
          SideWlks_23 age_23 sex_23 povcat_i ACE2more_23
          / link=logit;
run;

data pe_strat_det;
    set pe_strat_det;
    where Variable ne "Intercept";
run;

proc sort data=pe_strat_det; by Variable _Imputation_; run;

proc mianalyze data=pe_strat_det;
    by Variable;
    modeleffects Estimate;
    stderr StdErr;
    ods output ParameterEstimates = final_strat_det;
    title "Stratified Model: Has Detracting Elements - Pooled Estimates";
run;
title;


/*================================================================*/
/*  SECTION 9: CI CALCULATIONS AND SUMMARY OUTPUT TABLES          */
/*                                                                */
/*  For non-imputed variables (e.g., SideWlks_23, age_23,         */
/*  sex_23), estimates are identical across all 6 implicates,     */
/*  producing between-imputation variance = 0. In these cases,    */
/*  proc mianalyze cannot compute CIs via Rubin's Rules and        */
/*  returns missing values for LCLMean and UCLMean.               */
/*                                                                */
/*  Solution: CIs are calculated manually as                      */
/*  Estimate +/- 1.96 * StdErr using the within-imputation        */
/*  survey variance. The CI_note variable flags which method       */
/*  was used for each parameter.                                   */
/*                                                                */
/*  Output datasets:                                              */
/*    all_sidewalk_results   -> Tables 2 and 3                    */
/*    emm_interaction_results -> Table 4                          */
/*    stratified_results      -> Table 5                          */
/*================================================================*/

%macro fix_ci(dsn=, out=, title=);
    data &out.;
        set &dsn.;
        if LCLMean = . then do;
            LCLMean = Estimate - 1.96 * StdErr;
            UCLMean = Estimate + 1.96 * StdErr;
            CI_note = "Manually calculated: zero between-imputation variance";
        end;
        else do;
            CI_note = "Rubin's Rules via proc mianalyze";
        end;
        label LCLMean = "Lower 95% CI"
              UCLMean = "Upper 95% CI"
              CI_note = "CI calculation method";
    run;
    proc print data=&out.;
        var Variable Estimate StdErr LCLMean UCLMean Probt CI_note;
        title "&title.";
    run;
    title;
%mend;

/*--- Apply CI macro to all models ---*/

/* Primary models */
%fix_ci(dsn=final_crude, out=final_crude_ci, title=Crude Model: CI);
%fix_ci(dsn=final_m1,    out=final_m1_ci,    title=Model 1 Age Sex: CI);
%fix_ci(dsn=final_m2,    out=final_m2_ci,    title=Model 2 FPL: CI);
%fix_ci(dsn=final_m3,    out=final_m3_ci,    title=Model 3 ACEs: CI);
%fix_ci(dsn=final_m4,    out=final_m4_ci,    title=Model 4 Fully Adjusted: CI);

/* Sensitivity models */
%fix_ci(dsn=final_s1,    out=final_s1_ci,
        title=Sensitivity Model 1 Age Sex Missing Indicators: CI);
%fix_ci(dsn=final_s2,    out=final_s2_ci,
        title=Sensitivity Model 2 FPL: CI);
%fix_ci(dsn=final_s3,    out=final_s3_ci,
        title=Sensitivity Model 3 ACE Missing Indicator: CI);
%fix_ci(dsn=final_s4,    out=final_s4_ci,
        title=Sensitivity Model 4 Fully Adjusted Missing Indicators: CI);

/* EMM models */
%fix_ci(dsn=final_emm_safe,    out=final_emm_safe_ci,
        title=EMM Model 1 Safety Interaction: CI);
%fix_ci(dsn=final_emm_det,     out=final_emm_det_ci,
        title=EMM Model 2 Detracting Interaction: CI);

/* Stratified models */
%fix_ci(dsn=final_strat_nodet, out=final_strat_nodet_ci,
        title=Stratified No Detracting Elements: CI);
%fix_ci(dsn=final_strat_det,   out=final_strat_det_ci,
        title=Stratified Has Detracting Elements: CI);

/*--- Summary Table: Sidewalk Log-OR Across All Models (Tables 2-3) ---*/
data all_sidewalk_results;
    length Model $50 CI_note $50;
    set final_crude_ci (in=a)
        final_m1_ci    (in=b)
        final_m2_ci    (in=c)
        final_m3_ci    (in=d)
        final_m4_ci    (in=e)
        final_s1_ci    (in=f)
        final_s2_ci    (in=g)
        final_s3_ci    (in=h)
        final_s4_ci    (in=i);
    where Variable = "SideWlks_23";
    if a then Model = "Crude";
    if b then Model = "Model 1: Age and Sex";
    if c then Model = "Model 2: FPL";
    if d then Model = "Model 3: ACEs (Complete Case)";
    if e then Model = "Model 4: Fully Adjusted (Complete Case)";
    if f then Model = "Sensitivity 1: Age Sex + Missing Indicators";
    if g then Model = "Sensitivity 2: FPL";
    if h then Model = "Sensitivity 3: ACE Missing Indicator";
    if i then Model = "Sensitivity 4: Fully Adjusted + Missing Indicators";
    keep Model Variable Estimate StdErr LCLMean UCLMean Probt CI_note;
    rename LCLMean = LCL
           UCLMean = UCL
           Probt   = pvalue;
run;

proc print data=all_sidewalk_results noobs;
    title "Tables 2 and 3: Sidewalk Log-OR and 95% CI - Primary and Sensitivity Models";
    var Model Estimate StdErr LCL UCL pvalue CI_note;
    format Estimate StdErr LCL UCL 8.3 pvalue pvalue6.4;
run;
title;

/*--- Summary Table: Interaction Log-OR (Table 4) ---*/
/* Interaction term variable names contain an asterisk            */
/* index() function identifies these rows                         */
data emm_interaction_results;
    length Model $50 CI_note $50;
    set final_emm_safe_ci (in=a)
        final_emm_det_ci  (in=b);
    where index(Variable, "*") > 0;
    if a then Model = "EMM Model 1: Safety x Sidewalk";
    if b then Model = "EMM Model 2: Detracting Elements x Sidewalk";
    keep Model Variable Estimate StdErr LCLMean UCLMean Probt CI_note;
    rename LCLMean = LCL
           UCLMean = UCL
           Probt   = pvalue;
run;

proc print data=emm_interaction_results noobs;
    title "Table 4: Interaction Log-OR and 95% CI - EMM Models";
    var Model Variable Estimate StdErr LCL UCL pvalue CI_note;
    format Estimate StdErr LCL UCL 8.3 pvalue pvalue6.4;
run;
title;

/*--- Summary Table: Stratified Sidewalk Log-OR (Table 5) ---*/
data stratified_results;
    length Model $50 CI_note $50;
    set final_strat_nodet_ci (in=a)
        final_strat_det_ci   (in=b);
    where Variable = "SideWlks_23";
    if a then Model = "Stratified: No Detracting Elements (n=1,871)";
    if b then Model = "Stratified: Has Detracting Elements (n=674)";
    keep Model Variable Estimate StdErr LCLMean UCLMean Probt CI_note;
    rename LCLMean = LCL
           UCLMean = UCL
           Probt   = pvalue;
run;

proc print data=stratified_results noobs;
    title "Table 5: Stratified Log-OR and 95% CI by Neighborhood Detracting Elements";
    var Model Estimate StdErr LCL UCL pvalue CI_note;
    format Estimate StdErr LCL UCL 8.3 pvalue pvalue6.4;
run;
title;

/*================================================================*/
/*  END OF ANALYSIS FILE                                          */
/*================================================================*/
