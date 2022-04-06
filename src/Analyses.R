# ==============================================================================
# 
# FILE NAME:   Analyses.R
# DESCRIPTION: Performs all the data analyses for the paper and related outputs
# 
# AUTHOR:      Daniel Morillo (daniel.morillo@cibersam.es)
# 
# DATE:        06/04/2022
# 
# ==============================================================================


## ---- MAIN: ------------------------------------------------------------------

# Environment setup:
gc()

## ----includes, cache=FALSE----------------------------------------------------
# Libraries:
library(rlang)
library(tidyverse)
library(readxl)
library(magrittr)
library(flextable)
library(gtsummary)
library(english)
library(scales)
library(janitor)

# Source files:
source("R/Constants.R", encoding = 'UTF-8')
source("R/Output.R",    encoding = 'UTF-8')


## ----load-data----------------------------------------------------------------
tab1_new <- read_excel(INIT_EDITED_FILEPATH, sheet = TABLE_1_SHEET)

FACTOR_VARS <- c( # Without stripped-off prefixes when appropriate
  "setting",
  "access.metadata",
  "access.individualdata",
  "harmonizationstrategy",
  "omics",
  "team_activity",
  "funding"
)

# Simplify variable names:
tab1_new <- tab1_new |>
  rename_with(str_remove, pattern = "methodology.") |>
  rename_with(str_remove, pattern = "nb")           |>
  rename_with(tolower)

tab1_new <- tab1_new |> mutate(
  # Cast to proper vector types (easier than specifying all column types above):
  across(
    morecohortstobeharmonized,
    factor,
    levels = c("FALSE", "TRUE"),
    labels = c("No", "Yes")
  ),
  across(
    harmonizationstrategy,
    str_replace, pattern = "ex_", replacement = "ex-"
  ),
  across(setting, str_replace, pattern = UNDERSCORE, replacement = SLASH),
  across(
    all_of(FACTOR_VARS),
    str_replace, pattern = UNDERSCORE, replacement = SPACE
  ),
  across(all_of(FACTOR_VARS), str_to_sentence),
  # Preprocess factor variables:
  across(all_of(FACTOR_VARS), factor),
  funding = funding                 |> # Funding recoding
    fct_expand("Private")           |>
    fct_recode(!!!FUNDING_LEVS_OLD) |>
    fct_relevel(FUNDING_LABELS),
  across(starts_with("access."), fct_relevel, ACCESS_LEVELS),
  # Compute continent of leading institution:
  across(country_institution, recode, Southafrica = "South Africa"),
  continent_institution = country_institution                       |>
    countrycode(origin = "country.name", destination = "continent") %>%
    {
      if_else( # subdivide in North / Latin America & Caribbean
        condition = . == "Americas",
        true      = country_institution |>
          countrycode(origin = "country.name", destination = "region"),
        false     = .
      )
    }                                                               |>
    factor(levels = VECTOR_CONTINENTS_AMERICAS_SEP)
)

# Reorder variables (the ones to the output first, then the rest):
tab1_new <- tab1_new |> select(
  initiative,
  region_countries,
  description_short,
  cohorts.total:participants.harmonized,
  age_range,
  harmonizedvariables,
  cohortcriteria_short,
  everything()
)


## ----country-derivate-vars----------------------------------------------------
# Create variable counts derivated from the countries variable
tab1_countries <- tab1_new                  |>
  separate_rows(countries, sep = COMMA_SEP) |>
  select(id, countries)                     |>
  drop_na()                                 |>
  mutate(
    continent   = countries |>
      countrycode(origin = "iso3c", destination = "continent"),
    wbdi_region = countries |>
      countrycode(origin = "iso3c", destination = "region")
  )

tab1_continents <- tab1_countries              |>
  count(id, continent)                         |>
  complete(id, continent, fill = list(n = 0L)) |>
  mutate(bool = n |> as.logical())

# Complete missing values with available information in `region`:

