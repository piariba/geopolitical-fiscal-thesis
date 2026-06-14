********************************************************************************
* PROJECT:  Budgeting for Uncertainty in Taxing Times (MSc Thesis, PPA, Bocconi)
* FILE:     figures_geopoliticalfiscal_thesis.do
* PURPOSE:  Figures
* AUTHOR:   Pia Riepl-Bauer
* MODIFIED: 2026-06-09

/* HOW TO USE: Run dataprep_geopoliticalfiscal_thesis.do and
regressions_geopoliticalfiscal_thesis.do FIRST so all datasets and eststo-stored
estimates are in memory. */
********************************************************************************

* --- Install packages ---
//ssc install coefplot
//ssc install blindschemes
//ssc install ridgeline
//ssc install palettes, replace
//ssc install colrspace, replace
//ssc install heatplot, replace

* Set colour scheme and font
set scheme plotplain // replace with s2mono for greyscale
graph set window fontface "Arial"

********************************************************************************
* Data Presentation (Ch. 3)
********************************************************************************

* ------------------------------------------------------------------------------
* Summary Statistics: Individual-Level Estimation Sample
* ------------------------------------------------------------------------------

frame change crosssection

* Define required labels and apply
local vl_sumstat ///
    v80          "Tax-social benefit preference"          ///
    GPR_DEU_std  "Current GPR (std.)"         ///
    gpr_form_std "Formative GPR 18-25 (std.)" ///
    d1           "Gender"                     ///
    d5           "School education"           ///
    d23          "Subjective class"                ///
    v81          "Tax-social benefit salience"       ///
    v72c         "State intervention in economy preference"   ///
    v72d         "Income redistribution preference"      ///
    v96          "Econ. perception general (current)"         ///
    v95          "Econ. perception personal (current)"        ///
    v102a        "Econ. perception general (retrospective)"        ///
    v101         "Econ. perception personal (retrospective)"       ///
    v100         "Econ. perception general (prospective)"        ///
    v99          "Econ. perception personal (prospective)"

local vl : copy local vl_sumstat
while `"`vl'"' != "" {
    gettoken vname  vl : vl
    gettoken vlabel vl : vl
    cap label var `vname' `"`vlabel'"'
}

* Variables used
local varlist v80 GPR_DEU_std gpr_form_std d1 d5 d23 v81 ///
	  v72c v72d v96 v95 v102a v101 v100 v99

local k : word count `varlist'
matrix S = J(`k', 5, .)

