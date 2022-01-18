# ==============================================================================
# 
# FILE NAME:   Output.R
# DESCRIPTION: Functions for output formatting
# 
# AUTHOR:      Mori (danivmorillo@gmail.com)
# 
# DATE:        21/04/2020
# 
# ==============================================================================


## ---- GLOBAL OPTIONS: --------------------------------------------------------

## ---- INCLUDES: --------------------------------------------------------------

library(glue)


## ---- CONSTANTS: -------------------------------------------------------------

QUOTING_CHARS    <- c(
  '*', '**', '"', "'", '_', '~', '`', '(', '[', '{', '^', '__'
)
QT_CLOSING_CHARS <- c(
  '*', '**', '"', "'", '_', '~', '`', ')', ']', '}', '^', '__'
) |> 
  set_names(QUOTING_CHARS)


## ---- FUNCTIONS: -------------------------------------------------------------

### Data variables and values outputs: ----

enumerate_levels <- function(.data, var, last = ", and ", italics = FALSE) {
  
  ## Argument checking and formatting: ----
  
  var <- enquo(var)
  
  # assert_is_data.frame(.data)
  # parse_varnames(as_label(var), .data)
  
  var <- .data |> pull(!!var)
  
  # assert_class_is_one_of(var, c("character", "factor"))
  if (is.character(var)) var <- factor(var)
  
  italics <- parse_bool(italics)
  
  
  ## Main: ----
  result <- levels(var)
  
  if (italics) result <- result |> enclose("*")
  
  glue_collapse(result, sep = ", ", last = last)
}

enclose <- function(strings, quoting = QUOTING_CHARS, omit_na = TRUE) {
  
  ## Argument checking and formatting: ----
  quoting <- match.arg(quoting)

  ## Main: ----
  result <- paste0(quoting, strings, QT_CLOSING_CHARS[quoting])
  
  if (omit_na) result[is.na(strings)] <- NA_character_
  
  result
}


### Other ancillary functions: ----
get_R_version <- function() {
  
  version <- sessionInfo()$R.version
  
  paste(version$major, version$minor, sep = '.')
}