## Create dataset with existing information (with missing nº of countries where
##   necessary):
suppressWarnings( # Warning when converting countries in `region` to `continent`
  tab1_missing_continents <- tab1_new             |>
    select(id, region)                            |>
    anti_join(tab1_continents, by = "id")         |>
    drop_na()                                     |>
    separate_rows(region, sep = ENUM_SEPS_REGEXP) |>
    mutate(
      region    = region |> str_replace("American?", "Americas"),
      # Correct values
      continent = region |>
        countrycode(origin = "country.name", destination = "continent"),
      n         = region    |>
        str_extract("\\d+") |>
        as.integer()        |>
        coalesce(continent |> is.na() |> if_else(NA_integer_, 1L)),
      continent = continent |> coalesce(
        region |> str_extract(
          VECTOR_CONTINENTS |> glue_collapse(sep = '|') |> enclose('(')
        )
      ),
      bool      = continent != TRUE # Turns all non-missing to `TRUE`
    )                                             |>
    ## Complete non-present information with proper values:
    complete(id, continent, fill = list(n = 0L, bool = FALSE), explicit = FALSE)
)

tab1_continents <- tab1_continents |>
  bind_rows(tab1_missing_continents |> select(-region))


# Subdivide "Americas" in "North America" and "Latin America & Caribbean"

## Create variable counts derivated from the countries variable:
tab1_regions <- tab1_countries                   |>
  count(id, wbdi_region)                         |>
  complete(id, wbdi_region, fill = list(n = 0L)) |>
  mutate(bool = n |> as.logical())

## Complete missing values with available information in `region`:
tab1_missing_regions <- tab1_missing_continents                |>
  select(everything(), -n, country = region)                   |>
  group_by(id, continent)                                      |>
  mutate(
    country = country       |>
      str_detect(continent) |>
      if_else(NA_character_, country),
    n       = country |>
      is.na()         %>%
      { if_else(all(.) & bool, NA_integer_, not(.) |> sum()) }
  )                                                            |>
  ungroup()                                                    |>
  left_join(CONTINENT_REGION_CORRESPONDENCE, by = "continent") |>
  # When possible, get the wbdi_region from the country name in `region`:
  mutate(
    wbdi_region = country                   |>
      countrycode("country.name", "region") |>
      factor()                              |>
      coalesce(wbdi_region)
  )                                                            |>
  # Complete the missing regions when they are known to not be considered:
  complete(
    id, wbdi_region,
    fill     = list(n = 0L, bool = FALSE),
    explicit = FALSE
  )                                                            |>
  # Discard duplicate cases when `wbdi_region` is univocally identified:
  distinct()                                                   |>
  # Duplicate `TRUE` values of continents that do not univocally map to regions:
  group_by(id, continent)                                      |>
  mutate(bool = if_else(bool & n() > 1L, NA, bool))            |>
  # Discard duplicates
  ungroup()                                                    |>
  distinct(id, wbdi_region, bool, n)                           |>
  # Collapse values from the same region:
  group_by(id, wbdi_region)                                    |>
  summarize(bool = any(bool), n = sum(n), .groups = "drop")

tab1_regions <- tab1_regions |> bind_rows(tab1_missing_regions)

tab1_american_regions <- tab1_regions          |>
  filter(wbdi_region |> str_detect("America")) |>
  rename(continent = wbdi_region)

## Collapse selected continents and regions:
tab1_continents <- tab1_continents |>
  filter(continent != "Americas")  |>
  bind_rows(tab1_american_regions)


# Add count of continents:
tab1_continents <- tab1_continents |>
  group_by(id)                     |>
  add_count(wt = bool, name = "n_continents")

# Create headers:
tab1_continent_headers <- tab1_continents                |>
  ungroup()                                              |>
  distinct(continent)                                    |>
  drop_na()                                              |>
  expand_grid(type = c("n", "bool"))                     |>
  unite(col = var_name, type, continent, remove = FALSE) |>
  arrange(desc(type))                                    |>
  transmute(
    var_name,
    header    = if_else(type == "n", "Nº of countries", "Continent"),
    subheader = continent
  )

# Join with main table:

tab1_continents_wide <- tab1_continents |>
  ungroup()                             |>
  pivot_wider(names_from = continent, values_from = n:bool)

