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

# Add code here that needs to be run when sourcing this script
## File system:
INITIATIVES_FILENAME <- "synchros-initiatives.xlsx"
TABLE_1_SHEET        <- "Table 1"
UPDATED_TABLE_SHEET  <- "Table 1 updated"
MICA_DATA_FILENAME   <- "mica-export.csv"

DATA_DIR <- "dat"
INITIATIVES_FILEPATH <- file.path(DATA_DIR, INITIATIVES_FILENAME)
MICA_DATA_FILEPATH   <- file.path(DATA_DIR, MICA_DATA_FILENAME)

## URLs:
SYNCHROS_URL <- "https://repository.synchros.eu"

## Text strings:
EMPTY_STRING               <- ''                              #   in the end
SPACE                      <- ' '
COMMA                      <- ', '
BULLET_PREFIX              <- '-'
LINE_FEED                  <- "\n"
SEMICOLON                  <- '; '
AND_CONJUNCTION            <- " and "

## Regular expressions:
AUTO_VARNAME_PREFIX_REGEXP <- r"(^\.\.\.)"
NO_INFO_REGEXP             <- "No information obtained(\\s*)" # Any whitespace
REPLACE_SEPS_REGEXP        <- glue("({SEMICOLON}|{AND_CONJUNCTION})")
NUMBER_REGEXP              <- r"(\d+)"