local i = 1
foreach v of local varlist {
    quietly summarize `v'
    matrix S[`i', 1] = r(mean)
    matrix S[`i', 2] = r(sd)
    matrix S[`i', 3] = r(min)
    matrix S[`i', 4] = r(max)
    matrix S[`i', 5] = r(N)
    local i = `i' + 1
}

matrix rownames S = `varlist'
matrix colnames S = Mean SD Min Max N

local outfile "$output/tab_summary_stats_indiv.tex"
file open fh using "`outfile'", write replace

file write fh "\begin{table}[htbp]" _n
file write fh "\centering" _n
file write fh "\caption{Summary Statistics: Individual-Level Estimation Sample \label{tab:sumstatgles_css}}" _n
file write fh "\begin{tabular}{lrrrrr}" _n
file write fh "\toprule" _n
file write fh "& Mean & SD & Min & Max & \multicolumn{1}{c}{\textit{N}} \\" _n
file write fh "\midrule" _n

local i = 1
foreach v of local varlist {

    if `i' == 1  file write fh "\multicolumn{6}{l}{\textit{Panel A: Outcome variable}} \\" _n
    if `i' == 2  file write fh "\midrule" _n
    if `i' == 2  file write fh "\multicolumn{6}{l}{\textit{Panel B: Geopolitical risk}} \\" _n
    if `i' == 4  file write fh "\midrule" _n
    if `i' == 4  file write fh "\multicolumn{6}{l}{\textit{Panel C: Socio-demographic controls}} \\" _n
    if `i' == 7  file write fh "\midrule" _n
    if `i' == 7  file write fh "\multicolumn{6}{l}{\textit{Panel D: Alternative outcome and control variables}} \\" _n
    if `i' == 10 file write fh "\midrule" _n
    if `i' == 10 file write fh "\multicolumn{6}{l}{\textit{Panel E: Economic perceptions}} \\" _n

    local vlab : variable label `v'
    local mean = S[`i', 1]
    local sd   = S[`i', 2]
    local mn   = S[`i', 3]
    local mx   = S[`i', 4]
    local n    = S[`i', 5]

    file write fh "\quad `vlab' & `=string(`mean', "%9.2f")' & `=string(`sd', "%9.2f")' & `=string(`mn', "%9.2f")' & `=string(`mx', "%9.2f")' & `=string(`n', "%9.0fc")' \\" _n

    local i = `i' + 1
}

file write fh "\bottomrule" _n
file write fh "\end{tabular}" _n
file write fh "\begin{minipage}{\linewidth}" _n
file write fh "\vspace{4pt}" _n
file write fh "\footnotesize" _n
file write fh "\textit{Notes:} Data from pre- and post-election cross-section surveys of the German Longitudinal Election Study 2009-2025 \parencite{glesGLESCrossSection200920212024, glesZA10100GLESCrossSection2025a} and the Germany-specific GPR index \parencite{caldaraMeasuringGeopoliticalRisk2022}. Full description of availability and scales of GLES survey items in Table~\ref{tab:gles_variables}. Panel A: all non-missing observations on the primary outcome. Panel B: full analytic sample entering most saturated model; GPR variables standardised prior to estimation. Panels D-E: variables not fielded in all waves); \textit{N} therefore differs across panels." _n
file write fh "\end{minipage}" _n
file write fh "\end{table}" _n

file close fh
display as text "Table written to: `outfile'"

* ------------------------------------------------------------------------------
* Descriptive Statistics
* ------------------------------------------------------------------------------

* --- Difference between wave 4 (2021) and wave 5 (2025) in SD units ---
//frame change crosssection

quietly sum GPR_DEU_std if wave == 4
scalar mean_w4_std = r(mean)
quietly sum GPR_DEU_std if wave == 5
scalar mean_w5_std = r(mean)
scalar diff_in_sd = mean_w5_std - mean_w4_std

di as text "Wave 4 (2021) mean GPR: " mean_w4_std
di as text "Wave 5 (2025) mean GPR: " mean_w5_std
di as text "Difference in SD units: " diff_in_sd

* --- Mean GPR per birth year cohort for interpretation ---
frame change pseudopanel

quietly sum gpr_form_std if birth_5yr == 1975
scalar mean_form_1975 = r(mean)

quietly sum gpr_form_std if birth_5yr == 1995
scalar mean_form_1995 = r(mean)

scalar diff_form_sd = mean_form_1995 - mean_form_1975

di as text "1975 cohort mean formative GPR (std.): " mean_form_1975
di as text "1990 cohort mean formative GPR (std.): " mean_form_1995
di as text "Difference in SD units (1995 - 1975):  " diff_form_sd

* ------------------------------------------------------------------------------
* Distribution (Ridgeline) of Tax-Benefit Preference by Survey Wave
* ------------------------------------------------------------------------------

frame change crosssection

* Label waves with election years for readable axis
label define wlbl 1 "2009" 2 "2013" 3 "2017" 4 "2021" 5 "2025", replace
label values wave wlbl

ridgeline v80, by(wave) ///
    bwidth(0.5)         ///
    overlap(3)          ///
    alpha(70)           ///
    normalize(global)   ///
    yline               ///
    xlabel(1(1)11)      ///
    xtitle("1 = less taxes, 11 = more social benefits", size(small)) ///
    note(" ", ///
         size(vsmall)) ///
    graphregion(color(white)) bgcolor(white)

graph export "$output/fig_tax-benefit_ridgeline.pdf", replace

* ------------------------------------------------------------------------------
* GPR Time Series with GLES Fieldwork Windows
* ------------------------------------------------------------------------------

frame create gpr
frame change gpr

* Load the FULL GPR time series
use "$data/gpr_temp.dta", clear
keep if intmon >= ym(2008,1)

* Generate shading variables
gen zero      = 0
gen shade_w1 = GPR_DEU if inrange(intmon, ym(2009,8),  ym(2009,11))
gen shade_w2 = GPR_DEU if inrange(intmon, ym(2013,7),  ym(2013,12))
gen shade_w3 = GPR_DEU if inrange(intmon, ym(2017,7),  ym(2017,12))
gen shade_w4 = GPR_DEU if inrange(intmon, ym(2021,8),  ym(2021,11))
gen shade_w5 = GPR_DEU if inrange(intmon, ym(2025,2),  ym(2025,4))
gen zero_w1  = 0 if inrange(intmon, ym(2009,8),  ym(2009,11))
gen zero_w2  = 0 if inrange(intmon, ym(2013,7),  ym(2013,12))
gen zero_w3  = 0 if inrange(intmon, ym(2017,7),  ym(2017,12))
gen zero_w4  = 0 if inrange(intmon, ym(2021,8),  ym(2021,11))
gen zero_w5  = 0 if inrange(intmon, ym(2025,2),  ym(2025,4))

* Set up graph
twoway ///
    (rarea zero_w1 shade_w1 intmon, fcolor(gs14) lwidth(none)) ///
    (rarea zero_w2 shade_w2 intmon, fcolor(gs14) lwidth(none)) ///
    (rarea zero_w3 shade_w3 intmon, fcolor(gs14) lwidth(none)) ///
    (rarea zero_w4 shade_w4 intmon, fcolor(gs14) lwidth(none)) ///
    (rarea zero_w5 shade_w5 intmon, fcolor(gs14) lwidth(none)) ///
    (line GPR_DEU intmon, lcolor(black) lwidth(medthin)), ///
    xline(`=ym(2022,2)', lpattern(dash) lcolor(maroon) lwidth(thin)) ///
	text(100 `=ym(2022,6)' "Ukraine" "invasion", ///
         size(vsmall) color(maroon)) ///
    text(30 `=ym(2009,10)' "W1", size(vsmall) color(gs6)) ///
    text(30 `=ym(2013,9)'  "W2", size(vsmall) color(gs6)) ///
    text(30 `=ym(2017,9)'  "W3", size(vsmall) color(gs6)) ///
    text(30 `=ym(2021,9)'  "W4", size(vsmall) color(gs6)) ///
    text(30 `=ym(2025,2)'  "W5", size(vsmall) color(gs6)) ///
    xtitle("") ytitle("GPR index (Germany)") ///
    xlabel( ///
        `=ym(2009,1)' "2009" ///
        `=ym(2013,1)' "2013" `=ym(2017,1)' "2017" ///
        `=ym(2021,1)' "2021" `=ym(2025,1)' "2025", ///
        angle(0)) ///
    legend(order(1 "GLES fieldwork windows" ///
                 6 "Monthly GPR") ///
           rows(1) size(vsmall) position(6)) ///
    graphregion(color(white)) bgcolor(white)
	
graph export "$output/fig_GPR_timeseries.pdf", replace
    
* ------------------------------------------------------------------------------
* Mean Formative GPR by Birth Year
* ------------------------------------------------------------------------------

frame change crosssection

* Collapse to one observation per birth year
collapse (mean) gpr_formative (count) n = v80, by(birth_year)

drop if birth_year <= 1927

twoway ///
    (scatter gpr_formative birth_year [w=n], ///
        msymbol(Oh) mcolor(gs8) msize(small)) ///
    (lowess gpr_formative birth_year, ///
        lcolor(navy) lwidth(medium)), ///
    xlabel(1930(10)2000, angle(0)) ///
    xtitle("Birth year") ///
    ytitle("Average Formative GPR, ages 18-25") ///
	legend(off) ///
    graphregion(color(white)) bgcolor(white)

graph export "$output/fig_formative_gpr_birthyear.pdf", replace

********************************************************************************
* Robustness Checks Sensitivity to 2025 Survey Wave (Ch. 5.2)
********************************************************************************

//frame change crosssection

* ------------------------------------------------------------------------------
* Leave-One-Wave-Out Estimate for GPR (Cross-Section)
* ------------------------------------------------------------------------------

preserve
    clear
    svmat leaveout_mat, names(col)
    rename (c1 c2 c3) (year b se)

    gen ci_lo = b - 1.96 * se
    gen ci_hi = b + 1.96 * se

    * Replace continuous year with evenly-spaced index
    gen x = .
    replace x = 1 if year == 0   // "All waves"
    replace x = 2 if year == 2009
    replace x = 3 if year == 2013
    replace x = 4 if year == 2017
    replace x = 5 if year == 2021
    replace x = 6 if year == 2025

    gen full_samp = (year == 0)
    gen zero = 0

    twoway ///
        (rcap ci_lo ci_hi x if !full_samp, ///
            lcolor(maroon) lwidth(medium)) ///
        (scatter b x if !full_samp, ///
            msymbol(S) mcolor(maroon) msize(medlarge)) ///
        (rcap ci_lo ci_hi x if full_samp, ///
            lcolor(navy) lwidth(medium)) ///
        (scatter b x if full_samp, ///
            msymbol(O) mcolor(navy) msize(medlarge)) ///
        (line zero x, ///
            lpattern(dash) lcolor(gs10) lwidth(thin)), ///
        xlabel(1 "All waves" 2 "Ex. 2009" 3 "Ex. 2013" ///
               4 "Ex. 2017" 5 "Ex. 2021" 6 "Ex. 2025", ///
               angle(40) labsize(small)) ///
        ylabel(, format(%9.2f)) ///
        ytitle("Current GPR (std.)", size(small)) ///
        xtitle("") ///
        title("", size(medsmall)) ///
        subtitle("", size(small)) ///
        note("", ///
             size(vsmall)) ///
        legend(order(2 "Leave-one-out" 4 "Full sample") ///
            pos(6) rows(1) size(small)) ///
        graphregion(color(white)) bgcolor(white)
		
    graph export "$output/fig_leaveout_wave_gpr.pdf", replace
restore

* ------------------------------------------------------------------------------
* Survey Wave FE coefficients (Cross-Section)
* ------------------------------------------------------------------------------

preserve
    clear
    svmat wave_fe_mat, names(col)
    rename (c1 c2 c3) (year b se)

    gen ci_lo = b - 1.96 * se
    gen ci_hi = b + 1.96 * se
    gen zero  = 0

    * Label 2009 as reference
    gen ref = (year == 2009)

    twoway ///
        (rcap ci_lo ci_hi year if !ref, ///
            lcolor(navy) lwidth(medium)) ///
        (scatter b year if !ref, ///
            msymbol(O) mcolor(navy) msize(medlarge)) ///
        (scatter b year if ref, ///
            msymbol(O) mcolor(gs10) msize(medlarge)) ///
        (line zero year, ///
            lpattern(dash) lcolor(gs10) lwidth(thin)), ///
        xlabel(2009 2013 2017 2021 2025, angle(0)) ///
        xscale(range(2007 2027)) ///
        ylabel(, format(%9.2f)) ///
        ytitle("Wave FE coefficient (ref: 2009)", size(small)) ///
        xtitle("Survey wave", size(small)) ///
        title("", size(medsmall)) ///
        subtitle("", size(small)) ///
        note("", size(vsmall)) ///
        legend(off) ///
        graphregion(color(white)) bgcolor(white)

    graph export "$output/fig_wave_fe_crosssection.pdf", replace
restore

********************************************************************************
* END OF FILE
********************************************************************************