tab1_new <- tab1_new |> left_join(tab1_continents_wide, by = "id")


## ----health-topic-derivate-vars-----------------------------------------------
tab1_topics <- tab1_new                             |>
  separate_rows(healthtopic, sep = PIPE_REGEXP)     |>
  select(id, healthtopic)

tab1_topic_headers <- tab1_topics |>
  drop_na()                       |>
  distinct(healthtopic)           |>
  transmute(
    var_name  = paste0("topic_", healthtopic),
    header    = TOPIC_HEADER,
    subheader = healthtopic                                      |>
      str_replace(
        pattern     = "birth_infancy_childhood_health",
        replacement = "Birth, infancy & childhood health"
      )                                                          |>
      str_replace_all(pattern = UNDERSCORE, replacement = SPACE) |>
      str_to_sentence()
  )

tab1_topics_wide <- tab1_topics                               |>
  mutate(value = TRUE)                                        |>
  complete(id, healthtopic, fill = list(value = FALSE))       |>
  drop_na()                                                   |>
  pivot_wider(names_from  = healthtopic, values_from = value) |>
  # Reorder according to Angel's suggestion (email from 21/03/2022)
  select(
    chronic_diseases, non_communicable_diseases,
    cancer,
    ends_with("_diseases"), # All diseases
    biomedicine, general_epidemiology, public_health,
    ageing, ends_with("_health"),
    social_environment,
    medical_imaging,
    everything()
  )                                                           |>
  rename_with(~paste0("topic_", .), .cols = -id)

tab1_new <- tab1_new |> left_join(tab1_topics_wide, by = "id")


## ----socioenvcontext-derivate-vars-----------------------------------------------------------------------
tab1_context <- tab1_new                            |>
  separate_rows(socioenvcontext, sep = PIPE_REGEXP) |>
  select(id, socioenvcontext)

tab1_context_headers <- tab1_context |>
  drop_na()                          |>
  distinct(socioenvcontext)          |>
  transmute(
    var_name  = paste0("context_", socioenvcontext),
    header    = SOCENV_HEADER,
    subheader = socioenvcontext                                  |>
      str_replace(
        pattern     = "work_",
        replacement = "work-"
      )                                                          |>
      str_replace(
        pattern     = "short_half_",
        replacement = "short-half-"
      )                                                          |>
      str_replace_all(pattern = UNDERSCORE, replacement = SPACE) |>
      str_to_sentence()
  )

tab1_context_wide <- tab1_context                                |>
  mutate(value = TRUE)                                           |>
  complete(id, socioenvcontext, fill = list(value = FALSE))      |>
  drop_na()                                                      |>
  pivot_wider(names_from = socioenvcontext, values_from = value) |>
  select(id, everything(), -other, other)                        |>
  rename_with(~paste0("context_", .), .cols = -id)

tab1_new <- tab1_new |> left_join(tab1_context_wide, by = "id")


## ----socioenvcontext-other-values------------------------------------------------------------------------
tab1_socioenvcontext_other <- tab1_new |>
  separate_rows(
    socioenvcontextother,
    sep = glue("({COMMA_SEP}|{SEMICOLON_SEP})")
  )                                    |>
  distinct(id, socioenvcontextother)   |>
  drop_na()                            |>
  count(socioenvcontextother)          |>
  arrange(desc(n))                     |>
  mutate(socioenvcontextother = socioenvcontextother |> str_to_sentence())


## ----analyses-derivate-vars------------------------------------------------------------------------------
tab1_analysis <- tab1_new                    |>
  separate_rows(analyses, sep = PIPE_REGEXP) |>
  select(id, analyses)                       |>
  filter(analyses != "na") # Missing values that appear in the listed values

tab1_analysis_headers <- tab1_analysis |>
  drop_na()                            |>
  distinct(analyses)                   |>
  transmute(
    var_name  = paste0("analysis_", analyses),
    header    = ANALYSIS_HEADER,
    subheader = analyses |> str_to_sentence()
  )

