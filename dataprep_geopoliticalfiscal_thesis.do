********************************************************************************
* PROJECT:  Budgeting for Uncertainty in Taxing Times (MSc Thesis, PPA, Bocconi)
* FILE:     dataprep_geopoliticalfiscal_thesis.do
* PURPOSE:  Data Preparation
* AUTHOR:   Pia Riepl-Bauer
* MODIFIED: 2026-06-09
********************************************************************************

clear all
version 19.5 // frames require Stata 17+

* --- Paths ---
global root "/Users/piarieplbauer/Library/Mobile Documents/com~apple~CloudDocs/1 Studium/PPA Master/MSc Thesis"
global data "$root/data"
global output "$root/output"
cd "$root"

********************************************************************************
* Import, Transform and Merge GLES Data
********************************************************************************

* ------------------------------------------------------------------------------
* Import GLES Cross-Section 2009–2021, Cumulation (ZA6835)
* ------------------------------------------------------------------------------

/* GLES Cross-Section 2009–2021, Cumulation, v2.0.0 (ZA6835).
   GESIS Data Archive, doi:10.4232/1.14389.
   Restricted data — not included in replication package; request access via GESIS. */

use "$data/ZA6835_v2-0-0.dta", clear

* Recode GLES missing codes (−71 to −99) into Stata extended missings (.a–.q)
foreach var of varlist _all {
	capture confirm numeric var `var'
	if !_rc {
		qui mvdecode `var', mv(-71=.q \-72=.p \-73=.r \-81=.o ///
						\-82=.n \-83=.m \-84=.l \-85=.k ///
						\-86=.j \-91=.i \-92=.h \-93=.g ///
						\-94=.f \-95=.e \-96=.d \-97=.c ///
						\-98=.b \-99=.a)
		local lab: value label `var'
		if "`lab'"!="" {
			label define `lab' ///
			.a "keine Angabe" ///
			.b "weiss nicht" ///
			.c "trifft nicht zu" ///
			.d "Split" ///
			.e "nicht teilgenommen" ///
			.f "nicht in Auswahlgesamtheit" ///
			.g "Interview abgebrochen" ///
			.h "Fehler in Daten" ///
			.i "Modus" ///
			.j "nicht wahlberechtigt" ///
			.k "nicht waehlen" ///
			.l "keine Erst-/Zweitstimme abgeben" ///
			.m "ungueltig waehlen" ///
			.n "keine andere Partei waehlen" ///
			.o "noch nicht entschieden" ///
			.p "nicht einzuschaetzen" ///
			.q "nicht bekannt" ///
			.r "Mehrfachnennungen", modify
			}
		}
	else {
		display as result "The variable " as error "`var'" as result " is a string variable." _n "If any of the missing values are present, they are uniformly defined as system missing." _n _n _n
		qui replace `var' = "" if regexm(`var',"-71|-72|-73|-81|-82|-83|-84|-85|-86|-91|-92|-93|-94|-95|-96|-97|-98|-99")
	}
}

* Keep only variables used downstream
keep sample intyear intdate bula v26 v32 v74 v80 v81 ///
     v83d v83e v83h v72c v72d v70 ///
     v95 v96 v99 v100 v101 v102a ///
	 d1 d3c d5 d8_c d10 d23 d2 ostwest

* ------------------------------------------------------------------------------
* Import GLES Cross-Section 2025, Post-Election (ZA10100)
* ------------------------------------------------------------------------------

/* GLES Cross-Section 2025, Post-Election, v2.0.0 (ZA10100).
   GESIS Data Archive, doi:10.4232/5.ZA10100.2.0.0.
   Restricted data — not included in replication package; request access via GESIS. */

frame create gles_2025
frame change gles_2025

use "$data/ZA10100_v2-0-0.dta"

