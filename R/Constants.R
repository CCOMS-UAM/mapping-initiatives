# ==============================================================================
# 
# FILE NAME:   Constants.R
# DESCRIPTION: Constant objects
# 
# AUTHOR:      Daniel Morillo (daniel.morillo@cibersam.es)
# 
# DATE:        17/12/2021
# 
# ==============================================================================


## ---- INCLUDES: --------------------------------------------------------------

library(glue)
# source("R/{source_file}", encoding = 'UTF-8')


## ---- CONSTANTS: -------------------------------------------------------------

## File system:

### File names:
INITIATIVES_FILENAME <- "synchros-initiatives.xlsx"
VAR_CORRESP_FILENAME <- "variable_correspondence.xlsx"
MICA_DATA_FILENAME   <- "mica-export.csv"
EXTRAS_FILENAME      <- "PORCENTAJES_template_3_population_.03.07.20.xls"
UPDATES_FILENAME     <- "SYNCHROS_REPOSITORY_ INITIATIVES_20200617.xlsx"

### File paths:
DATA_DIR <- "dat"
INITIATIVES_FILEPATH <- file.path(DATA_DIR, INITIATIVES_FILENAME)
MICA_DATA_FILEPATH   <- file.path(DATA_DIR, MICA_DATA_FILENAME)
VAR_CORRESP_FILEPATH <- file.path(DATA_DIR, VAR_CORRESP_FILENAME)
EXTRAS_FILEPATH      <- file.path(DATA_DIR, EXTRAS_FILENAME)
UPDATES_FILEPATH     <- file.path(DATA_DIR, UPDATES_FILENAME)

## Excel manipulation:
TABLE_1_SHEET        <- "Table 1"
UPDATED_TABLE_SHEET  <- "Table 1 updated"
COMPLETE_TABLE_SHEET <- "Table 1 complete"
TABLE_1_EXTRA_SHEET  <- "INITIATIVES"
TABLE_1_UPDATE_SHEET <- "POPULATION COHORT INITIATIVES"

# Vector of Excel column coordinates (letters), to convert to numeric positions
EXCEL_COL_POSITIONS <- c(LETTERS, paste0('A', LETTERS))

## URLs:
SYNCHROS_URL <- "https://repository.synchros.eu"

## Text strings:
EMPTY_STRING    <- ''
SPACE           <- ' '
COMMA           <- ', '
DASH            <- '-'
UNDERSCORE      <- '_'
PIPE            <- '|'
BULLET_PREFIX   <- DASH
SLASH           <- '/'
LINE_FEED       <- "\n"
CARRIAGE_RETURN <- "\r"
COLON           <- ': '
SEMICOLON       <- '; '
AND_CONJUNCTION <- " and "
ASTERISK        <- '*'
COL_PREFFIX     <- "col_"

## Regular expressions:
AUTO_VARNAME_PREFIX_REGEXP     <- r"(^\.\.\.)"
NO_INFO_REGEXP                 <- "No information obtained(\\s*)"# whitespace(s)
REPLACE_SEPS_REGEXP            <- glue("({SEMICOLON}|{AND_CONJUNCTION})")
ENUM_SEPS_REGEXP               <- glue("({COMMA}|{AND_CONJUNCTION})")
NUMBER_REGEXP                  <- r"(\d+)"
ASTERISK_REGEXP                <- glue("\\{ASTERISK}")
UPPERCASE_LETTERS_BEGIN_REGEXP <- "^[A-Z]+"
UPDATE_VARS_CHARCLASS_REGEXP   <- glue("[{SPACE}{SLASH}{DASH}]")
ANALYSES_SUFFIX_REGEXP         <- glue("[{SPACE}{DASH}]analyses")

## Country processing objects:
VECTOR_CONTINENTS <- codelist |>
  distinct(continent)         |>
  arrange(continent)          |>
  drop_na()                   |>
  pull()

VECTOR_REGIONS <- codelist |>
  distinct(region)         |>
  arrange(region)          |>
  drop_na()                |>
  pull()
