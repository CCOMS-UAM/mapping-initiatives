# ==============================================================================
# 
# FILE NAME:   Guild_project.R
# DESCRIPTION: This script builds the complete project from scratch (only the
#              Excel files in the `dat/` subfolder are necessary)
# 
# AUTHOR:      Daniel Morillo (daniel.morillo@cibersam.es)
# 
# DATE:        24/02/2022
# 
# ==============================================================================


## ---- GLOBAL OPTIONS: --------------------------------------------------------

gc()
rm(list = ls())


## ---- INCLUDES: --------------------------------------------------------------

library(rmarkdown)
library(readxl)
library(tidyverse)

source("R/Constants.R", encoding = 'UTF-8')


## ---- CONSTANTS: -------------------------------------------------------------

WRITE_TABLES <- TRUE # This can be changed to `FALSE` if ones doesn't want
                     #   to write again the tables from the source Excel files.


## ---- FUNCTIONS: -------------------------------------------------------------


## ---- MAIN: ------------------------------------------------------------------

# Write notebooks: ----

# Notebook that generates the first version of the updated table:
render(
  "notebooks/Update_initiatives.Rmd",
  params = list(write_file = WRITE_TABLES)
)

# Notebook that generates the complete version of the updated table:
render(
  "notebooks/Complete_initiatives_additional.Rmd",
  params = list(write_file = WRITE_TABLES)
)


# File verification: ----

# Runs the notebook in the current sesson without writng the Excel file:
source("notebooks/Complete_initiatives_additional.Rmd", echo=TRUE)

read_table <- read_excel(INITIATIVES_FILEPATH, sheet = COMPLETE_TABLE_SHEET)

# This checks that the table written in the excel file and the result after
#   reading it are coincident:
initiatives_complete |> select(-id) |> iwalk(
  ~{
    comp <- initiatives_complete |> select(id, old = !!sym(.y))  |>
      full_join(read_table |> select(id, new = !!sym(.y))) |>
      mutate(eq = old == new)
    comp |> count(eq) |> print()
    comp |> filter(is.na(eq)) |> count(old, new) |> print()
  }
)

