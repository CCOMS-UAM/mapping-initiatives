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

# source("R/{source_file}", encoding = 'UTF-8')


## ---- CONSTANTS: -------------------------------------------------------------

WRITE_TABLES <- TRUE # This can be changed to `FALSE` if ones doesn't want
                     #   to write again the tables from the source Excel files.


## ---- FUNCTIONS: -------------------------------------------------------------


## ---- MAIN: ------------------------------------------------------------------

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
