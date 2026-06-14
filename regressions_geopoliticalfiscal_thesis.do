********************************************************************************
* PROJECT:  Budgeting for Uncertainty in Taxing Times (MSc Thesis, PPA, Bocconi)
* FILE:     regressions_geopoliticalfiscal_thesis.do
* PURPOSE:  Regressions
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

* --- Packages (uncomment to install) ---
//ssc install estout
//ssc install coefplot

* ------------------------------------------------------------------------------
* Variable Labels (globals; assembled into locals at point of use)
* ------------------------------------------------------------------------------

* Cross-section GPR core
global vl_gpr_cs ///
    GPR_DEU_std                    "Current GPR (std.)" ///
    gpr_form_std                   "Formative GPR 18-25 (std.)" ///
    GPR_x_form_c                   "Current GPR \$\times\$ formative GPR" ///
    "c.GPR_DEU_std#c.gpr_form_std" "Current GPR \$\times\$ formative GPR"

* Pseudo-panel GPR core (cell means; prefix "Mean")
global vl_gpr_pp ///
    GPR_DEU_std                    "Mean current GPR (std.)" ///
    gpr_form_std                   "Mean formative GPR 18-25 (std.)" ///
    GPR_x_form_c                   "Mean current GPR \$\times\$ formative GPR" ///
    "c.GPR_DEU_std#c.gpr_form_std" "Mean current GPR \$\times\$ formative GPR"

* Tax salience (GT robustness, Ch. 5.3)
global vl_gt ///
    taxsal_norm_std                   "Tax salience GT (norm., std.)" ///
    taxsal_ma6_std                    "Tax salience GT (6m MA, std.)" ///
    "c.GPR_DEU_std#c.taxsal_norm_std" "Current GPR \$\times\$ tax salience (GT norm.)" ///
    "c.GPR_DEU_std#c.taxsal_ma6_std"  "Current GPR \$\times\$ tax salience (GT MA6)"

* Socio-demographic controls — cross-section (factor variables)
global vl_dem_cs ///
    d1  "Gender" ///
    d5  "School education" ///
    d23 "Subj. class"

* Socio-demographic controls — pseudo panel (cell-mean shares)
global vl_dem_pp ///
    female           "(Share of) female" ///
    abitur           "(Share of) Abitur" ///
    lower_class_subj "(Share of) subj. lower class"

* Political controls — cross-section (used in GT salience table for v81)
global vl_pol_cs ///
    v80       "Tax-benefit pref." ///
    v81       "Tax-benefit salience"

* Economic perceptions — cross-section
global vl_econ_cs ///
    econ_personal   "Econ. pers. (curr.)" ///
    econ_general    "Econ. gen. (curr.)" ///
    econ_retro_pers "Econ. pers. (retro.)" ///
    econ_retro_gen  "Econ. gen. (retro.)" ///
    econ_prosp_pers "Econ. pers. (prosp.)" ///
    econ_prosp_gen  "Econ. gen. (prosp.)"

* Economic perceptions — pseudo panel
global vl_econ_pp ///
    econ_personal   "Mean econ. pers. (curr.)" ///
    econ_general    "Mean econ. gen. (curr.)" ///
    econ_retro_pers "Mean econ. pers. (retro.)" ///
    econ_retro_gen  "Mean econ. gen. (retro.)" ///
    econ_prosp_pers "Mean econ. pers. (prosp.)" ///
    econ_prosp_gen  "Mean econ. gen. (prosp.)"

* Formative exposure window variants — pseudo panel (Ch. 5.1)
global vl_fe_pp ///
    GPR_DEU_std        "Mean current GPR (std.)" ///
    gpr_form_std       "M. formative GPR (18-25) (std.)" ///
    gpr_form_1525_std  "M. formative GPR (15-25) (std.)" ///
    gpr_form_1830_std  "M. formative GPR (18-30) (std.)" ///
    gpr_form_0018_std  "M. formative GPR (0-18) (std.)" ///
    gpr_form_0030_std  "M. formative GPR (0-30) (std.)" ///
    gpr_form_life_std  "M. formative GPR (life) (std.)" ///
    GPR_x_form_c       "M. current GPR \$\times\$ formative GPR (18-25)" ///
    GPR_x_form_1525    "M. current GPR \$\times\$ formative GPR (15-25)" ///
    GPR_x_form_1830    "M. current GPR \$\times\$ formative GPR (18-30)" ///
    GPR_x_form_0018    "M. current GPR \$\times\$ formative GPR (0-18)" ///
    GPR_x_form_0030    "M. current GPR \$\times\$ formative GPR (0-30)" ///
    GPR_x_form_life    "M. current GPR \$\times\$ formative GPR (life)"

* Miscellaneous (pre/post indicator and wave dummies)
global vl_misc ///
    post_election "Post-election sample" ///
    "1.wave"      "Wave 1 (2009)" ///
    "2.wave"      "Wave 2 (2013)" ///
    "3.wave"      "Wave 3 (2017)" ///
    "4.wave"      "Wave 4 (2021)" ///
    "5.wave"      "Wave 5 (2025)"

********************************************************************************
* Individual-Level OLS with Fixed Effects (Ch. 4.1 / 3.2.2)
********************************************************************************

frame create crosssection
frame change crosssection

use "$data/gles_gpr.dta", clear
drop if missing(v80)

local varlabels $vl_gpr_cs $vl_dem_cs

* M1: Bivariate
eststo m1: reg v80 GPR_DEU_std, robust
estadd local birth_year_fe "No"
estadd local state_fe      "No"
estadd local controls      "No"

* M2: + birth-year FEs
eststo m2: reg v80 GPR_DEU_std i.birth_year, cluster(intmon)
estadd local birth_year_fe "Yes"
estadd local state_fe      "No"
estadd local controls      "No"

* M3: + state FEs
eststo m3: reg v80 GPR_DEU_std i.birth_year i.bula, cluster(intmon)
estadd local birth_year_fe "Yes"
estadd local state_fe      "Yes"
estadd local controls      "No"

