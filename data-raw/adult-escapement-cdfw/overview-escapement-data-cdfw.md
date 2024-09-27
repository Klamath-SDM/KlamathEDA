Fall Chinook Escapement - Klamath Basin Watershed
================
\[Your name\]
\[Date\]

The purpose of this markdown is to give an overview of the types of data
available, temporal coverage, geographic coverage, and to get an idea of
the amount of work that it would take us to clean it up and use it.

This data was shared by [Morgan
Knechtle](mailto::Morgan.Knechtle@wildlife.ca.gov) and it is publicly
available at [California Open Data
Portal](https://data.ca.gov/dataset/fall-chinook-escapement-klamath-basin-watershed)

### Overview

Adult salmonid data collected from various areas within the Klamath
basin watershed. Various tributaries are monitored using video systems
(Bogus Creek, Shasta River, Scott River), other areas are monitored
using redd/carcass surveys, and Iron gate Hatchery adult returns. The
main purpose of the data is to estimate escapement of fall Chinook
slamon, although data on other species (steelhead, coho salmon) also
collected.

### Data Available

#### Bogus Creek carcass spawning

- Title: Bogus Creek carcass spawning
- Extent: Survey is located on Bogus Creek from the confluence with the
  Klamath River upstream 3.6 miles.
- Description: Data includes daily carcass recoveries from spawning
  grounds surveys. Biological data from carcasses includes date
  recovered, species, condition, reach collected, observed clips, fork
  length and biological sample collected. Date utilized to describe
  population estimated at adult fish counting facility.
- Initial collection: October 2008
- Final collection: December 2022
- Fields included:

<!-- -->

    ## tibble [560 × 17] (S3: tbl_df/tbl/data.frame)
    ##  $ SurveyID   : chr [1:560] "Bogus 2022" "Bogus 2022" "Bogus 2022" "Bogus 2022" ...
    ##  $ ObsDate    : POSIXct[1:560], format: "2022-10-21" "2022-10-21" ...
    ##  $ Code       : chr [1:560] "1" "1" "1" "1" ...
    ##  $ SppCode    : chr [1:560] "KS" "KS" "KS" "KS" ...
    ##  $ Length     : num [1:560] 67 65 55 63 65 63 71 61 57 64 ...
    ##  $ Sex        : chr [1:560] "F" "F" "F" "F" ...
    ##  $ Spawned    : logi [1:560] FALSE TRUE FALSE FALSE FALSE FALSE ...
    ##  $ A_Clip     : chr [1:560] "FALSE" "TRUE" "FALSE" "FALSE" ...
    ##  $ H_Tag      : num [1:560] NA 16878 NA NA 14186 ...
    ##  $ NonRnd     : logi [1:560] FALSE TRUE FALSE TRUE FALSE TRUE ...
    ##  $ Condition  : chr [1:560] "2" "2" "2" "5" ...
    ##  $ SampleNo   : chr [1:560] "BO102122R101" NA "BO102122R103" NA ...
    ##  $ Scales     : logi [1:560] TRUE FALSE TRUE FALSE TRUE FALSE ...
    ##  $ Tissue     : logi [1:560] TRUE FALSE FALSE FALSE FALSE FALSE ...
    ##  $ Otoliths   : logi [1:560] TRUE FALSE FALSE FALSE FALSE FALSE ...
    ##  $ RecID      : chr [1:560] "41183" "41184" "41185" "41186" ...
    ##  $ Sample Rate: chr [1:560] "Sampled 1:1" "Sampled 1:1" "Sampled 1:1" "Sampled 1:1" ...

- Name of xlsx file: DMP_Bogus Creek Carcass Data 2008_2022.xlsx

Cleaning implications:

- Data in the xlsx is distributed by year per tab
- 2013 - 2022 data has the same fields, 2008 - 2012 are missing
  “condition” column. There are some minimal inconsistencies with column
  names accross years  
- Fields definition list:
  - Location and year
  - Date carcass encountered
  - Reach number
  - Species observed
  - Fork length measured in centimeters
  - Sex of fish observed
  - Determination of sucessful spawning
  - description of hatchery marks
  - unique number associated with head
  - was carcass included in systematic sample
  - Condition description
  - Unique sample number of each carcass
  - Where scales collected
  - Was tissue collected
  - Where otoliths collected
  - unique number for the record
  - Systematic sample rate

#### Upper Salmon River Carcass Mark Recapture Spawning

- Title: Upper Salmon River Carcass Mark Recapture Spawning Grounds
  Surveys
- Extent: Survey is located on the Upper Salmon River (above Nordheimer
  Campground), including Upper Mainstem, and North and South Forks of
  the Salmon River and tributaries.
- Description: Data includes daily carcass recoveries from spawning
  grounds surveys. Biological data from carcasses, disposition, and jaw
  tagging information used in a mark recapture population estimation
  study. Data provided used in Program R Cormack Jolly Seber popoulation
  estimator. Contemporary data set.
- Initial collection: October 2011
- Final collection: December 2022
- Fields included:

<!-- -->

    ## tibble [132 × 10] (S3: tbl_df/tbl/data.frame)
    ##  $ Date    : POSIXct[1:132], format: "2022-10-11" "2022-10-11" ...
    ##  $ Path    : chr [1:132] "1" "1" "1" "2" ...
    ##  $ FL      : num [1:132] 62 77 79 60 NA 40 66 89 69 69 ...
    ##  $ SEX     : chr [1:132] "M" "F" "F" "F" ...
    ##  $ SPAWN?  : chr [1:132] "Y" "Y" "Y" "N" ...
    ##  $ Tag App.: chr [1:132] "15743" "15412" "15418" NA ...
    ##  $ Recap.  : chr [1:132] NA NA NA NA ...
    ##  $ Rel/Chop: chr [1:132] "R" "R" "R" "C" ...
    ##  $ Clips   : logi [1:132] NA NA NA NA NA NA ...
    ##  $ Headtag : logi [1:132] NA NA NA NA NA NA ...

- Name of xlsx file: Salmon River Carcass Mark Recapture 2011-2022.xlsx

Cleaning implications:

- Data in the xlsx is distributed by year per tab

- Column names accross the different years are pretty similar

- Fields definition list:

  - Date carcass encountered
  - Numerical value dispositon of carcass
  - Fork length measured in centimeters
  - Sex of fish observed
  - Determination of sucessful spawning
  - unique tag \# attached to carcass upon first encounter
  - unique tag \# of tag on carcass during recapture
  - release or re-released tagged fish, or chopped untagged fish
  - description of hatchery marks
  - unique identified tag applied upon recovery of known hatchery origin
    fish