tab1_analysis_wide <- tab1_analysis                       |>
  mutate(value = TRUE)                                    |>
  complete(id, analyses, fill = list(value = FALSE))      |>
  drop_na()                                               |>
  pivot_wider(names_from = analyses, values_from = value) |>
  rename_with(~paste0("analysis_", .), .cols = -id)

tab1_new <- tab1_new |> left_join(tab1_analysis_wide, by = "id")


## ----create-output-dataset-------------------------------------------------------------------------------
# Create formatted output table for the initiatives table:
tab1_new_out <- tab1_new |> select(initiative:cohortcriteria_short)


## ----preprocess-descriptives-----------------------------------------------------------------------------
# Initiatives without harmonized cohorts are assigned a "missing" value
#   to the number of harmonized variables and participants, so we can have
#   those descriptives for the actual initiatives with harmonized cohorts
tab1_new <- tab1_new |> mutate(
  across(
    c(participants.harmonized, harmonizedvariables),
    if_else, condition = cohorts.harmonized != 0, false = NA_real_
  )
)


## ----create-headers-labels-------------------------------------------------------------------------------
# Get the names from the first two rows of the file, and create names and labels
suppressMessages( # Message when reading empty column names
  tab1_headers <- read_excel(
    INITIATIVES_FILEPATH,
    sheet = TABLE_1_SHEET,
    n_max = 1
  )                                                                          |>
    pivot_longer(everything(), names_to = "header", values_to = "subheader") |>
    mutate(
      header = header                            |>
        str_detect(AUTO_VARNAME_PREFIX_REGEXP)   |>
        if_else(header |> dplyr::lag(1), header) |>
        str_replace("harmonized", "harmonised"), # Correct errata in headers:
    )                                                                        |>
    mutate( # Edit headers to correspond to the new structure:
      header    = if_else(header == "INITIATIVE", "Initiative", header),
      header    = if_else(
        header == "Region, Country",
        true  = "Region / countries",
        false = header
      ),
      header    = if_else(header == "Main objective", "Description", header),
      header    = if_else(
        header |> str_detect("^Briefly"),
        true  = "Cohort criteria",
        false = header
      )
    )                                                                        |>
    # Delete unnecessary headers
    slice(-10)                                                               |>
    bind_rows( # Add additional labels for descriptives table
      tibble(
        header    = c(
          "Age"             |> rep(2),
          "Nº of countries",# n_countries
          "Setting",
          "Access to" |> rep(2),
          "Harmonization strategy",
          "With omics data",
          "Team active (at consultation)",
          "Funding",
          "Continent of leading institution",
          "Nº of continents" # n_continents
        ),
        subheader = c(
          "Minimum", "Maximum",          # Age
          NA_character_ |> rep(2),       # Nº of countries and seting
          "Metadata", "Individual data", # Access to data
          NA_character_ |> rep(6) # Harmonization strategy to continent of ...
        )                         #   leading institution.
      )
    )                                                                        |>
    add_column( # Add variable names column
      var_name = tab1_new |>
        select(
          -(id:description),
          -cohortcriteria,
          -(socioenvcontext:analysesother),
          -healthtopic,
          -countries,
          -country_institution,
          -(n_Africa:analysis_pooled)
        )                 |>
        colnames()
    )
)

# Add headers/labels
tab1_headers <- tab1_headers |> bind_rows(
  tab1_continent_headers,
  tab1_topic_headers,
  tab1_context_headers,
  tab1_analysis_headers
)

# Create labels and format subheaders:
tab1_headers <- tab1_headers |>
  unite(# TODO; Use subheaders as labels (when adding headers to the desc. tab.)
    header, subheader,
    col    = "label",
    sep    = COLON,
    remove = FALSE,
    na.rm  = TRUE
  )                          |>
  mutate( # Set duplicates for cell merging
    subheader = subheader |>
      is.na()             |>
      if_else(true = header, false = subheader)
  )