* M4: + individual controls
eststo m4: reg v80 GPR_DEU_std i.birth_year i.bula ///
    i.d1 i.d5 i.d23, cluster(intmon)
estadd local birth_year_fe "Yes"
estadd local state_fe      "Yes"
estadd local controls      "Yes"

/* M5–M6: gpr_form_std is a function of birth_year, so it is collinear with
   birth-year FEs. Broad cohort dummies replace birth-year FEs from M5 onward. */

* M5: + formative GPR (cohort dummies replace birth-year FEs)
eststo m5: reg v80 GPR_DEU_std gpr_form_std i.cohort i.bula ///
    i.d1 i.d5 i.d23, cluster(intmon)
estadd local birth_year_fe "Generation"
estadd local state_fe      "Yes"
estadd local controls      "Yes"

* M6: + GPR × formative GPR interaction
eststo m6: reg v80 c.GPR_DEU_std##c.gpr_form_std i.cohort i.bula ///
    i.d1 i.d5 i.d23, cluster(intmon)
estadd local birth_year_fe "Generation"
estadd local state_fe      "Yes"
estadd local controls      "Yes"

esttab m1 m2 m3 m4 m5 m6 using "$output/reg_v80_GPR_FE_main.tex", replace ///
    keep(GPR_DEU_std gpr_form_std c.GPR_DEU_std#c.gpr_form_std) ///
    b(%9.3f) se(%9.3f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    nonote ///
    varlabels(`varlabels') ///
    stats(birth_year_fe state_fe controls N r2_a, ///
          labels("Birth-year FE" "State FE" "Controls" ///
                 "Observations" "Adj. R\$^2\$") ///
          fmt(0 0 0 0 3)) ///
    mtitles("Bivariate" "Birth Year FE" "Birth + State FE" ///
            "Controls" "Formative GPR" "Interaction") ///
    title("Current GPR on Tax–Benefit Preferences: Individual-Level OLS Regression with Birth-Year and State Fixed Effects and Controls \label{reg:v80GPRmain}") ///
    addnote("* p<0.10, ** p<0.05, *** p<0.01. Standard errors clustered on interview month level except (1) with robust SEs.")

********************************************************************************
* Cohort-Aggregated Pseudo Panel (Ch. 4.2 / 3.2.3)
********************************************************************************

frame create pseudopanel
frame change pseudopanel

use "$data/pseudo_panel_5yr_bula.dta", clear

local varlabels $vl_gpr_pp $vl_dem_pp

* PB0: No cohort FE — raw GPR correlation
eststo pb0: reg v80 GPR_DEU_std [aw = inv_var_wt], robust
estadd local cohort_fe "No"
estadd local controls  "No"

* PB1: + cohort FE
eststo pb1: areg v80 GPR_DEU_std ///
    [aw = inv_var_wt], absorb(cohort_id) vce(robust)
estadd local cohort_fe "Yes"
estadd local controls  "No"

* PB2: + demographic controls
eststo pb2: areg v80 GPR_DEU_std ///
    female abitur lower_class_subj ///
    [aw = inv_var_wt], absorb(cohort_id) vce(robust)
estadd local cohort_fe "Yes"
estadd local controls  "Yes"

* PB3: + formative GPR
eststo pb3: areg v80 GPR_DEU_std gpr_form_std ///
    female abitur lower_class_subj ///
    [aw = inv_var_wt], absorb(cohort_id) vce(robust)
estadd local cohort_fe "Yes"
estadd local controls  "Yes"

* PB4: + GPR × formative GPR interaction
eststo pb4: areg v80 GPR_DEU_std gpr_form_std GPR_x_form_c ///
    female abitur lower_class_subj ///
    [aw = inv_var_wt], absorb(cohort_id) vce(robust)
estadd local cohort_fe "Yes"
estadd local controls  "Yes"

* PB5: + economic perceptions (used in econ perception section below)
eststo pb5: areg v80 GPR_DEU_std gpr_form_std GPR_x_form_c ///
    female abitur lower_class_subj ///
    econ_personal econ_general ///
    [aw = inv_var_wt], absorb(cohort_id) vce(robust)
estadd local cohort_fe "Yes"
estadd local controls  "Yes"

* Main results table: PB0–PB4 (PB5 reported in economic perceptions section)
esttab pb0 pb1 pb2 pb3 pb4 using "$output/reg_v80_pseudopanel_main.tex", replace ///
    keep(GPR_DEU_std gpr_form_std GPR_x_form_c ///
         female abitur lower_class_subj) ///
	order(GPR_DEU_std gpr_form_std GPR_x_form_c ///
         female abitur lower_class_subj) ///
    b(%9.3f) se(%9.3f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    nonote ///
    varlabels(`varlabels') ///
    stats(cohort_fe N r2_a, ///
          labels("Cohort FE" "Cells" "Adj. R\$^2\$") ///
          fmt(0 0 3)) ///
    mtitles("No FE" "Baseline" "Controls" ///
            "Formative GPR" "Interaction") ///
    title("Current and Formative GPR on Tax–Benefit Preferences: Cohort-Aggregated Pseudo Panel Regression with Cohort Fixed Effects and Compositional Controls \label{reg:v80pseudopanelmain}") ///
    addnote("* p<0.10, ** p<0.05, *** p<0.01. Robust standard errors in parentheses." ///
            "Means for 5-year birth \$\times\$ state cohorts. Inverse-variance weighted.")

********************************************************************************
* Economic Perceptions as Mediators (Ch. 4.3 / 3.2.4)
********************************************************************************

// frame change pseudopanel

local controls_socdem female abitur lower_class_subj
local gpr_core        GPR_DEU_std gpr_form_std GPR_x_form_c

local varlabels $vl_gpr_pp $vl_dem_pp $vl_econ_pp

* ------------------------------------------------------------------------------
* Economic Perception Channel: Descriptive Attenuation Pathway
* ------------------------------------------------------------------------------

* --- Panel A: DV = v80 (fiscal conservatism) ---

* Col 1: Interaction model, no economic perceptions (total effect)
eststo ec_total: areg v80 GPR_DEU_std gpr_form_std GPR_x_form_c     ///
    `controls_socdem'                                  			    ///
    [aw = inv_var_wt], absorb(cohort_id) vce(robust)
estadd local cohort_fe "Yes"
estadd local controls  "Yes"
estadd local econ_ctrl "No"
estadd local dv        "Tax-benefit pref."

* Col 2: Add general economic perceptions (direct effect)
eststo ec_direct: areg v80 GPR_DEU_std gpr_form_std GPR_x_form_c    ///
    `controls_socdem'                                  			    ///
    econ_general                                                    ///
    [aw = inv_var_wt], absorb(cohort_id) vce(robust)
estadd local cohort_fe "Yes"
estadd local controls  "Yes"
estadd local econ_ctrl "Yes"
estadd local dv        "Tax-benefit pref."

* --- Panel B: DV = econ_general (first stage) ---

* Col 3: GPR predicts general economic perceptions
eststo ec_stage1: areg econ_general GPR_DEU_std gpr_form_std        ///
    `controls_socdem'                                   			///
    [aw = inv_var_wt], absorb(cohort_id) vce(robust)
estadd local cohort_fe "Yes"
estadd local controls  "Yes"
estadd local econ_ctrl "---"
estadd local dv        "Econ. perception, general"

* --- Results table ---
local varlabels_ec ///
    GPR_DEU_std   "Mean current GPR (std.)" ///
    gpr_form_std  "Mean form. GPR (std.)" ///
    GPR_x_form_c  "Mean current \$\times$ form. GPR" ///
    econ_general  "Mean econ. gen. (curr.)"

esttab ec_total ec_direct ec_stage1                                   ///
    using "$output/reg_v80_econ_channel_panel.tex", replace           ///
    keep(GPR_DEU_std gpr_form_std GPR_x_form_c econ_general)          ///
    b(%9.3f) se(%9.3f)                                                ///
    star(* 0.10 ** 0.05 *** 0.01)                                     ///
    nonote                                                            ///
    varlabels(`varlabels_ec')                                      	  ///
    mgroups("DV: Tax-benefit preference"                              ///
            "\shortstack{DV: Econ. perception\\(gen.\ curr.)}",                      ///
            pattern(1 0 1)                                            ///
            prefix(\multicolumn{@span}{c}{)                           ///
            suffix(})                                                 ///
            span erepeat(\cmidrule(lr){@span}))                       ///
    mtitles("Total effect" "Direct effect" "First stage")             ///
    stats(cohort_fe controls N r2_a,                                 ///
          labels("Cohort FE" "Controls"               				 ///
                 "Cells" "Adj. R\$^2\$")                              ///
          fmt(0 0 0 3))                                               ///
    title("GPR on Tax-Benefit Preferences Before and After Controlling for Economic Perceptions: Descriptive Attenuation and First-Stage Evidence (Pseudo Panel) \label{reg:v80econchannelpanel}") ///
    addnote("* p<0.10, ** p<0.05, *** p<0.01. Robust standard errors in parentheses." ///
            "Means for 5-year birth \$\times\$ state cohorts. Inverse-variance weighted.")

* ------------------------------------------------------------------------------
* First-Stage Regressions: Economic Perceptions on GPR
* ------------------------------------------------------------------------------
* Col 1: DV = econ_personal (current, pocketbook)
eststo fs_pers: areg econ_personal GPR_DEU_std gpr_form_std           ///
    `controls_socdem'                                                   ///
    [aw = inv_var_wt], absorb(cohort_id) vce(robust)
estadd local cohort_fe "Yes"
estadd local controls  "Yes"
estadd local waves     "1-5"

* Col 2: DV = econ_general (current, sociotropic)
eststo fs_gen: areg econ_general GPR_DEU_std gpr_form_std             ///
    `controls_socdem'                                                   ///
    [aw = inv_var_wt], absorb(cohort_id) vce(robust)
estadd local cohort_fe "Yes"
estadd local controls  "Yes"
estadd local waves     "1-5"

* Col 3: DV = econ_retro_gen (retrospective general; wave 4 missing)
eststo fs_retro_gen: areg econ_retro_gen GPR_DEU_std gpr_form_std     ///
    `controls_socdem'                                                   ///
    [aw = inv_var_wt], absorb(cohort_id) vce(robust)
estadd local cohort_fe "Yes"
estadd local controls  "Yes"
estadd local waves     "2-5"

* --- Results table ---
esttab fs_pers fs_gen fs_retro_gen                                    ///
    using "$output/reg_firststage_econ_channel.tex", replace          ///
    keep(GPR_DEU_std gpr_form_std)                                    ///
    b(%9.3f) se(%9.3f)                                                ///
    star(* 0.10 ** 0.05 *** 0.01)                                     ///
    nonote                                                            ///
    varlabels(`varlabels_ec')                                      	  ///
    mgroups("DV: Personal (curr.)"                  				  ///
            "DV: General (curr.)"                   				  ///
            "DV: General (retro.)",                 				  ///
            pattern(1 1 1)                                            ///
            prefix(\multicolumn{@span}{c}{)                           ///
            suffix(})                                                 ///
            span erepeat(\cmidrule(lr){@span}))                       ///
    mtitles("Personal (curr.)" "General (curr.)" "General (retro.)")  ///
    stats(cohort_fe controls waves N r2_a,                            ///
          labels("Cohort FE" "Controls" "Waves"                       ///
                 "Cells" "Adj. R\$^2\$")                              ///
          fmt(0 0 0 0 3))                                             ///
    title("Economic Perceptions on GPR: First-Stage Regressions Across Selected Perception Dimensions (Pseudo Panel)"  ///
          "\label{reg:firststageeconchannel}")                      ///
    addnote("* p<0.10, ** p<0.05, *** p<0.01. Robust standard errors in parentheses." ///
            "Means for 5-year birth \$\times\$ state cohorts. Inverse-variance weighted.")

* ------------------------------------------------------------------------------
* All Economic Perception Channels (Appendix)
* ------------------------------------------------------------------------------

* Reference
eststo em_ref: areg v80 `gpr_core' ///
    `controls_socdem' ///
    [aw = inv_var_wt], absorb(cohort_id) vce(robust)
estadd local econ_ctrl "None"
estadd local cohort_fe "Yes"
estadd local controls  "Yes"
estadd local sample_r  "All waves"
estadd local weighting "Inverse variance"
estadd local waves     "1-5"

* Current general
eststo er_gen: areg v80 `gpr_core' ///
    `controls_socdem' econ_general ///
    [aw = inv_var_wt], absorb(cohort_id) vce(robust)
estadd local cohort_fe "Yes"
estadd local controls  "Yes"
estadd local weighting "Inverse variance"
estadd local waves     "1-5"

* Retrospective personal
eststo er_retro_pers: areg v80 `gpr_core' ///
    `controls_socdem' econ_retro_pers ///
    [aw = inv_var_wt], absorb(cohort_id) vce(robust)
estadd local cohort_fe "Yes"
estadd local controls  "Yes"
estadd local weighting "Inverse variance"
estadd local waves     "1-5"

* Retrospective general
eststo er_retro_gen: areg v80 `gpr_core' ///
    `controls_socdem' econ_retro_gen ///
    [aw = inv_var_wt], absorb(cohort_id) vce(robust)
estadd local cohort_fe "Yes"
estadd local controls  "Yes"
estadd local weighting "Inverse variance"
estadd local waves     "2-5"

* Prospective personal
eststo er_prosp_pers: areg v80 `gpr_core' ///
    `controls_socdem' econ_prosp_pers ///
    [aw = inv_var_wt], absorb(cohort_id) vce(robust)
estadd local cohort_fe "Yes"
estadd local controls  "Yes"
estadd local weighting "Inverse variance"
estadd local waves     "1-5"

* Prospective general
eststo er_prosp_gen: areg v80 `gpr_core' ///
    `controls_socdem' econ_prosp_gen ///
    [aw = inv_var_wt], absorb(cohort_id) vce(robust)
estadd local cohort_fe "Yes"
estadd local controls  "Yes"
estadd local weighting "Inverse variance"
estadd local waves     "1-5"

esttab em_ref er_gen er_retro_pers er_retro_gen er_prosp_pers er_prosp_gen ///
    using "$output/reg_v80_econ_allchannels.tex", replace ///
    keep(`gpr_core' econ_general econ_retro_pers econ_retro_gen ///
         econ_prosp_pers econ_prosp_gen) ///
    order(`gpr_core' econ_general econ_retro_pers econ_retro_gen ///
          econ_prosp_pers econ_prosp_gen) ///
    b(%9.3f) se(%9.3f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    nonote ///
    varlabels(`varlabels') ///
    stats(cohort_fe controls waves N r2_a, ///
          labels("Cohort FE" "Controls" "Waves" ///
                 "Cells" "Adj. R\$^2\$") ///
          fmt(0 0 0 0 3)) ///
    mtitles("Reference" "Current" "Retro. pers." "Retro. gen." ///
            "Prosp. pers." "Prosp. gen.") ///
    title("GPR on Tax–Benefit Preferences Controlling for All Economic Perception Channels (Pseudo Panel) \label{reg:v80econallchannels}") ///
    addnote("* p<0.10, ** p<0.05, *** p<0.01. Robust standard errors in parentheses." ///
            "Means for 5-year birth \$\times\$ state cohorts. Inverse-variance weighted.")
			
********************************************************************************
* Robustness Checks (Ch. 5)
********************************************************************************

// frame change pseudopanel

* ------------------------------------------------------------------------------
* Alternative Formative Exposure and Learning Mechanisms (Ch. 5.1)
* ------------------------------------------------------------------------------

local varlabels $vl_gpr_pp $vl_dem_pp $vl_fe_pp

* Baseline: 18–25
eststo fw_base: areg v80 GPR_DEU_std gpr_form_std GPR_x_form_c ///
    `controls_socdem' ///
    [aw = inv_var_wt], absorb(cohort_id) vce(robust)
estadd local window    "18-25"
estadd local cohort_fe "Yes"
estadd local controls  "Yes"

* Earlier onset: 15–25
eststo fw_1525: areg v80 GPR_DEU_std gpr_form_1525_std GPR_x_form_1525 ///
    `controls_socdem' ///
    [aw = inv_var_wt], absorb(cohort_id) vce(robust)
estadd local window    "15-25"
estadd local cohort_fe "Yes"
estadd local controls  "Yes"

* Extended window: 18–30
eststo fw_1830: areg v80 GPR_DEU_std gpr_form_1830_std GPR_x_form_1830 ///
    `controls_socdem' ///
    [aw = inv_var_wt], absorb(cohort_id) vce(robust)
estadd local window    "18-30"
estadd local cohort_fe "Yes"
estadd local controls  "Yes"

* Childhood: 0–18
eststo fw_0018: areg v80 GPR_DEU_std gpr_form_0018_std GPR_x_form_0018 ///
    `controls_socdem' ///
    [aw = inv_var_wt], absorb(cohort_id) vce(robust)
estadd local window    "0--18"
estadd local cohort_fe "Yes"
estadd local controls  "Yes"

* Full childhood + early adulthood: 0–30
eststo fw_0030: areg v80 GPR_DEU_std gpr_form_0030_std GPR_x_form_0030 ///
    `controls_socdem' ///
    [aw = inv_var_wt], absorb(cohort_id) vce(robust)
estadd local window    "0-30"
estadd local cohort_fe "Yes"
estadd local controls  "Yes"

* Full adult life (18 to interview year)
eststo fw_life: areg v80 GPR_DEU_std gpr_form_life_std GPR_x_form_life ///
    `controls_socdem' ///
    [aw = inv_var_wt], absorb(cohort_id) vce(robust)
estadd local window    "18-int. yr."
estadd local cohort_fe "Yes"
estadd local controls  "Yes"

* Standard export
/*esttab fw_base fw_1525 fw_1830 fw_0018 fw_0030 fw_life ///
    using "$output/rob_formative_windows.tex", replace ///
    keep(GPR_DEU_std ///
         gpr_form_std       gpr_form_1525_std  gpr_form_1830_std ///
         gpr_form_0018_std  gpr_form_0030_std ///
         gpr_form_life_std ///
         GPR_x_form_c       GPR_x_form_1525    GPR_x_form_1830 ///
         GPR_x_form_0018    GPR_x_form_0030 ///
         GPR_x_form_life) ///
    b(%9.3f) se(%9.3f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    nonote ///
    varlabels(`varlabels') ///
    stats(controls cohort_fe N r2_a, ///
          labels("Controls" "Cohort FE" "Cells" "Adj. R\$^2\$") ///
          fmt(0 0 0 3)) ///
    mtitles("18-25" "15-25" "18-30" "0-18" "0-30" "18-int.yr.") ///
    title("Sensitivity of Formative GPR to Alternative Exposure Window (Pseudo Panel) \label{rob:robformativewindows}") ///
    addnote("* p<0.10, ** p<0.05, *** p<0.01. Robust standard errors in parentheses." ///
            "Means for 5-year birth \$\times\$ state cohorts. Inverse-variance weighted.") */

* --- Alternative export for slimmer table ---
* Compact varlabels for this table only
local varlabels_fw ///
    GPR_DEU_std        "Current GPR (std.)" ///
    gpr_form_std       "\shortstack[l]{Formative GPR\\(18-25, std.)}" ///
    gpr_form_1525_std  "\shortstack[l]{Formative GPR\\(15-25, std.)}" ///
    gpr_form_1830_std  "\shortstack[l]{Formative GPR\\(18-30, std.)}" ///
    gpr_form_0018_std  "\shortstack[l]{Formative GPR\\(0-18, std.)}" ///
    gpr_form_0030_std  "\shortstack[l]{Formative GPR\\(0-30, std.)}" ///
    gpr_form_life_std  "\shortstack[l]{Formative GPR\\(18-life, std.)}" ///
    GPR_x_form_c       "\shortstack[l]{Current GPR\$\times\$\\(18-25)}" ///
    GPR_x_form_1525    "\shortstack[l]{Current GPR\$\times\$\\(15-25)}" ///
    GPR_x_form_1830    "\shortstack[l]{Current GPR\$\times\$\\(18-30)}" ///
    GPR_x_form_0018    "\shortstack[l]{Current GPR\$\times\$\\(0-18)}" ///
    GPR_x_form_0030    "\shortstack[l]{Current GPR\$\times\$\\(0-30)}" ///
    GPR_x_form_life    "\shortstack[l]{Current GPR\$\times\$\\(18-life)}"

esttab fw_base fw_1525 fw_1830 fw_0018 fw_0030 fw_life ///
    using "$output/rob_formative_windows.tex", replace ///
    keep(GPR_DEU_std ///
         gpr_form_std       gpr_form_1525_std  gpr_form_1830_std ///
         gpr_form_0018_std  gpr_form_0030_std ///
         gpr_form_life_std ///
         GPR_x_form_c       GPR_x_form_1525    GPR_x_form_1830 ///
         GPR_x_form_0018    GPR_x_form_0030 ///
         GPR_x_form_life) ///
    b(%9.3f) se(%9.3f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    nonote ///
    varlabels(`varlabels_fw') ///
    stats(controls cohort_fe N r2_a, ///
          labels("Controls" "Cohort FE" "Cells" "Adj. R\$^2\$") ///
          fmt(0 0 0 3)) ///
    mtitles("18-25" "15-25" "18-30" "0-18" "0-30" "18-int.yr.") ///
    title("Sensitivity of Formative GPR to Alternative Exposure Window (Pseudo Panel) \label{rob:robformativewindows}") ///
    addnote("* p<0.10, ** p<0.05, *** p<0.01. Robust standard errors in parentheses." ///
            "Means for 5-year birth \$\times\$ state cohorts. Inverse-variance weighted.")

* ------------------------------------------------------------------------------
* Sensitivity to the 2025 Survey Wave (Ch. 5.2)
* ------------------------------------------------------------------------------

frame change crosssection

local varlabels $vl_gpr_cs $vl_dem_cs $vl_misc

* --- Leave-one-wave-out matrix (used for coefficient plot in figures file) ---

matrix leaveout_mat = J(6, 3, .)  // rows 1–5: exclusions; row 6: all waves

* Row 6: all waves included (reference)
reg v80 c.GPR_DEU_std##c.gpr_form_std ///
    i.cohort i.bula i.d1 i.d5 i.d23, cluster(intmon)
matrix leaveout_mat[6, 1] = 0  // 0 = no exclusion placeholder
matrix leaveout_mat[6, 2] = _b[GPR_DEU_std]
matrix leaveout_mat[6, 3] = _se[GPR_DEU_std]

* Rows 1–5: exclude one wave at a time
local wave_years_lo 2009 2013 2017 2021 2025
forvalues w = 1/5 {
    local yr : word `w' of `wave_years_lo'
    reg v80 c.GPR_DEU_std##c.gpr_form_std ///
        i.cohort i.bula i.d1 i.d5 i.d23 ///
        if wave != `w', cluster(intmon)
    matrix leaveout_mat[`w', 1] = `yr'
    matrix leaveout_mat[`w', 2] = _b[GPR_DEU_std]
    matrix leaveout_mat[`w', 3] = _se[GPR_DEU_std]
}

* --- Wave fixed effects table ---

* Reference: no wave FE
eststo m_wfe_ref: reg v80 c.GPR_DEU_std##c.gpr_form_std i.cohort i.bula ///
    i.d1 i.d5 i.d23, cluster(intmon)
estadd local wave_fe       "No"
estadd local birth_year_fe "Generation"
estadd local state_fe      "Yes"
estadd local controls      "Yes"

* With wave FEs (wave 1 = 2009 omitted)
eststo m_wfe: reg v80 c.GPR_DEU_std##c.gpr_form_std i.cohort i.bula ///
    i.wave i.d1 i.d5 i.d23, cluster(intmon)
estadd local wave_fe       "Yes"
estadd local birth_year_fe "Generation"
estadd local state_fe      "Yes"
estadd local controls      "Yes"

esttab m_wfe_ref m_wfe using "$output/rob_v80_GPR_waveFE.tex", replace ///
    keep(GPR_DEU_std gpr_form_std c.GPR_DEU_std#c.gpr_form_std ///
         2.wave 3.wave 4.wave 5.wave) ///
    b(%9.3f) se(%9.3f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    nonote ///
    varlabels(`varlabels') ///
    stats(wave_fe birth_year_fe state_fe controls N r2_a, ///
          labels("Wave FE" "Birth-year FE" "State FE" ///
                 "Controls" "Observations" "Adj. R\$^2\$") ///
          fmt(0 0 0 0 0 3)) ///
    mtitles("Full reference model" "Wave FE") ///
    title("Sensitivity to Survey Waves: Individual-Level OLS With and Without Wave Fixed Effects \label{rob:v80GPRwavefe}") ///
    addnote("* p<0.10, ** p<0.05, *** p<0.01. Standard errors clustered on interview month level." ///
            "Wave 1 (2009) is the omitted base category.")

* Store wave FE coefficients for figures file; wave 1 set to zero (reference)
matrix wave_fe_mat = J(5, 3, .)
matrix wave_fe_mat[1, 1] = 2009
matrix wave_fe_mat[1, 2] = 0
matrix wave_fe_mat[1, 3] = 0

local wave_years 2013 2017 2021 2025
forvalues w = 2/5 {
    local yr : word `= `w' - 1' of `wave_years'
    matrix wave_fe_mat[`w', 1] = `yr'
    matrix wave_fe_mat[`w', 2] = _b[`w'.wave]
    matrix wave_fe_mat[`w', 3] = _se[`w'.wave]
}

* ------------------------------------------------------------------------------
* Tax Salience as a Potential Confound (Google Trends Analysis) (Ch. 5.3)
* ------------------------------------------------------------------------------

frame create gtrends
frame change gtrends

use "$data/gles_gpr_gt.dta", clear

local controls_gt i.d1 i.d5 i.d23
local varlabels $vl_gpr_cs $vl_dem_cs $vl_pol_cs $vl_gt

* Col 1: Survey salience item (v81) as benchmark
eststo sal_ref: reg v80 c.GPR_DEU_std##c.gpr_form_std ///
    `controls_gt' v81 ///
    i.birth_year i.bula, cluster(intmon_gles)
estadd local sal_measure  "v81 (survey)"
estadd local birth_year_fe "Gen."
estadd local state_fe      "Yes"
estadd local controls      "Yes"

* Col 2: GT normalised index replacing v81
eststo sal_gt1: reg v80 c.GPR_DEU_std##c.gpr_form_std ///
    `controls_gt' taxsal_norm_std ///
    i.birth_year i.bula, cluster(intmon_gles)
estadd local sal_measure  "GT norm."
estadd local birth_year_fe "Gen."
estadd local state_fe      "Yes"
estadd local controls      "Yes"

* Col 3: GT 6-month moving average
eststo sal_gt2: reg v80 c.GPR_DEU_std##c.gpr_form_std ///
    `controls_gt' taxsal_ma6_std ///
    i.birth_year i.bula, cluster(intmon_gles)
estadd local sal_measure  "GT MA6"
estadd local birth_year_fe "Gen."
estadd local state_fe      "Yes"
estadd local controls      "Yes"

esttab sal_ref sal_gt1 sal_gt2 ///
    using "$output/rob_gt_salience.tex", replace ///
    keep(GPR_DEU_std gpr_form_std ///
         c.GPR_DEU_std#c.gpr_form_std ///
         v81 taxsal_norm_std taxsal_ma6_std) ///
    b(%9.3f) se(%9.3f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    nonote ///
    varlabels(`varlabels') ///
    stats(birth_year_fe state_fe controls N r2_a, ///
          labels("Birth-year FE" "State FE" "Controls" ///
                 "Observations" "Adj. R\$^2\$") ///
          fmt(0 0 0 0 3)) ///
    mtitles("Tax–Ben. Salience" "GT norm." "GT 6-month m.a.") ///
    title("GPR on Tax-Benefit Preferences Controlling for Tax Salience: Survey Item and Google Trends Measures (Individual-Level) \label{rob:gtsal}") ///
    addnote("* p<0.10, ** p<0.05, *** p<0.01. Standard errors clustered on interview month level.")

* ------------------------------------------------------------------------------
* Alternative Dependent Variables (Ch. 5.4)
* ------------------------------------------------------------------------------

frame change pseudopanel

local varlabels $vl_gpr_pp $vl_dem_pp

* Col 0: v80 reference — full sample
eststo ref_si_f: areg v80 GPR_DEU_std gpr_form_std GPR_x_form_c ///
    `controls_socdem' ///
    [aw = inv_var_wt], absorb(cohort_id) vce(robust)
estadd local dv_label  "v80: tax--benefit trade-off"
estadd local waves     "1-5"
estadd local cohort_fe "Yes"
estadd local controls  "Yes"

/* Cols 1–3: restricted to waves 2–5; v72c and v72d not available in wave 1 */

* Col 1: v80 restricted to waves 2–5
eststo ref_si: areg v80 GPR_DEU_std gpr_form_std GPR_x_form_c ///
    `controls_socdem' ///
    if wave >= 2 & wave <= 5 ///
    [aw = inv_var_wt], absorb(cohort_id) vce(robust)
estadd local dv_label  "v80: tax--benefit trade-off"
estadd local waves     "2-5"
estadd local cohort_fe "Yes"
estadd local controls  "Yes"

* Col 2: v72c — state out of economy
eststo dv_si: areg v72c GPR_DEU_std gpr_form_std GPR_x_form_c ///
    `controls_socdem' ///
    if wave >= 2 & wave <= 5 ///
    [aw = inv_var_wt], absorb(cohort_id) vce(robust)
estadd local dv_label  "v72c: state out of economy"
estadd local waves     "2-5"
estadd local cohort_fe "Yes"
estadd local controls  "Yes"

* Col 3: v72d — income redistribution
eststo dv_red: areg v72d GPR_DEU_std gpr_form_std GPR_x_form_c ///
    `controls_socdem' ///
    if wave >= 2 & wave <= 5 ///
    [aw = inv_var_wt], absorb(cohort_id) vce(robust)
estadd local dv_label  "v72d: income redistribution"
estadd local waves     "2-5"
estadd local cohort_fe "Yes"
estadd local controls  "Yes"

* Result table (lean)
local varlabels_dv ///
    GPR_DEU_std  "Mean curr. GPR (std.)" ///
    gpr_form_std "\shortstack[l]{Mean form. GPR\\(18-25, std.)}" ///
    GPR_x_form_c "\shortstack[l]{Mean curr. GPR\\ $\times$ formative GPR}"

esttab ref_si_f ref_si dv_si dv_red ///
    using "$output/rob_dv_state_redist.tex", replace ///
    keep(GPR_DEU_std gpr_form_std GPR_x_form_c) ///
    b(%9.3f) se(%9.3f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    nonote ///
    varlabels(`varlabels_dv') ///
    stats(waves cohort_fe controls N r2_a, ///
          labels("Waves" "Cohort FE" "Controls" ///
                 "Cells" "Adj. R\$^2\$") ///
          fmt(0 0 0 0 3)) ///
    mtitles("Tax–Ben., full" "Tax-Ben., restr." "State in Econ." "Redistrib.") ///
    title("GPR on Alternative Fiscal Preference Outcomes: State Intervention and Income Redistribution (Pseudo Panel) \label{rob:dvstateredistpanel}") ///
    addnote("* p<0.10, ** p<0.05, *** p<0.01. Robust standard errors in parentheses." ///
            "Means for 5-year birth \$\times\$ state cohorts. Inverse-variance weighted.")
			
* ------------------------------------------------------------------------------
* Sample Restrictions for Geographical and Methodological Robustness (Ch. 5.5)
* ------------------------------------------------------------------------------

local varlabels $vl_gpr_pp $vl_dem_pp

* --- East German cohort exclusions (Ch. 5.5.1) ---

/* East German states (excl. Berlin): 12=BB, 13=MV, 14=Sachsen,
   15=Sachsen-Anhalt, 16=Thüringen */
gen byte east_bula = inlist(bula, 12, 13, 14, 15, 16)
label var east_bula "1 = East German state (excl. Berlin)"

* Reference: full sample
eststo sr_ref: areg v80 GPR_DEU_std gpr_form_std GPR_x_form_c ///
    `controls_socdem' ///
    [aw = inv_var_wt], absorb(cohort_id) vce(robust)
estadd local restriction "None (full sample)"
estadd local cohort_fe   "Yes"
estadd local waves       "All (1–5)"
estadd local controls    "Yes"
estadd local sample_r    "Full"

* Restriction A: drop East Germans born before 1972 (formative years pre-reunification)
eststo sr_reunif_a: areg v80 GPR_DEU_std gpr_form_std GPR_x_form_c ///
    `controls_socdem' ///
    if !(east_bula == 1 & birth_5yr < 1972) ///
    [aw = inv_var_wt], absorb(cohort_id) vce(robust)
estadd local restriction "Drop East, born <1972"
estadd local cohort_fe   "Yes"
estadd local waves       "All (1–5)"
estadd local controls    "Yes"

* Restriction B: West Germans only
eststo sr_reunif_b: areg v80 GPR_DEU_std gpr_form_std GPR_x_form_c ///
    `controls_socdem' ///
    if east_bula == 0 ///
    [aw = inv_var_wt], absorb(cohort_id) vce(robust)
estadd local restriction "West Germans only"
estadd local cohort_fe   "Yes"
estadd local waves       "All (1–5)"
estadd local controls    "Yes"

esttab sr_ref sr_reunif_a sr_reunif_b using "$output/rob_samplesplit_reunif.tex", replace ///
    keep(GPR_DEU_std gpr_form_std GPR_x_form_c) ///
    b(%9.3f) se(%9.3f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    nonote ///
    varlabels(`varlabels') ///
    stats(cohort_fe controls N r2_a, ///
          labels("Cohort FE" "Controls" ///
                 "Cells" "Adj. R\$^2\$") ///
          fmt(0 0 0 3)) ///
    mtitles("Full sample" "Drop East <1972" "West only") ///
    title("Sensitivity to East German Cohorts: Sample Splits Around German Reunification (Pseudo Panel) \label{rob:samplesplitreunif}") ///
    addnote("* p<0.10, ** p<0.05, *** p<0.01. Robust standard errors in parentheses." ///
            "Means for 5-year birth \$\times\$ state cohorts. Inverse-variance weighted.")

* --- Pre-1985 GPR restriction (Ch. 5.5.2) ---

/* Historical GPR index (GPRHC) used for pre-1985 months; born ≥1967 ensures
   all formative years (18–25) fall within the post-1985 country-level index */
eststo sr_post85: areg v80 GPR_DEU_std gpr_form_std GPR_x_form_c ///
    `controls_socdem' ///
    if birth_5yr >= 1967 ///
    [aw = inv_var_wt], absorb(cohort_id) vce(robust)
estadd local restriction "Born ≥1967 (form. yrs ≥1985)"
estadd local cohort_fe   "Yes"
estadd local waves       "All (1–5)"
estadd local controls    "Yes"

esttab sr_ref sr_post85 using "$output/rob_samplesplit_1985.tex", replace ///
    keep(GPR_DEU_std gpr_form_std GPR_x_form_c `controls_socdem') ///
    b(%9.3f) se(%9.3f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    nonote ///
    varlabels(`varlabels') ///
    stats(cohort_fe controls N r2_a, ///
          labels("Cohort FE" "Controls" ///
                 "Cells" "Adj. R\$^2\$") ///
          fmt(0 0 0 3)) ///
    mtitles("Full sample" "Born ≥1967") ///
    title("Sensitivity to GPR Index Construction: Restricting to Cohorts Whose Formative Years Fall Within the Country-Level Index (Pseudo Panel) \label{rob:samplesplit1985}") ///
    addnote("* p<0.10, ** p<0.05, *** p<0.01. Robust standard errors in parentheses." ///
            "Means for 5-year birth \$\times\$ state cohorts. Inverse-variance weighted.")

* --- Pre/post-election sample split (Ch. 5.5.3) ---

frame create pseudopanel_sample
frame change pseudopanel_sample

use "$data/pseudo_panel_5yr_bula_sample.dta", clear

local varlabels $vl_gpr_pp $vl_dem_pp $vl_misc

* M1: sample-level panel (9 time points), no post_election control
eststo pp_samp: areg v80 GPR_DEU_std gpr_form_std GPR_x_form_c ///
    `controls_socdem' ///
    [aw = inv_var_wt], absorb(cohort_id) vce(robust)
estadd local time_dim  "Sample (9 points)"
estadd local post_ctrl "No"
estadd local sample_r  "Full"
estadd local cohort_fe "Yes"
estadd local controls  "Yes"

* M2: + post_election as control
eststo pp_post: areg v80 GPR_DEU_std gpr_form_std GPR_x_form_c ///
    post_election `controls_socdem' ///
    [aw = inv_var_wt], absorb(cohort_id) vce(robust)
estadd local time_dim  "Sample (9 points)"
estadd local post_ctrl "Yes"
estadd local sample_r  "Full"
estadd local cohort_fe "Yes"
estadd local controls  "Yes"

* M3: pre-election samples only
eststo pp_pre: areg v80 GPR_DEU_std gpr_form_std GPR_x_form_c ///
    `controls_socdem' ///
    if post_election == 0 ///
    [aw = inv_var_wt], absorb(cohort_id) vce(robust)
estadd local time_dim  "Sample (4 pre)"
estadd local post_ctrl "N/A"
estadd local sample_r  "Pre-elec."
estadd local cohort_fe "Yes"
estadd local controls  "Yes"

* M4: post-election samples only
eststo pp_postonl: areg v80 GPR_DEU_std gpr_form_std GPR_x_form_c ///
    `controls_socdem' ///
    if post_election == 1 ///
    [aw = inv_var_wt], absorb(cohort_id) vce(robust)
estadd local time_dim  "Sample (5 post)"
estadd local post_ctrl "N/A"
estadd local sample_r  "Post-elec."
estadd local cohort_fe "Yes"
estadd local controls  "Yes"

* Results (lean)
local varlabels_pp ///
    GPR_DEU_std    "Mean current GPR (std.)" ///
    gpr_form_std   "\shortstack[l]{Mean formative GPR\\(18-25, std.)}" ///
    GPR_x_form_c   "\shortstack[l]{Mean current GPR\\ $\times$ formative GPR}" ///
    post_election  "\shortstack[l]{Post-election\\ sample}" ///
    lower_class_subj "\shortstack[l]{(Share of)\\ subj. lower class}" ///
	female           "(Share of) female" ///
    abitur           "(Share of) Abitur" ///

esttab sr_ref pp_samp pp_post pp_pre pp_postonl using "$output/rob_prepost_sample.tex", replace ///
    keep(GPR_DEU_std gpr_form_std GPR_x_form_c post_election `controls_socdem') ///
    b(%9.3f) se(%9.3f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    nonote ///
    varlabels(`varlabels_pp') ///
    stats(sample_r cohort_fe controls N r2_a, ///
          labels("Sample" "Cohort FE" "Controls" "Cells" "Adj. R\$^2\$") ///
          fmt(0 0 0 0 3)) ///
    mtitles("Reference" "By sample" "Post ctrl." "Pre only" "Post only") ///
    title("Sensitivity to Survey Timing and Cohort Aggregation method: Pre- vs. Post-Election Sample Splits and Sample-Level Pseudo Panel \label{rob:prepostsample}") ///
    addnote("* p<0.10, ** p<0.05, *** p<0.01. Robust standard errors in parentheses." ///
            "Means for 5-year birth \$\times\$ state cohorts. Inverse-variance weighted.")

* ------------------------------------------------------------------------------
* Ordered Logit as a Check on Scale Cardinality (Ch. 5.6)
* ------------------------------------------------------------------------------

frame change crosssection

local varlabels $vl_gpr_cs $vl_dem_cs

* OLS baseline (identical spec to M6)
eststo m_ols: reg v80 c.GPR_DEU_std##c.gpr_form_std ///
    i.cohort i.bula i.d1 i.d5 i.d23, cluster(intmon)
estadd local birth_year_fe "Generation"
estadd local state_fe      "Yes"
estadd local controls      "Yes"
estadd local estimator     "OLS"

* Ordered logit: exact replication of OLS spec above
eststo m_ologit: ologit v80 c.GPR_DEU_std##c.gpr_form_std ///
    i.cohort i.bula i.d1 i.d5 i.d23, cluster(intmon)
estadd local birth_year_fe "Generation"
estadd local state_fe      "Yes"
estadd local controls      "Yes"
estadd local estimator     "Ordered logit"

esttab m_ols m_ologit using "$output/rob_orderedlogit_ols.tex", replace ///
    keep(GPR_DEU_std gpr_form_std c.GPR_DEU_std#c.gpr_form_std) ///
    b(%9.3f) se(%9.3f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    nonote ///
    varlabels(`varlabels') ///
    stats(estimator birth_year_fe state_fe controls N r2_a, ///
          labels("Estimator" "Birth-year FE" "State FE" ///
                 "Controls" "Observations" "Adj. R\$^2\$") ///
          fmt(0 0 0 0 0 3)) ///
    mtitles("Standard OLS" "Ordered logit") ///
    title("Sensitivity to Scale Cardinality Assumption: OLS vs. Ordered Logit for Tax-Benefit Preferences (Individual-Level) \label{rob:orderedlogitols}") ///
    addnote("* p<0.10, ** p<0.05, *** p<0.01. Standard errors clustered on interview month level." ///
            "Ordered logit coefficients are log-odds (proportional odds).")

********************************************************************************
* END OF FILE
********************************************************************************
