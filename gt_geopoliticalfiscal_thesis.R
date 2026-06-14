################################################################################
# PROJECT:  Budgeting for Uncertainty in Taxing Times: How Geopolitical Risk 
  # Shapes Fiscal Policy Preferences through Economic Anxiety and Political 
  # Learning. Survey Evidence from Germany, 2009-2025 (MSc Thesis, PPA, Bocconi)

# FILE:     gt_geopoliticalfiscal_thesis.R
# PURPOSE:	Pulling Google Trends data
# AUTHOR:   Pia Riepl-Bauer
# MODIFIED: 2026-06-09
################################################################################

rm(list = ls())
setwd("/Users/piarieplbauer/Library/Mobile Documents/com~apple~CloudDocs/1 Studium/PPA Master/MSc Thesis/data/GT")

#install.packages(c("gtrendsR", "tidyverse", "haven", "lubridate", "zoo"))

library(gtrendsR)    # Google Trends API wrapper
library(tidyverse)   # dplyr, tidyr, ggplot2, readr, purrr
library(haven)       # write_dta() — Stata .dta export
library(lubridate)   # date handling
library(zoo)         # rollmean() for smoothing

# Setup GT trends: date window
TIME_START  <- "2009-01-01"
TIME_END    <- "2025-06-30"
time_window <- paste(TIME_START, TIME_END)   # gtrendsR format: "YYYY-MM-DD YYYY-MM-DD"

GEO <- "DE"   # Germany national; subregion data pulled separately below

# TAX AND WELFARE STATE SALIENCE ###############################################
# Term List --------------------------------------------------------------------

# All 20 terms in a named vector (German search string → English label)
TERMS_NAMED <- c(
  "Steuerlast"           = "Tax burden",
  "Steuerbelastung"      = "Tax load / tax pressure",
  "Abgabenlast"          = "Total contribution burden (taxes + social contributions)",
  "Abgabenquote"         = "Tax-and-contribution ratio",
  "Steuern senken"       = "Cut taxes",
  "Steuern Deutschland"  = "Taxes Germany",
  "Einkommensteuer"      = "Income tax",
  "Einkommensteuertarif" = "Income tax schedule / rate structure",
  "Spitzensteuersatz"    = "Top marginal income tax rate",
  "Reichensteuer"        = "Wealth / millionaires' tax",
  "Kalte Progression"    = "Bracket creep",
  "Steuerverschwendung"  = "Wasteful spending of tax money",
  "Steuergerechtigkeit"  = "Tax fairness",
  "Steuererhöhung"       = "Tax increase",
  "Steuersenkung"        = "Tax cut",
  "Solidaritätszuschlag" = "Solidarity surcharge (Soli)",
  "Steuerreform"         = "Tax reform",
  "Lohnsteuer"           = "Wage tax / payroll income tax",
  "Steuerdruck"          = "Tax pressure",
  "hohe Steuern"         = "High taxes"
)

terms_de <- names(TERMS_NAMED)   # German strings (what we send to GT)
n_terms  <- length(terms_de)     # 20

# Set anchor -------------------------------------------------------------------
ANCHOR <- "Steuerlast"   # anchor term (also included in term list above)

# Remove anchor from the list of "other" terms (it goes in every batch)
other_terms <- terms_de[terms_de != ANCHOR]   # 19 terms

# Split into batches of 4 (each batch + anchor = 5 for one GT call)
batch_size <- 4
batches    <- split(other_terms,
                    ceiling(seq_along(other_terms) / batch_size))
# Result: 5 batches (4+4+4+4+3, last batch has 3 other terms + anchor = 4 total)

# GT trends wrapper function
safe_gtrends <- function(keyword, geo, time, retries = 3, sleep_base = 60) {
  for (attempt in seq_len(retries)) {
    tryCatch({
      result <- gtrends(keyword    = keyword,
                        geo        = geo,
                        time       = time,
                        onlyInterest = TRUE)
      Sys.sleep(sleep_base + runif(1, 0, 15))
      return(result)
    }, error = function(e) {
      msg <- conditionMessage(e)
      cat(sprintf("[Attempt %d/%d] Error for '%s': %s\n",
                  attempt, retries,
                  paste(keyword, collapse = " + "), msg))
      if (attempt < retries) Sys.sleep(sleep_base * attempt)
    })
  }
  stop(sprintf("All %d attempts failed for: %s",
               retries, paste(keyword, collapse = " + ")))
}