# Assign meaningful labels to columns
tab1_new <- tab1_new |> imap_dfc(# Labels to assign to the columns
  \(column, variable) {
    
    properties <- tab1_headers |> filter(var_name == variable)
    
    column %@% "header"     <- properties |> pull(header)
    # column %@% "label"      <- properties |> pull(label)
    # column %@% "subheader"  <- properties |> pull(subheader)
    # TODO: Substitute two previous lines by the follwing:
    column %@% "label"  <- properties |> pull(subheader)
    
    column
  }
)


## ----descriptive-table--------------------------------------------------------
# Select and order data for table of descriptives:
tab1_new_describe <- tab1_new |> select(
  team_activity, continent_institution, funding,
  starts_with("access"),
  starts_with("topic_"),
  starts_with("context_"),
  omics,
  starts_with("cohorts."),
  morecohortstobeharmonized,
  harmonizedvariables,
  starts_with("participants."),
  starts_with("age."),
  n_countries, setting, starts_with("bool_"),
  harmonizationstrategy,
  starts_with("analysis_")
)

descriptives_table_output <- tab1_new_describe |> tbl_summary(
  statistic    = list(all_continuous()  ~ "{median} ({min} - {max})"),
  digits       = list(all_categorical() ~ c(0, 1)),
  missing_text = "(Missing)"
  # sort = # TODO: Does not seem to work
) |>
  modify_header(label ~ "**Variable**")

## TODO: Possibly convert to "tibble"
# descriptives_table_output


## ----compute-descriptive-values-----------------------------------------------
# Total nº of initiatives:
total_N_out <- descriptives_table_output |>
  extract2("N")                          |>
  as.english()                           |>
  as.character()
total_N_out_sentence_case <- total_N_out |> str_to_sentence()

# Maximum number of missing values in one descriptive variable:
max_missing_out <- tab1_new_describe           |>
  summarize(across(.fns = ~sum(is.na(.))/n())) |>
  pivot_longer(everything())                   |>
  filter(value == max(value))                  |>
  distinct(value)                              |>
  pull()                                       |>
  percent(accuracy = .1)

# Active projects:
active_projects_prop_out <- descriptives_table_output |>    # Over non-missing
  inline_text(variable = "team_activity", pattern = "{p}%") # Over total
active_projects_prop_total_out <- tab1_new_describe |>
  tabyl(team_activity)                              |>
  filter(team_activity == "Yes")                    |>
  pull(percent)                                     |>
  percent(accuracy = .1)

# Countries of leading institutions:

country_institutions <- tab1_new |>
  count(country_institution)     |>
  drop_na()                      |>
  mutate(
    out = country_institution |> paste0(" (n = ", n, ')'),
    out = out %>% if_else(
      country_institution %in% COUNTRYNAME_ACRONYMS,
      paste0('the ', .),
      .
    )
  )

country_institution_max_freq <- country_institutions |> filter(n == max(n))

country_institution_max_freq_out <- country_institution_max_freq |> pull()

country_institution_ranking_next <- country_institutions                      |>
  anti_join(country_institution_max_freq, by = c("country_institution", "n")) |>
  arrange(desc(n))                                                            |>
  slice(1:3)

country_institution_ranking_next_out <- country_institution_ranking_next |>
  pull()                                                                 |>
  glue_collapse(sep = ", ", last = ", and ")


# Funding sources:
funding_public_out <- descriptives_table_output |> inline_text(
  variable = "funding",
  level    = sym(PUBLIC_FUNDING),
  pattern  = "{p}%"
)
funding_mixed_out  <- descriptives_table_output |> inline_text(
  variable = "funding",
  level    = sym(MIXED_FUNDING),
  pattern  = "{p}%"
)

# Harmonization strategy:
harmo_strategies_count <- tab1_new |>
  count(harmonizationstrategy)     |>
  drop_na()

harmo_strategy_max_out <- harmo_strategies_count |>
  filter(n == max(n))                            |>
  pull(harmonizationstrategy)

harmo_max_prop_out <- descriptives_table_output |> inline_text(
  variable = "harmonizationstrategy",
  level    = all_of(harmo_strategy_max_out),
  pattern  = "{p}%"
)

# Analysis:
analysis_pooled_out    <- descriptives_table_output |>
  inline_text(variable = "analysis_pooled",    pattern = "{p}%")
