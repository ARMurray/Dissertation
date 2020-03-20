# This script checks the completeness of the downloaded SAMP data
library(lubridate)
library(here)

files <- list.files(here("Data/SMAP/SPL4SMAU"), pattern = ".h5$", recursive = TRUE)

dates <- ymd_hms(substr(files,16,30))

# First and Last Dates
dates[1]
dates[length(dates)]

# First and Last File Names
files[length(files)]
files[1]

# Is the number of files correct?
# A file every 3 hours

fpd <- 24/3
fpy <- 365*fpd

length(files)/fpy

