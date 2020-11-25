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
  
  print(paste0("Finished ",folders[n]," at: ",Sys.time()))
}


# Make a layer with all storm ppt counts and cumulative.

rasters2 <- list.files(here("Data/prism"), recursive = TRUE, pattern = ".bil$", full.names = TRUE)
import <- stack(rasters2)
sumAll <- sum(import)%>%
  projectRaster(crs = "+proj=cea +lat_ts=30 +lon_0=0 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs +type=crs")

# Zonal Statistics to determine mean rainfall by SMAP pixel
extract2 <- extract(sumAll, template, fun=mean, na.rm = TRUE, df = TRUE)

shpJoin2 <- cbind(template,extract2)%>%
  filter(layer > 50)%>%
  dplyr::select(Cell_ID,layer)

colnames(shpJoin2) <- c("Cell_ID","AllStorms","geometry")

# Join all of the storm specific data
shps <- list.files(here("Data/prism"), pattern = "50mm.shp$", recursive = TRUE, full.names = TRUE) # Full file path
names <- list.files(here("Data/prism"), pattern = "50mm.shp$", recursive = TRUE, full.names = FALSE) # Short file path

for(n in 1:length(shps)){
  shp <- st_read(shps[n])%>%   # import 1 shp at a time
    st_drop_geometry()%>% # drop geometry
    dplyr::select(Cell_ID,layer) # select only ID and value columns
  stormID <- substr(names[n],1,8) # create storm ID
  colnames(shp) <- c("Cell_ID",stormID) # Rename the value column based on storm ID
  shpJoin2 <- shpJoin2%>%   # Add the new column to the existing dataset
    left_join(shp)
}

st_write(shpJoin2, here("Data/prism/pptByStorm.shp"))

ggplot(shpJoin2)+
  geom_sf(aes(fill = layer, color = layer))