* Recode GLES missing codes (−71 to −99) into Stata extended missings (.a–.q)
foreach var of varlist _all {
	capture confirm numeric var `var'
	if !_rc {
		qui mvdecode `var', mv(-71=.q \-72=.p \-73=.r \-81=.o ///
						\-82=.n \-83=.m \-84=.l \-85=.k ///
						\-86=.j \-91=.i \-92=.h \-93=.g ///
						\-94=.f \-95=.e \-96=.d \-97=.c ///
						\-98=.b \-99=.a)
		local lab: value label `var'
		if "`lab'"!="" {
			label define `lab' ///
			.a "keine Angabe" ///
			.b "weiss nicht" ///
			.c "trifft nicht zu" ///
			.d "Split" ///
			.e "nicht teilgenommen" ///
			.f "nicht in Auswahlgesamtheit" ///
			.g "Interview abgebrochen" ///
			.h "Fehler in Daten" ///
			.i "Modus" ///
			.j "nicht wahlberechtigt" ///
			.k "nicht waehlen" ///
			.l "keine Erst-/Zweitstimme abgeben" ///
			.m "ungueltig waehlen" ///
			.n "keine andere Partei waehlen" ///
			.o "noch nicht entschieden" ///
			.p "nicht einzuschaetzen" ///
			.q "nicht bekannt" ///
			.r "Mehrfachnennungen", modify nofix
			}
		}
}

keep sample intyear intdatestart intdateend bula ///
		q76 q120 q37 q40 q41 q13 q23  ///
		q16 q26 q14 q24 q27c q27d q119 ///
		d1 d2a d7 d44 d45 d38 ostwest

* Flag observations where intdatestart was missing and replaced by intdateend
gen byte intdate_flag = (intdatestart == .h & !missing(intdateend))

* Use intdateend when intdatestart is missing (.h = "Fehler in Daten")
replace intdatestart = intdateend if intdatestart == .h

drop intdateend

/* For 1,232 / 7,337 observations the interview finished on a different date
   than it started; intdate_flag marks these cases. */
rename intdatestart intdate

* Rename ZA10100 variables to match cumulation naming convention
rename q76  v26
rename q120 v32
rename q37  v74
rename q40  v80
rename q41  v81
rename q13  v95
rename q23  v96
rename q14  v101   // retrospective personal
rename q24  v102a  // retrospective general (5-pt scale)
rename q16  v99    // prospective personal
rename q26  v100   // prospective general
rename d2a  d3c
rename d7   d5
rename d44  d8_c
rename d45  d10
rename d38  d23
rename q27c v72c
rename q27d v72d
rename q119 v70

* ------------------------------------------------------------------------------
* Align Variable Types and Append
* ------------------------------------------------------------------------------

* Store variable types from cumulation for comparison
frame change default

local varlist sample intyear intdate bula v26 v32 v74 v70 v72c v72d v80 v81 ///
				v95 v96 v100 v101 v102a ///
				d1 d3c d5 d8_c d10 d23 ostwest

foreach var of local varlist {
    local type_cum_`var' : type `var'
}

* Report type mismatches between cumulation and 2025 frame
frame change gles_2025

foreach var of local varlist {
    local type_2025_`var' : type `var'
    if "`type_cum_`var''" != "`type_2025_`var''" {
        di as error "Type mismatch for `var': Cumulation=`type_cum_`var'' vs 2025=`type_2025_`var''"
    }
    else {
        di as result "Type match for `var': `type_cum_`var''"
    }
}

* Count total mismatches
frame change default
local varlist sample intyear intdate bula v26 v32 v72c v72d v74 v80 v81 ///
				v95 v96 v99 v100 v101 v102a v70 ///
				d1 d3c d5 d8_c d10 d23 ostwest

local mismatch_count = 0

