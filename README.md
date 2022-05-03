# Repository `mapping-initiatives`

SYNCHROS paper
"Mapping of initiatives that integrate European and
international population cohorts"

# Main outputs

The two most relevant files are:

- (`output/manuscript/Main_text.Rmd`)[output/manuscript/Main_text.Rmd]:
  This file renders the article main text output.
  
- (`output/manuscript/Supplementary_table.Rmd`)[output/manuscript/Supplementary_table.Rmd]:
  This output renders the Supplementary Table 1 file, the interactive table
  with the most relevant informatio of the initiatives.
  
The output of these two files constitute the documents submitted to the
journal, along with the cover letter and the "Authorship" and
"Declaration of competing interests" statement forms (not included).

# Rendering the output

The easiest way to render the project output is by sourcing the script
[`src/Build_project.R`](src/Build_project.R).
First to this step, some pre-requisites must be met
(which imply manual installation of software components).

## Manual installation of software components

- Install [R version 4.1.3][R]:
  It is important that this version is used instead of the latest one,
  as (at least in v. 4.2.0) package `xlsx` causes the R session to abort.
  In Windows, using the [binary installer][inst] is recommended.

[R]: https://cran.rstudio.com/bin/windows/base/old/4.1.3/
[inst]: (https://cran.rstudio.com/bin/windows/base/old/4.1.3/R-4.1.3-win.exe)

- [Rstudio Desktop][RS]: Although not strictly necessary, it is recommended
  to install the latest version of the Rstudio IDE.

[RS]: https://www.rstudio.com/products/rstudio/download/#download

- [Java][J]: Install version 8, update 331 or latest of the
  Java Runtime Environment (JRE).
  After finishing the installation, it is important to configure the
  [`JAVA_HOME`][JH] environment variable.
  The path to the JRE installation on Windows will tipically be similar to
  `C:/Program Files/Java/jre1.8.0_331` (depending on the version).

[J]: https://www.java.com/es/download/

[JH]: https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/diepm/epm_set_java_home_104x6dd63633_106x6dd6441c.html

## Building the project

In order to build the project, simply source the script
[`src/Build_project.R`](src/Build_project.R):

```r
source("src/Build_project.R")
```

This will render all the project outputs.
Some throughput files will be also rendered, including throughput dataset files.
This will not affect the output, as the main outputs referred to above
depend on file `dat/initiatives-dataset.xlsx` which will not be updated,
as it is the output of a manual throughput process
(i.e. manual recoding of the initiative free-text fields "Description" and
"Cohort criteria" in order to make them shorter).
To omit re-generating the throughput datasets, set the object
`WRITE_TABLES <- FALSE` in line 33 of that script.
