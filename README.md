Replication package for “Lifetime and intergenerational consequences of
poor childhood health”
================
Krzysztof Karbownik and Anthony Wray,
Journal of Human Resources

<!-- README.md is generated from README.Rmd. Please edit that file. -->

You can cite this replication package using Zenodo, where an archival
version of this repository is stored.
[![DOI](https://zenodo.org/badge/XXX.svg)](XXX)

## Overview

This replication package contains code, output, raw data, and Stata
packages. The code in this replication package will replicate all tables
and figures from raw data using Stata and a few unix shell commands.
Instructions for accessing restricted-use data are provided below.

The entire replication takes 7 and a half days to run on a 2.9 GHz
Intel-based Windows PC (64-bit x86-64) with 24 GB of RAM or 4 and a half
days on a machine with 64 RAM.

The Zenodo replication package is available here: XXX

The GitHub version is available here:
<https://github.com/anthonywray/lifetime-consequences-child-health>

## Data availability statement

Replication materials are provided under a BSD 3-Clause License.

The hospital inpatient admissions data from St. Bartholomew’s and Guy’s
Hospitals that support the findings of this study are included with the
replication package.

The hospital inpatient admissions data from Great Ormond Street Hospital
are publicly available from the Historic Hospital Admission Records
Project (HHARP) (<https://hharp.org/>). The HHARP data used in this
study were kindly shared by Dr. Sue Hawkins (<drsuehawkins@gmail.com>).
They cannot be posted online or included with the replication materials.

The anonymized complete-count data (UK Data Archive study number
[7481](https://beta.ukdataservice.ac.uk/datacatalogue/studies/study?id=7481#!/details))
for the Censuses of England and Wales, 1881 to 1911, are publicly
available from the Integrated Census Microdata (I-CeM) project
(<https://icem.data-archive.ac.uk/#step1>). Since data access is
[safeguarded](https://ukdataservice.ac.uk/find-data/access-conditions/),
the data files used for this study cannot be included with the
replication materials.

“Integrated Census Microdata (I-CeM) Names and Addresses, 1851-1911:
Special Licence Access” (UK Data Archive study number
[7856](https://beta.ukdataservice.ac.uk/datacatalogue/studies/study?id=7856#!/details))
is a safeguarded dataset that contains names and addresses from the
Integrated Census Microdata (I-CeM) dataset of the censuses of Great
Britain for the period 1851 to 1911. These data can only be accessed by
obtaining a Special License agreement with the UK Data Archive and the
data distributor, FindMyPast Ltd.

Prior versions of the complete count 1881 Census of England and Wales
were accessed from the North Atlantic Population Project
(<https://www.nappdata.org/napp/>) in 2013. The NAPP data are now
distributed through the IPUMS International data system
(<https://international.ipums.org/international/>). At the time we
accessed the data, the residential address variable was available for
download from NAPP, but it is now only available as part of the
restricted-use dataset “Integrated Census Microdata (I-CeM) Names and
Addresses, 1851-1911: Special Licence Access.” Thus, we cannot include
our original extracts from NAPP as part of the replication materials.

All other data are contained in the Zenodo repository.

### Public-use raw data links

-   Integrated Census Microdata (I-CeM) project data documentation and
    supporting materials, including parish and place list dictionary
    files are available
    [here](https://www.essex.ac.uk/research-projects/integrated-census-microdata).
-   An archived version of a website for an index of streets by
    registration district from the 1891 Census of England and Wales is
    located
    [here](https://webarchive.nationalarchives.gov.uk/ukgwa/+/http://yourarchives.nationalarchives.gov.uk/index.php?title=Place:Altrincham_Registration_District,_1891_Census_Street_Index).
    The authors accessed and scraped data from the website in 2013. As
    the original website was a “wiki”-style page, the archived version
    may differ from the version accessed by the authors.

### Limited-use data links and instructions

Researchers interested in accessing the hospital inpatient admission
records from the Historic Hospital Admission Records Project (HHARP)
(<https://hharp.org/>) will need to create an account on the HHARP
website. Data download is limited to 200 observations. The search
results page indicates how many entries match the search criteria.
Downloaded data files are in `.csv` format. Researchers who require
larger volumes of data should contact Dr. Sue Hawkins
(<drsuehawkins@gmail.com>).

Researchers based outside the UK who are interested in accessing the
complete count records for the Censuses of Great Britain (including the
Censuses of England and Wales) from the Integrated Census Microdata
(I-CeM) project (<http://icem.data-archive.ac.uk/#step1>) will need to
create an account with the UK Data Service
(<https://beta.ukdataservice.ac.uk/myaccount/login>) by first requesting
a username
[here](https://beta.ukdataservice.ac.uk/myaccount/credentials). If you
are in the UK and from an institution of higher or further education or
your organisation is part of the UK Access Management Federation (UKAMF)
and on
[this](http://www.ukfederation.org.uk/content/Documents/AccountableIdPs)
list of federation members, you can use the username and password issued
to you by your organisation to login/register with the UK Data Service.
Data download is limited to 1,000,000 observations. Downloaded data
files are in `.csv` pipe-delimited format. Authors converted `.csv`
files to `.dta` files using Stat/Transfer and the shell script
`shells/csv_to_dta.sh`.

### Restricted-use data instructions

The dataset that contains names and addresses from the complete count
Censuses of England and Wales is restricted use, but may be accessed by
obtaining a Special License agreement with the UK Data Archive and the
data distributor, FindMyPast Ltd. Instructions can be found
[here](https://beta.ukdataservice.ac.uk/datacatalogue/studies/study?id=7856#!/access-data).
It can take several months to be approved and gain access to the data.
Data are provided as `.txt` files. Authors converted `.txt` files to
`.dta` files using Stat/Transfer and the shell script
`shells/csv_to_dta.sh`.

### Historical archive instructions

Inpatient hospital admission registers were viewed and photographed by
the authors at the [Barts Health NHS Trust
Archives](https://www.bartshealth.nhs.uk/barts-health-archives) and the
[London Metropolitan
Archive](https://www.cityoflondon.gov.uk/things-to-do/history-and-heritage/london-metropolitan-archives/visitor-information/opening-times-and-location).
Requests for appointments at the Barts Health NHS Trust Archives should
be made at least one week in advance. Researchers must complete a
[researcher registration
form](https://www.bartshealth.nhs.uk/download.cfm?doc=docm93jijm4n21261.pdf&ver=40076)
in advance of their visit. Researchers interested in visiting the LMA
will need to [apply in
advance](https://www.cityoflondon.gov.uk/things-to-do/history-and-heritage/london-metropolitan-archives/visitor-information/opening-times-and-location)
for a History Card.

## Raw dataset list

| Data file or Folder                       | Source                     | Notes                                                         | Provided |
|-------------------------------------------|----------------------------|---------------------------------------------------------------|----------|
| `raw/diseases/*_Categories.csv`           | Authors                    | Causes of admission manually coded by authors.                | Yes      |
| `raw/geography/*`                         | I-CeM and NAPP             | Data dictionaries.                                            | Yes      |
| `raw/hospitals/*.dta`                     | Authors                    | Data collected by authors.                                    | Yes      |
| `raw/hharp/hharp_hospital_admissions.dta` | HHARP                      | Limited-access, instructions for obtaining data are above.    | No       |
| `raw/icem/England_YYYY_*.dta`             | I-CeM                      | Limited-access, instructions for obtaining data are above.    | No       |
| `raw/icem_sl/ICEM_Names_EW_*.dta`         | I-CeM and UK Data Service  | Restricted-access, instructions for obtaining data are above. | No       |
| `raw/names/nicknames_for_matching.csv`    | Stanford University        | Obtained from Roy Mill at Stanford University.                | Yes      |
| `raw/napp/napp_*.dta`                     | NAPP                       | Current public-use version does not include address variable. | No       |
| `raw/occupations/*`                       | I-CeM                      | Data dictionaries.                                            | Yes      |
| `raw/streets/*`                           | The National Archives (UK) | These are the scraped streets data.                           | Yes      |
| `shells/*`                                | NAPP                       | Codebook and do files.                                        | Yes      |

## Computational requirements

### Software requirements

-   Stata 14. Some sections of code are set to version 12.
    -   All user-written Stata programs used in this project can be
        found in the `scripts/code/programs` directory

Portions of the code use shell commands, which may require Unix. The
analysis takes 7 and a half days to run on a 2.9 GHz Intel-based Windows
PC (64-bit x86-64) Microsoft Windows 10 Professional operating system,
24GB of RAM, and 8-core Stata/MP version 17.0. The run time will be 3
days shorter on a computer with 64 RAM.

At least 150GB of spare hard drive space is required for the raw data
files and at least 500 GB of spare hard drive space is required for the
intermediate files if you want to build the processed data from raw
data.

### Description of programs

-   `0_run_all.do` is the main script that runs all the code, allows you
    to select all options, and sets up file paths.
    -   `scripts/code/1_build/01_extract_icem_census_data.do` extracts
        the complete-count census datasets.
        -   Runtime: about 4 hours and 30 minutes.
    -   `scripts/code/1_build/02_clean_icem_names_birthplaces.do`
        extracts the names from the restricted-use census files and
        cleans the birthplace variables.
        -   Runtime: about 1 hour and 15 minutes.
    -   `scripts/code/1_build/03_icem_census_linkage.do` creates 10-,
        20-, and 30-year links for complete count censuses between 1881
        and 1911.
        -   Runtime: about 6 days 16 hours and 15 minutes. This step
            takes about 3 days on a computer with 64 GB of RAM.
    -   `scripts/code/1_build/04_extract_hospital_data.do` extracts and
        cleans the hospital data.
        -   Runtime: about 7 minutes.
    -   `scripts/code/1_build/05_census_hospital_record_linkage.do`
        links the hospital records to the censuses.
        -   Runtime: about 1 hour and 30 minutes.
    -   `scripts/code/1_build/06_build_analysis_data.do` builds the data
        sets used to produce the tables and figures.
        -   Runtime: about 2 hours and 30 minutes.
    -   `scripts/code/2_analysis/01_tables_figures.do` runs the
        regressions and conducts the analysis that generates the tables
        and figures in the main paper.
        -   Runtime: about 30 minutes.
    -   `scripts/code/2_analysis/02_online_appendix.do` runs the
        regressions and conducts the analysis that generates the tables
        and figures in the online appendix.
        -   Runtime: about 11 hours and 15 minutes.
    -   `scripts/code/2_analysis/03_intext_statistics.do` generates the
        numbers that are computed from the data and are mentioned in the
        main paper and online appendix.
        -   Runtime: about 3 minutes.

**Build:** The names of the folders in `scripts/code/01_build`
correspond to the names of the main do files above. The folders with
code that builds the data contain the individual programs described
below. The sub-folder `_name_cleanup/` includes code for cleaning the
name variables that is called on in various steps.

**Step 1:** `scripts/code/01_build/01_extract_icem_census_data/`

-   `01.01_extract_icem_self_variables.do` combines all observations for
    a census year to a single file, extracts the variables needed for
    the analysis, and saves different categories of variables to
    separate files
-   `01.02_fix_icem_household_ids.do` makes corrections to the original
    household ID variable
-   `01.03_extract_icem_father_variables.do` extracts variables for
    fathers to be merged into an individual’s record
-   `01.04_extract_icem_mother_variables.do` extracts variables for
    mothers to be merged into an individual’s record
-   `01.05_extract_icem_head_variables.do` extracts variables for the
    household head to be merged into an individual’s record
-   `01.06_create_icem_sibling_ids.do` constructs sibling identifiers
-   `01.07_extract_icem_spouse_variables.do` extracts variables for the
    spouse to be merged into an individual’s record
-   `01.08_extract_icem_child_variables.do` extracts variables for
    children to be merged into a parent’s record

**Step 2:** `scripts/code/01_build/02_clean_icem_names_birthplaces/`

-   `02.00_input_nicknames_for_matching.do` sets up a crosswalk file
    with nicknames to use in linking census and hospital data
-   `02.01_icem_extract_names.do` extracts and cleans variables with
    names
-   `02.02_icem_name_distribution.do` constructs variables with the
    frequency of each name
-   `02.03_icem_birthplace_cleanup.do` cleans and codes the birth place
    variables

**Step 3:** `scripts/code/01_build/03_icem_census_linkage/`

-   `03.01_extract_icem_matching_vars.do` extracts the variables used in
    linkage from the I-CeM complete count data
-   `03.02_icem_blocking_setup.do` performs pre-processing steps prior
    to blocking
-   `03.03_icem_blocking.do` performs the blocking step in the census
    linkage
-   `03.04_icem_linkage_unique_sample.do` creates the linked samples of
    unique matches between censuses

**Step 4:** `scripts/code/01_build/04_extract_hospital_data/`

-   `04.00_input_london_district_list.do` extracts a crosswalk of
    districts for London from a UK-wide file
-   `04.01_compile_hharp_data.do` cleans the Great Ormond Street
    Hospital data from HHARP
-   `04.02_combine_hospital_data.do` combines the HHARP data with the
    hospital records from St. Bartholomew’s and Guy’s Hospitals
-   `04.03_clean_residential_addresses.do` cleans the address variable
    in the hospital records and codes residential districts and parishes
-   `04.04_clean_cause_of_admission.do` cleans and codes the cause of
    admission variable
-   `04.05_create_health_deficiency_index.do` constructs the health
    deficiency index variable using the cause of admission information

**Step 5:** `scripts/code/01_build/05_census_hospital_record_linkage/`

-   `05.01_extract_hospital_matching_vars.do` extracts the variables
    from the hospital records used in linking to the census
-   `05.02_icem_hosp_matching.do` links the hospital records to the
    census

**Step 6:** `scripts/code/01_build/06_build_analysis_data/`

-   .do files in the sub-folder `_sibling_restrictions/` impose
    restrictions and select the siblings used in the analysis, and are
    called by .do files in this step

**Analysis:** All tables and figures in the main paper and the online
appendix are created by the .do files in the folder
`scripts/code/02_analysis`

-   `01_tables_figures.do` creates tables and figures in the main paper
-   `02_online_appendix.do` creates tables and figures in the online
    appendix
-   `03_intext_statistics.do` calculates numbers that are mentioned in
    main paper or online appendix

### Packages

All packages and dependencies are included. A list of packages used for
Stata is below:

#### Stata

carryforward, estout, ftools, gtools, jarowinkler, keeporder, labutil,
nysiis, reghdfe, regsave, unique

## Instructions for replicators

1.  Unzip, download, or clone the replication folder.
2.  Set the global `PROJ_PATH` on line 29 in `0_run_all.do`, which
    points to the replication folder.
3.  Download the I-CeM complete count census data to the folder
    `raw/icem` according to the description above. The I-CeM data
    downloaded as `.csv` files can be converted to `.dta` files using
    the shell script `csv_to_dta.sh` in the `shells/` folder. Save each
    county and year to a separate file in the `raw/icem` folder
    following the name convention `England_YYYY_County`. The names of
    the counties should correspond to the lists of counties in lines 13
    to 19 of `01.01_extract_icem_self_variables.do`.
4.  Add the Special License data with names to the folder `raw/icem_sl`.
    Convert the `.txt` files to `.dta` files using the shell script
    `csv_to_dta.sh`. The `.dta` files should be named
    `ICEM_NAMES_EW_YYYY`.
5.  Obtain the HHARP hospital data and save to `raw/hharp`.
6.  The complete count census data from NAPP used in this study include
    the variable `GB81A_ADDRESS` that is no longer publicly available.
    The extracts of NAPP data used in lines 10 and 118 of
    `scripts/code/01_build/04_extract_hospital_data/04.03_clean_residential_addresses.do`
    need to be replaced with the I-CeM Special License data that include
    the address variable from the 1881 census of England and Wales. The
    variable names may need to be changed.
7.  Save and run `0_run_all.do`.

## Tables and figures

The `.tex` or `.eps` files containing the tables and figures can be
found in `/output`.

## Data citations

Hawkins, Sue. (2010). *HHARP: The Historic Hospital Admission Records
Project* (<https://hharp.org/>).

Minnesota Population Center. (2008). *North Atlantic Population Project:
Complete count microdata, Version 2.0 \[Machine-readable database\].*
Minneapolis: Minnesota Population Center.

Schurer, K., Higgs, E. (2020). *Integrated Census Microdata (I-CeM),
1851-1911*. \[data collection\]. UK Data Service. SN: 7481,
<http://doi.org/10.5255/UKDA-SN-7481-2>.

Schurer, K., Higgs, E. (2020). *Integrated Census Microdata (I-CeM),
1851-1911*. \[data collection\]. UK Data Service. SN: 7481,
<http://doi.org/10.5255/UKDA-SN-7481-2>.

The National Archives. (2013). *1891 Census Street Index*. \[website\].
The National Archives.
[URL](https://webarchive.nationalarchives.gov.uk/ukgwa/+/http://yourarchives.nationalarchives.gov.uk/index.php?title=Category:1891_census_registration_districts)

## Package citations

## Stata

Tony Brady, 1998. “UNIQUE: Stata module to report number of unique
values in variable(s),” Statistical Software Components S354201, Boston
College Department of Economics, revised 18 Jun 2020.

Mauricio Caceres Bravo, 2018. “GTOOLS: Stata module to provide a fast
implementation of common group commands,” Statistical Software
Components S458514, Boston College Department of Economics, revised 02
February 2022.

Sergio Correia, 2016. “FTOOLS: Stata module to provide alternatives to
common Stata commands optimized for large datasets,” Statistical
Software Components S458213, Boston College Department of Economics,
revised 26 October 2019.

Sergio Correia, 2014. “REGHDFE: Stata module to perform linear or
instrumental-variable regression absorbing any number of
high-dimensional fixed effects,” Statistical Software Components
S457874, Boston College Department of Economics, revised 18 Nov 2019.

James Feigenbaum, 2014. “JAROWINKLER: Stata module to calculate the
Jaro-Winkler distance between strings,” Statistical Software Components
S457850, Boston College Department of Economics, revised 13 Oct 2016.

James Feigenbaum, 2014. “KEEPORDER: Stata module to keep and order a set
of variables,” Statistical Software Components S457859, Boston College
Department of Economics, revised 02 July 2014.

Ben Jann, 2004 “ESTOUT: Stata module to make regression tables,”
Statistical Software Components S439301, Boston College Department of
Economics, revised 25 March 2022.

David Kantor, 2004. “CARRYFORWARD: Stata module to carry forward
previous observations,” Statistical Software Components S444902, Boston
College Department of Economics, revised 15 January 2016.

Julian Reif, 2008. “REGSAVE: Stata module to save regression results to
a Stata-formatted dataset,” Statistical Software Components S456964,
Boston College Department of Economics, revised 12 Apr 2020.

Adrian Sayers, 2014. “NYSIIS: Stata module to calculate nysiis codes
from string variables,” Statistical Software Components S457936, Boston
College Department of Economics, revised 21 Jul 2018.