foreach var of local varlist {
    local type_cum : type `var'
    frame gles_2025: local type_2025 : type `var'
    
    if "`type_cum'" != "`type_2025'" {
        di as error "`var': Cumulation = `type_cum', 2025 = `type_2025'"
        local mismatch_count = `mismatch_count' + 1
    }
}

di as result _n "Total mismatches: `mismatch_count'"

/* Identified mismatches:
   sample:  byte  (cumulation) vs float (2025)
   intyear: int   (cumulation) vs float (2025)
   bula:    byte  (cumulation) vs long  (2025)
   d3c:     str17 (cumulation) vs str25 (2025) */

* Recast numeric types to match cumulation
frame change gles_2025

recast byte sample,  force
recast int  intyear, force
recast byte bula,    force

* Shorten d3c from str25 to str17 to match cumulation
gen str17 d3c_new = d3c
drop d3c
rename d3c_new d3c
order d3c, after(d1)

* Append 2025 data to cumulation
tempfile gles2025
save `gles2025', replace

frame change default
append using `gles2025'

* Verify append
tab intyear, m

* Save appended dataset
save "$data/GLES_cumulation_2009_2025.dta", replace

* ------------------------------------------------------------------------------
* Prepare Combined GLES Data
* ------------------------------------------------------------------------------

* Check missing interview dates (298 missings, exclusively in 2021)
tab intyear if missing(intdate)

* Impute missing interview dates in 2021 as September 1 (mid-fieldwork)
replace intdate = mdy(9, 1, 2021) if intyear == 2021 & missing(intdate)

* Check missing birth years (some can be recovered from reported age)
codebook d3c
tab d2 if missing(d3c)

* Drop respondents 90+ whose birth year is reported as "XXXX oder frueher"
gen byte over90_flag = strpos(d3c, "oder frueher") > 0
count if over90_flag == 1  // 158 observations
drop if over90_flag == 1
drop over90_flag

* Convert birth year from string to numeric
gen birth_year = real(d3c)

* Recover birth_year from reported age where still missing
gen age_numeric = real(d2)
replace birth_year = intyear - age_numeric if missing(birth_year) & !missing(age_numeric)
drop age_numeric

* Check remaining unresolvable missings
count if missing(birth_year)  // 247 observations

* Create year-month interview identifier for GPR merge
generate intmon = mofd(intdate)
recast int intmon
format intmon %tm
label var intmon "Interview: Datum, Jahr-Monat"
order intmon, after(intdate)

* --- Survey wave and sample indicators ---

* Wave indicator (election year)
gen wave = .
replace wave = 1 if sample == 1 | sample == 2   // 2009
replace wave = 2 if sample == 3 | sample == 4   // 2013
replace wave = 3 if sample == 5 | sample == 6   // 2017
replace wave = 4 if sample == 7 | sample == 8   // 2021
replace wave = 5 if sample == 9                 // 2025
label define wave_lbl 1 "2009" 2 "2013" 3 "2017" 4 "2021" 5 "2025"
label values wave wave_lbl
label variable wave "Election year"

* Extend sample labels for 2025 to fit cumulation pattern
label define SAMPLE 9 "post25", add
label values sample SAMPLE

* Pre/post-election indicator
gen post_election = 0
replace post_election = 1 if inlist(sample, 2, 4, 6, 8, 9)
label variable post_election "1 = post-election wave"

* --- Broad birth cohorts (named for their formative-year geopolitical context) ---
generate cohort = .
replace cohort = 1 if birth_year <= 1945
replace cohort = 2 if birth_year > 1945 & birth_year <= 1965
replace cohort = 3 if birth_year > 1965 & birth_year <= 1985
replace cohort = 4 if birth_year > 1985 & birth_year <= 2003
replace cohort = 5 if birth_year > 2003

label define cohort_lbl 1 "Postwar (≤1945)" 2 "Baby Boomers (1946-65)" ///
                        3 "Reunification (1966-85)" 4 "Eurocrisis (1986-2003)" ///
						5 "Ukraine War (2004-)"
label values cohort cohort_lbl
label var cohort "Broad birth cohort based on formative years"

********************************************************************************
* Import, Transform and Merge Geopolitical Risk Index (GPR)
********************************************************************************

/* Monthly Country-Specific GPR Index from Caldara & Iacoviello (2022).
   doi:10.1257/aer.20191823; publicly available at
   https://www.matteoiacoviello.com/gpr_country.htm */

frame create gpr
frame change gpr

use "$data/data_gpr_export.dta", clear

rename month intmon
recast int intmon

* Combine historical (pre-1985) and regular country GPR into a single series
generate GPR_DEU = GPRC_DEU
replace GPR_DEU = GPRHC_DEU if GPRC_DEU == .  // historical index for pre-1985 months
label var GPR_DEU "Combined Country GPR with historical for pre-1985: Percent of articles (Germany)"

keep intmon GPRC_DEU GPRHC_DEU GPR_DEU

save "$data/gpr_temp.dta", replace

* ------------------------------------------------------------------------------
* Merge GLES and GPR Data
* ------------------------------------------------------------------------------

frame change default

* m:1 merge on interview month; keep all GLES obs, matched GPR where available
merge m:1 intmon using "$data/gpr_temp.dta", keep(1 3)
drop if missing(sample)  // rows with no GLES sample indicator; artifact of m:1 merge

* ------------------------------------------------------------------------------
* Formative GPR Exposure
* ------------------------------------------------------------------------------

* --- Collapse GPR to annual level for formative window calculations ---
frame change gpr

gen year = year(dofm(intmon))
keep intmon year GPR_DEU

collapse (mean) GPR_DEU, by(year)
sort year

save "$data/gpr_annual.dta", replace

* --- Birth year scaffold: one row per birth year 1920–2009 ---
frame create formative_gpr
frame change formative_gpr

* Covers all respondents after dropping over-90s; 91 rows (1920–2009 inclusive)
set obs 91
gen birth_year = 1919 + _n

* Formative window bounds for each specification
gen fy_min_1825 = birth_year + 18   // baseline: ages 18–25
gen fy_max_1825 = birth_year + 25

gen fy_min_1525 = birth_year + 15   // earlier onset: ages 15–25
gen fy_max_1525 = birth_year + 25

gen fy_min_1830 = birth_year + 18   // extended window: ages 18–30
gen fy_max_1830 = birth_year + 30

gen fy_min_0018 = birth_year + 0    // childhood through adolescence: ages 0–18
gen fy_max_0018 = birth_year + 18

gen fy_min_0030 = birth_year + 0    // full childhood + early adulthood: ages 0–30
gen fy_max_0030 = birth_year + 30

gen fy_min_life = birth_year + 18   // full adult life; upper bound set at merge stage

save "$data/birth_years_scaffold.dta", replace

* --- Fixed-window lookup tables ---

/* For each window: cross birth year scaffold with gpr_annual, retain only
   years within the window, collapse to an unweighted mean by birth year. */

foreach spec in 1825 1525 1830 0018 0030 {

    use "$data/gpr_annual.dta", clear
    cross using "$data/birth_years_scaffold.dta"

    keep if year >= fy_min_`spec' & year <= fy_max_`spec'

    collapse (mean) gpr_form_`spec' = GPR_DEU, by(birth_year)

    label var gpr_form_`spec' "Avg GPR formative years (`spec')"
    save "$data/gpr_form_`spec'_lookup.dta", replace
}

* Merge all fixed-window lookups into default frame
frame change default

foreach spec in 1825 1525 1830 0018 0030 {
    merge m:1 birth_year using "$data/gpr_form_`spec'_lookup.dta", ///
        keep(1 3) gen(merge_form_`spec')
}

* --- Full adult life lookup ---

/* Upper bound varies by respondent, so lookup tables are built per survey year
   (birth_year × intyear) and then appended. Merge condition: m:1 birth_year intyear.*/

frame change formative_gpr

local survey_years 2009 2013 2017 2021 2025

foreach sy of local survey_years {

    use "$data/gpr_annual.dta", clear

    * Cross with birth year scaffold to get all birth_year × year combinations
    cross using "$data/birth_years_scaffold.dta"

    * Keep only years within adult life up to this survey year
    keep if year >= birth_year & year <= `sy'

    * Drop birth years for whom age 18 is after the survey year (too young)
    drop if birth_year > `sy'

    * Age at time of GPR experience
    gen age_at_exp   = year - birth_year          // 0 for birth year
	gen age_at_exp_w = max(age_at_exp, 18)

    * Full adult life: unweighted mean
    gen gpr_form_life_tmp = GPR_DEU

    collapse (mean)  gpr_form_life_tmp,            ///
             by(birth_year)

    gen intyear = `sy'

    label var gpr_form_life_tmp  "Avg GPR from birth to survey year `sy'"

    save "$data/gpr_form_lifdec_`sy'.dta", replace
}

* Append per-survey-year lookup tables
use "$data/gpr_form_lifdec_2009.dta", clear
foreach sy in 2013 2017 2019 2021 2025 {
    append using "$data/gpr_form_lifdec_`sy'.dta"
}

rename gpr_form_life_tmp  gpr_form_life

label var gpr_form_life  "Avg GPR from birth to survey year"

save "$data/gpr_form_lifdec_lookup.dta", replace

* Merge into default frame on birth_year × intyear
frame change default

merge m:1 birth_year intyear using "$data/gpr_form_lifdec_lookup.dta", ///
    keep(1 3) gen(merge_form_lifdec)

* --- Standardise all GPR variants ---
foreach spec in 1825 1525 1830 0018 0030 life {
    egen gpr_form_`spec'_std = std(gpr_form_`spec')
    label var gpr_form_`spec'_std "Formative GPR `spec' (standardised)"
}

* Alias baseline (18–25) to canonical variable names used downstream
clonevar gpr_formative = gpr_form_1825
clonevar gpr_form_std  = gpr_form_1825_std
label var gpr_formative "Avg GPR formative years 18-25 (baseline)"
label var gpr_form_std  "Formative GPR 18-25 (standardised, baseline)"

* Standardise current GPR and construct baseline interaction term
egen GPR_DEU_std = std(GPR_DEU)
label var GPR_DEU_std "GPR Germany (standardised)"

gen GPR_x_formative = GPR_DEU_std * gpr_form_std
label var GPR_x_formative "GPR × Formative GPR 18-25 (both std)"

save "$data/gles_gpr.dta", replace

********************************************************************************
* Construct Pseudo Panel
********************************************************************************

frame create pseudopanel
frame change pseudopanel

use "$data/gles_gpr.dta", clear

* Check overall, between, and within variation in GPR across cohort × wave
preserve
	recast int birth_year, force
    collapse (mean) v80 GPR_DEU (count) n_obs = v80, by(birth_year wave)
    xtset birth_year wave
    xtsum GPR_DEU
restore

* --- Prepare individual-level data for collapsing ---

* Recast grouping variables to avoid float precision issues
recast int  birth_year, force
recast byte bula,       force
recast byte wave,       force
recast byte ostwest,    force

* Check missingness rates by wave for candidate control variables
foreach var in d1 d5 d23 v74 v26 v32 v95 v96 v81 {
    di as text "--- `var' ---"
    tab wave if missing(`var')
}

* --- Demographic composition variables ---
gen female            = (d1 == 2)        if !missing(d1)
gen abitur            = (d5 == 5)        if !missing(d5)
gen class_subj        = d23              if !missing(d23)
gen lower_class_subj  = (d23 <= 2)      if d23 >= 1 & d23 <= 6  // lower + workers
gen middle_class_subj = (d23 >= 3 & d23 <= 5) if d23 >= 1 & d23 <= 6

* --- Political composition variables ---
gen leftright  = v74        if !missing(v74)  // left-right self-placement (1–11)
gen pid_strength = v26      if !missing(v26)  // PID strength (1=sehr stark … 5=sehr schwach)
gen party_lean = (v32 == 1) if !missing(v32)  // any party leaning (v32: 1=yes, 2=no)

* --- Economic perception variables ---
gen econ_personal = v95 if !missing(v95)    // current personal (1=sehr gut … 5=sehr schlecht)
label var econ_personal "Personal economic situation (1=much better…5=much worse)"

gen econ_general = v96 if !missing(v96)     // current general
label var econ_general "General economic situation (1=much better…5=much worse)"

gen econ_retro_pers = v101 if !missing(v101)  // retrospective personal
label var econ_retro_pers "Retrospective personal econ. (1=much better…5=much worse)"

gen econ_retro_gen = v102a if !missing(v102a) // retrospective general; not asked in pre-2013 wave
label var econ_retro_gen "Retrospective general econ. (1=much better…5=much worse)"

gen econ_prosp_pers = v99 if !missing(v99)   // prospective personal
label var econ_prosp_pers "Prospective personal econ. (1=much better…5=much worse)"

gen econ_prosp_gen = v100 if !missing(v100)  // prospective general
label var econ_prosp_gen "Prospective general econ. (1=much better…5=much worse)"

* Democratic satisfaction as trust-in-government proxy (v70, 1–4)
gen demsatisfac = v70 if !missing(v70)
label var demsatisfac "Satisfaction with democracy (1=very satisfied…4=very dissatisfied)"

* Issue salience of main DV (v81, 1=sehr wichtig … 5=überhaupt nicht wichtig)
gen salience = v81 if !missing(v81)

* Foreign-born indicator (d8_c is only present for respondents born outside Germany)
gen foreign_born = !missing(d8_c)

save "$data/pseudo_panel_raw.dta", replace

* ------------------------------------------------------------------------------
* 5-Year Birth Bands × State (Main Specification)
* ------------------------------------------------------------------------------

gen int birth_5yr = floor(birth_year / 5) * 5
label variable birth_5yr "5-year birth cohort"

* Check cell sizes by birth band and wave before collapsing
bysort birth_5yr wave: gen cell_check = _N if !missing(v80)
tabstat cell_check, by(wave) stats(mean p10 p25 p50 min n)
table birth_5yr wave, stat(count v80) nformat(%9.0f)
drop cell_check

keep v80 v83d v83e v83h v72c v72d ///
     GPR_DEU GPR_DEU_std ///
     gpr_formative gpr_form_std ///
     gpr_form_1525 gpr_form_1525_std ///
     gpr_form_1830 gpr_form_1830_std ///
	 gpr_form_0018 gpr_form_0018_std ///
     gpr_form_0030 gpr_form_0030_std ///
     gpr_form_life gpr_form_life_std ///
     female abitur class_subj lower_class_subj middle_class_subj ///
     leftright pid_strength party_lean ///
     salience foreign_born demsatisfac ///
	 econ_personal econ_general ///
     econ_retro_pers econ_retro_gen ///
     econ_prosp_pers econ_prosp_gen ///
     birth_5yr bula wave ostwest

drop if missing(v80) | missing(birth_5yr) | missing(bula) | missing(wave)

* Collapse to cohort × wave means (composition variables averaged within cells)
collapse (mean) v80 v83d v83e v83h v72c v72d ///
				GPR_DEU_std gpr_form_std ///
                gpr_form_1525_std ///
                gpr_form_1830_std ///
				gpr_form_0018_std ///
                gpr_form_0030_std ///
                gpr_form_life_std ///
                female abitur class_subj lower_class_subj middle_class_subj ///
				leftright pid_strength party_lean ///
				salience foreign_born demsatisfac ///
				econ_personal econ_general ///
                econ_retro_pers econ_retro_gen ///
                econ_prosp_pers econ_prosp_gen ///
         (sd)    v80_sd = v80 ///
         (count) n_obs  = v80, ///
         by(birth_5yr bula wave)

* Verify collapse: no duplicates
di as text "Total cells: " _N
duplicates tag birth_5yr bula wave, gen(dup_post)
tab dup_post  // all zeros
drop dup_post

* Cohort ID: unique per birth_5yr × bula combination
gen long cohort_id = birth_5yr * 100 + bula
order cohort_id

* Check within-cohort variation of composition variables across waves
bysort cohort_id: egen female_sd = sd(female)
bysort cohort_id: egen abitur_sd = sd(abitur)
summarize female_sd abitur_sd

* Identify cells with entirely missing control values
foreach var of varlist female abitur lower_class_subj leftright ///
                        econ_personal econ_general demsatisfac {
    qui count if missing(`var')
    if r(N) > 0 {
        di as text "--- Missing cells for `var': " r(N) " ---"
        list birth_5yr bula wave if missing(`var')
    }
}

* Verify cohort_id is unique per wave
duplicates tag cohort_id wave, gen(dup_id)
tab dup_id
drop dup_id

* Inverse variance weight: n / SD² (cells with n=1 use mean SD as fallback)
summarize v80_sd
replace v80_sd = r(mean) if missing(v80_sd) | v80_sd == 0
gen inv_var_wt = n_obs / (v80_sd^2)

* Interaction terms constructed on collapsed data
gen GPR_x_form_c     = GPR_DEU_std * gpr_form_std
gen GPR_x_form_1525  = GPR_DEU_std * gpr_form_1525_std
gen GPR_x_form_1830  = GPR_DEU_std * gpr_form_1830_std
gen GPR_x_form_0018  = GPR_DEU_std * gpr_form_0018_std
gen GPR_x_form_0030  = GPR_DEU_std * gpr_form_0030_std
gen GPR_x_form_life  = GPR_DEU_std * gpr_form_life_std

label var GPR_x_form_c	   "GPR × Formative GPR 18-25 (collapsed)"
label var GPR_x_form_1525  "GPR × Formative GPR 15-25 (collapsed)"
label var GPR_x_form_1830  "GPR × Formative GPR 18-30 (collapsed)"
label var GPR_x_form_0018  "GPR × Formative GPR 0-18 (collapsed)"
label var GPR_x_form_0030  "GPR × Formative GPR 0-30 (collapsed)"
label var GPR_x_form_life  "GPR × Formative GPR full life (collapsed)"

* Set panel
xtset cohort_id wave
xtdescribe
xtsum v80 GPR_DEU_std

save "$data/pseudo_panel_5yr_bula.dta", replace

* ------------------------------------------------------------------------------
* Alternative Pseudo Panel: Individual Birth Year × East/West
* ------------------------------------------------------------------------------

use "$data/pseudo_panel_raw.dta", clear

* ostwest coding: 1 = West, 2 = East (Berlin assigned to East)

* Cell size check before collapsing
bysort birth_year ostwest wave: gen cell_check = _N if !missing(v80)
tabstat cell_check, by(wave) stats(mean p10 p25 p50 min n)
di as text "Cells with n < 20:"
count if cell_check < 20 & !missing(cell_check)
drop cell_check

keep v80 v83d v83e v83h v72c v72d ///
     GPR_DEU GPR_DEU_std ///
     gpr_formative gpr_form_std ///
     gpr_form_1525_std gpr_form_1830_std ///
     gpr_form_life_std ///
     female abitur class_subj lower_class_subj middle_class_subj ///
     leftright pid_strength party_lean ///
     salience foreign_born demsatisfac ///
     econ_personal econ_general ///
     econ_retro_pers econ_retro_gen ///
     econ_prosp_pers econ_prosp_gen ///
     birth_year bula ostwest wave

drop if missing(v80) | missing(birth_year) | missing(wave) | missing(ostwest)

* Collapse to birth_year × ostwest × wave cells
collapse (mean) v80 v83d v83e v83h v72c v72d ///
                GPR_DEU_std gpr_form_std ///
                gpr_form_1525_std gpr_form_1830_std ///
                gpr_form_life_std ///
                female abitur class_subj lower_class_subj middle_class_subj ///
                leftright pid_strength party_lean ///
                salience foreign_born ///
                econ_personal econ_general ///
                econ_retro_pers econ_retro_gen ///
                econ_prosp_pers econ_prosp_gen ///
         (sd)    v80_sd = v80 ///
         (count) n_obs  = v80, ///
         by(birth_year ostwest wave)

* Verify collapse
di as text "Total cells (birth_year × ostwest): " _N
duplicates tag birth_year ostwest wave, gen(dup_ow)
tab dup_ow
drop dup_ow

* Cohort ID: birth_year × 10 + ostwest (1=West, 2=East)
gen long cohort_id_ow = birth_year * 10 + ostwest
label var cohort_id_ow "Cohort ID: birth_year × ostwest"
order cohort_id_ow

* Inverse variance weight
summarize v80_sd
replace v80_sd = r(mean) if missing(v80_sd) | v80_sd == 0
gen inv_var_wt = n_obs / (v80_sd^2)

* Interaction terms constructed on collapsed data
gen GPR_x_form_c     = GPR_DEU_std * gpr_form_std
gen GPR_x_form_1525  = GPR_DEU_std * gpr_form_1525_std
gen GPR_x_form_1830  = GPR_DEU_std * gpr_form_1830_std
gen GPR_x_form_life  = GPR_DEU_std * gpr_form_life_std

label var GPR_x_form_c     "GPR × Formative GPR 18-25 (ow collapsed)"
label var GPR_x_form_1525  "GPR × Formative GPR 15-25 (ow collapsed)"
label var GPR_x_form_1830  "GPR × Formative GPR 18-30 (ow collapsed)"
label var GPR_x_form_life  "GPR × Formative GPR full life (ow collapsed)"

* Verify cohort_id is unique per wave
duplicates tag cohort_id_ow wave, gen(dup_id)
tab dup_id
drop dup_id

* Set panel
xtset cohort_id_ow wave
xtdescribe
xtsum v80 GPR_DEU_std

save "$data/pseudo_panel_birthyr_ostwest.dta", replace

* ------------------------------------------------------------------------------
* Alternative Pseudo Panel by Samples (Pre/Post-Election Split)
* ------------------------------------------------------------------------------

use "$data/pseudo_panel_raw.dta", clear

* birth_5yr not yet generated on this frame — create here
gen int birth_5yr = floor(birth_year / 5) * 5
label variable birth_5yr "5-year birth cohort"

keep v80 ///
     GPR_DEU GPR_DEU_std ///
     gpr_formative gpr_form_std ///
     gpr_form_1525_std gpr_form_1830_std ///
     gpr_form_life_std ///
     female abitur class_subj lower_class_subj middle_class_subj ///
     leftright pid_strength party_lean ///
     salience foreign_born demsatisfac ///
     econ_personal econ_general ///
     econ_retro_pers econ_retro_gen ///
     econ_prosp_pers econ_prosp_gen ///
     post_election birth_5yr bula sample wave

drop if missing(v80) | missing(birth_5yr) | missing(bula) | missing(sample)

* Collapse to cohort × sample cells (9 time points across 5 elections)
collapse (mean) v80 ///
                GPR_DEU_std gpr_form_std ///
                gpr_form_1525_std gpr_form_1830_std ///
                gpr_form_life_std ///
                female abitur class_subj lower_class_subj middle_class_subj ///
                leftright pid_strength party_lean ///
                salience foreign_born ///
                econ_personal econ_general ///
                econ_retro_pers econ_retro_gen ///
                econ_prosp_pers econ_prosp_gen ///
                post_election wave ///
         (sd)    v80_sd = v80 ///
         (count) n_obs  = v80, ///
         by(birth_5yr bula sample)

* Verify collapse
di as text "Total cells (birth_5yr × bula × sample): " _N
duplicates tag birth_5yr bula sample, gen(dup_samp)
tab dup_samp
drop dup_samp

* Cohort ID (same formula as main spec; time dimension is sample, not wave)
gen long cohort_id = birth_5yr * 100 + bula
label var cohort_id "Cohort ID: birth_5yr × bula"
order cohort_id

* Inverse variance weight
summarize v80_sd
replace v80_sd = r(mean) if missing(v80_sd) | v80_sd == 0
gen inv_var_wt = n_obs / (v80_sd^2)

* Baseline interaction term
gen GPR_x_form_c = GPR_DEU_std * gpr_form_std
label var GPR_x_form_c "GPR × Formative GPR 18-25 (sample collapsed)"

* Set panel: cohort_id × sample (9 time points)
xtset cohort_id sample
xtdescribe
xtsum v80 GPR_DEU_std

save "$data/pseudo_panel_5yr_bula_sample.dta", replace

********************************************************************************
* Import and Transform Google Trends Tax Salience Data
********************************************************************************

/* Google Trends data fetched via gt_geopoliticalfiscal_thesis.R; see README. */

frame create gt
frame change gt

import delimited "$data/GT/taxation_gt_salience_national.csv", ///
    clear varnames(1) case(lower)

* Parse year-month for merge
gen intmon_gt = monthly(ym, "YM")
format intmon_gt %tm
label var intmon_gt "GT data: year-month (Stata %tm)"

label var index_raw   "GT Fiscal Salience Index (raw, rescaled to anchor)"
label var taxsal_norm "GT Fiscal Salience Index (normalised 0–100)"
label var taxsal_ma3  "GT Fiscal Salience (3-month moving average)"
label var taxsal_ma6  "GT Fiscal Salience (6-month moving average)"

save "$data/taxation_gt_salience_national.dta", replace

* ------------------------------------------------------------------------------
* Merge GT Salience with Main GLES–GPR Data
* ------------------------------------------------------------------------------

use "$data/gles_gpr.dta", clear

rename intmon intmon_gles  // avoid collision with intmon_gt
gen intmon_gt = intmon_gles
format intmon_gt %tm

merge m:1 intmon_gt using "$data/taxation_gt_salience_national.dta", ///
    keep(master match) nogenerate

* Check merge quality: no GLES obs should be missing GT if GT covers full window
tab wave if missing(taxsal_norm)
assert !missing(taxsal_norm) if !missing(intmon_gt)

destring taxsal_ma3 taxsal_ma6, replace force

* Standardise GT variables for regression comparability with GPR
foreach v of varlist taxsal_norm index_raw taxsal_ma3 taxsal_ma6 {
    egen `v'_std = std(`v')
    label var `v'_std "`v' (standardised)"
}

save "$data/gles_gpr_gt.dta", replace

********************************************************************************
* END OF FILE
********************************************************************************
