# Repository `mapping-initiatives`

SYNCHROS paper
"Mapping of initiatives that integrate European and
international population cohorts"

# Main outputs

The two most relevant files are:

- [`output/manuscript/Main_text.Rmd`](output/manuscript/Main_text.Rmd):
  This file renders the article main text output.
  
- [`output/manuscript/Supplementary_table.Rmd`](output/manuscript/Supplementary_table.Rmd):
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
  After finishing the installation, it is important to 
  [configure the `JAVA_HOME` environment variable][JH].
  The path to the JRE installation on Windows will tipically be similar to
  `C:/Program Files/Java/jre1.8.0_331` (depending on the version).

[J]: https://www.java.com/es/download/

[JH]: https://docs.oracle.com/en/cloud/saas/enterprise-performance-management-common/diepm/epm_set_java_home_104x6dd63633_106x6dd6441c.html

- [Git client][G]: Install the Git client in order to be able to clone locally
  the project repository. On Windows, use the 64-bit [Windows installer][GW].

[G]: https://git-scm.com/download

[GW]: https://git-scm.com/download/win

## Installing the project locally

This project is hosted as a GitHub repository.
It can be cloned as a local Git repository following [this instructions][CR].
Note that this will create a local copy of the GitHub repository as an
Rstudio project in the folder specified.
The URL that must be entered into the `Repository URL` text box is:

https://github.com/CCOMS-UAM/mapping-initiatives.git

[CR]: https://book.cds101.com/using-rstudio-server-to-clone-a-github-repo-as-a-new-project.html

After cloning the repository, the Rstudio project will open automatically in the
Rstudio IDE.
If it doesn't, or you want to return later to the project in Rstudio,
you can do so by double clicking on the file `mapping-initiatives.Rproj`
that has been created when cloning the repository.

**NOTE:** It is common practice to avoid using and versioning `.Rprofile` files.
This project uses [package `renv`][renv] to create a reproducible environment,
and thus needs the `.Rprofile` file that lives in the root directory of the
project. **Please DO NOT delete or edit this file**; it will install and
activate the `renv` package and make it ready for restoring the environment.

[renv]: https://cran.r-project.org/package=renv

## Changing to the "Submission candidate" branch (optional)

The repository cloning will create all the files as they are in the current
state of development of the project.
This is because the active Git branch will be the branch `main` by default.
If you want to build "Submission candidate 1" instead
(this will output the files submitted to IJE),
[check out branch `submission/ije` instead][SB] (see Step 2 in this link).

[SB]: https://twrushby.wordpress.com/2017/03/27/collaboration-with-rstudio-and-git-using-branches/

## Building the project

In order to build the project, simply source the script
[`src/Build_project.R`](src/Build_project.R) with the following command:

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

**NOTE:** Rendering the project may take a while, especially the first time.
This is due to the `renv` package restoring the environment, which implies
downloading and installing several R packages. Please, be patient!
