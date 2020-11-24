#devtools::install_github('ropensci/prism')
library(lubridate)
library(tidyverse)
library(sf)
library(prism)
library(here)
library(raster)

# Download Prism Data by Storm

storms <- read.csv(here("Data/NOAA/stormStats.csv"))%>%
  filter(landfall == "YES")%>%
  mutate(lFall_dateTime = lubridate::ymd_hms(lFall_dateTime),
         end = lubridate::ymd_hms(end))

# Import template for spatial aggregation to SMAP pixels
template <- st_read(here("Data/SMAP/SE_US_SMAP_Template.shp")) #Import template for SMAP pixels


for(n in 1:nrow(storms)){
  prism_set_dl_dir(paste0(here("Data/Prism",storms$ID[n])), create = TRUE)
  get_prism_dailys(type = "ppt" ,minDate = date(storms$lFall_dateTime[n]) - 1, maxDate = date(storms$end[n]) + 5, keepZip = FALSE)
}

# Aggregate ppt totals by storm
folders <- list.files(here("Data/prism"),include.dirs = TRUE)

for(n in 1:length(folders)){
  rasters <- list.files(paste0(here("Data/prism"),"/",folders[n]), recursive = TRUE, pattern = ".bil$", full.names = TRUE)
  rainDays <- length(rasters) # Count days of rain recorded
  allrasters <- stack(rasters) # Import all rasters for individual storm
  totPPT <- sum(allrasters)%>% # Calculate total precipitation
    projectRaster(crs = "+proj=cea +lat_ts=30 +lon_0=0 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs +type=crs")
  # Zonal Statistics to determine mean rainfall by SMAP pixel
  extract <- extract(totPPT, template, fun=mean, na.rm = TRUE, df = TRUE)
  
  shpJoin <- cbind(template,extract)%>%
    filter(layer > 50)
  
  st_write(shpJoin, paste0(here("Data/prism"),"/",folders[n],"/",folders[n],"_ppt_GT_50mm.shp"))
  
  print(paste0("Finsihed ",folders[n]," at: ",Sys.time()))
}