analysis_meta_out      <- descriptives_table_output |>
  inline_text(variable = "analysis_meta",      pattern = "{p}%")
analysis_federated_out <- descriptives_table_output |>
  inline_text(variable = "analysis_federated", pattern = "{p}%")

# Omics:
omics_out <- descriptives_table_output |>
  inline_text(variable = "omics", pattern = "{p}% (n = {n})")

# Total nº of cohorts:
total_cohorts_range_out  <- descriptives_table_output |>
  inline_text(variable = "cohorts.total", pattern = "{min} and {max}")
total_cohorts_median_out <- descriptives_table_output |>
  inline_text(variable = "cohorts.total", pattern = "{median}")

# Harmonized cohorts:
harm_cohorts_max_out <- descriptives_table_output |>
  inline_text(variable = "cohorts.harmonized", pattern = "{max}")

# More cohorts to be harmonized:
more_cohorts_expected_n_out <- descriptives_table_output |>
  inline_text(variable = "morecohortstobeharmonized", pattern = "{n}")

# Harmonized variables:
harm_vars_range_out  <- descriptives_table_output |>
  inline_text(variable = "harmonizedvariables", pattern = "{min} to {max}")
harm_vars_median_out <- descriptives_table_output |>
  inline_text(variable = "harmonizedvariables", pattern = "{median}")

# Harmonized participants:
harm_participants_max_out    <- descriptives_table_output |>
  inline_text(variable = "participants.harmonized", pattern = "{max}")
harm_participants_median_out <- descriptives_table_output |>
  inline_text(variable = "participants.harmonized", pattern = "{median}")

# Particinats' ages across included cohorts:
max_age_max_out  <- descriptives_table_output |>
  inline_text(variable = "age.max", pattern = "{max}")

# Topics:
prop_ageing_out <- descriptives_table_output |>
  inline_text(variable = "topic_ageing", pattern = "{p}%")

# Nº of countries:
max_n_countries_out <- descriptives_table_output           |>
  inline_text(variable = "n_countries", pattern = "{max}") |>
  as.integer()                                             |>
  as.english()                                             |>
  as.character()
min_n_countries_out <- descriptives_table_output           |>
  inline_text(variable = "n_countries", pattern = "{min}") |>
  as.integer()                                             |>
  as.english()                                             |>
  as.character()

# Nº of continents

tab1_n_continents <- tab1_new |>
  select(n_continents)        |>
  tbl_summary()

prop_1_continent_out  <- tab1_n_continents |>
  inline_text(variable = "n_continents", level = "1", pattern = "{p}%")
prop_6_continents_out <- tab1_n_continents |>
  inline_text(variable = "n_continents", level = "6", pattern = "{p}%")


# Nº of initiatives per region
prop_Europe_out <- descriptives_table_output |>
  inline_text(variable = "bool_Europe", pattern = "{p}%")

n_Africa_out    <- descriptives_table_output             |>
  inline_text(variable = "bool_Africa", pattern = "{n}") |>
  as.integer()                                           |>
  as.english()                                           |>
  as.character()
prop_Africa_out <- descriptives_table_output |>
  inline_text(variable = "bool_Africa", pattern = "{p}%")

n_Latam_out    <- descriptives_table_output                                 |>
  inline_text(variable = "bool_Latin America & Caribbean", pattern = "{n}") |>
  as.integer()                                                              |>
  as.english()                                                              |>
  as.character()
prop_Latam_out <- descriptives_table_output |>
  inline_text(variable = "bool_Latin America & Caribbean", pattern = "{p}%")


## ----initiatives-table-output-manuscript--------------------------------------
initiatives_table_output <- tab1_new_out                  |>
  flextable()                                             |>
  set_header_df(
    mapping = tab1_headers |> select(-label),
    key     = "var_name"
  )                                                       |>
  merge_h(part = "header")                                |>
  merge_v(part = "header")                                |>
  colformat_num( na_str = MISSING_STR)                    |>
  colformat_char(na_str = MISSING_STR)                    |>
  set_table_properties(layout = "autofit")