# Fetch GT data ----------------------------------------------------------------

# Anchor standalone
anchor_raw <- safe_gtrends(keyword = ANCHOR, geo = GEO, time = time_window)

anchor_national <- anchor_raw$interest_over_time %>%
  as_tibble() %>%
  transmute(
    date   = as.Date(date),
    term   = keyword,
    hits   = suppressWarnings(as.numeric(hits))  # "<1" → NA, handled below
  ) %>%
  replace_na(list(hits = 0))   # treat "<1" as 0 for index construction

# Save raw anchor
write_csv(anchor_national,
          file.path("raw_anchor_national.csv"))

# Fetch each batch (4 new terms + anchor) --------------------------------------

batch_results <- list()

for (i in seq_along(batches)) {
  batch_terms <- c(batches[[i]], ANCHOR)
  cat(sprintf("  Batch %d/%d: %s\n", i, length(batches),
              paste(batch_terms, collapse = " | ")))
  
  raw <- safe_gtrends(keyword = batch_terms, geo = GEO, time = time_window)
  
  batch_results[[i]] <- raw$interest_over_time %>%
    as_tibble() %>%
    transmute(
      date  = as.Date(date),
      term  = keyword,
      hits  = suppressWarnings(as.numeric(hits))
    ) %>%
    replace_na(list(hits = 0))
}

# Save raw batch results
saveRDS(batch_results, file.path("raw_batch_results.rds"))

# Rescale batches using anchor ratios ------------------------------------------

rescale_batch <- function(batch_df, anchor_standalone_df) {
  # Extract anchor column from this batch
  anchor_in_batch <- batch_df %>%
    filter(term == ANCHOR) %>%
    select(date, anchor_batch = hits)
  
  # Other terms in this batch
  others <- batch_df %>%
    filter(term != ANCHOR)
  
  # Join anchor-in-batch and standalone anchor
  others %>%
    left_join(anchor_in_batch, by = "date") %>%
    left_join(anchor_standalone_df %>% select(date, anchor_standalone = hits),
              by = "date") %>%
    mutate(
      ratio    = if_else(anchor_batch > 0, hits / anchor_batch, 0),
      rescaled = ratio * anchor_standalone
    ) %>%
    select(date, term, hits_raw = hits, rescaled)
}

rescaled_list <- map(batch_results, rescale_batch,
                     anchor_standalone_df = anchor_national)

# Also add anchor itself (rescaled = standalone hits, ratio = 1)
anchor_rescaled <- anchor_national %>%
  mutate(hits_raw = hits, rescaled = hits) %>%
  select(date, term, hits_raw, rescaled)

# Combine everything
all_terms_rescaled <- bind_rows(rescaled_list, anchor_rescaled) %>%
  arrange(term, date)

# Save rescaled series
write_csv(all_terms_rescaled,
          file.path("all_terms_rescaled_national.csv"))

# Construct unweighted national, monthly average -------------------------------

taxation_gt_salience_national <- all_terms_rescaled %>%
  group_by(date) %>%
  summarise(
    n_terms_obs   = n(),
    index_raw     = mean(rescaled, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    # Normalise to 0–100
    taxsal_min  = min(index_raw),
    taxsal_max  = max(index_raw),
    taxsal_norm = (index_raw - taxsal_min) / (taxsal_max - taxsal_min) * 100,
    # 3-month and 6-month rolling means for smoothing
    taxsal_ma3  = rollmean(taxsal_norm, k = 3, fill = NA, align = "right"),
    taxsal_ma6  = rollmean(taxsal_norm, k = 6, fill = NA, align = "right"),
    # Year-month for Stata merge
    year  = year(date),
    month = month(date),
    ym    = paste0(year, "m", sprintf("%02d", month))   # Stata ym format: "2009m06"
  ) %>%
  select(-taxsal_min, -taxsal_max)

write_csv(taxation_gt_salience_national,
          file.path("taxation_gt_salience_national.csv"))