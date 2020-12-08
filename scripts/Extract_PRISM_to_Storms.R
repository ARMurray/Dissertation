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


#for(n in 1:nrow(storms)){
#  prism_set_dl_dir(paste0(here("Data/Prism",storms$ID[n])), create = TRUE)
#  get_prism_dailys(type = "ppt" ,minDate = date(storms$lFall_dateTime[n]) - 1, maxDate = date(storms$end[n]) + 5, keepZip = FALSE)
#}

# List sotrm track points
pts <- data.frame(Path = list.files(here("Data/NOAA/officialTracks/"), recursive = TRUE, full.names = TRUE, pattern = "pts.shp$"),
                  File = list.files(here("Data/NOAA/officialTracks/"), recursive = TRUE, full.names = FALSE, pattern = "pts.shp$"))%>%
  mutate(ID = substr(File,6,13))


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
    filter(layer > 50)%>%
    st_transform(6933)
  
  # Add filter so that we only include ppt that occured within X km
  strmtrk <- pts%>%
    filter(ID == tolower(folders[n]))
  
  track <- st_read(strmtrk$Path)%>%
    st_transform(6933)
  
  withinX <- as.data.frame(st_is_within_distance(shpJoin, track, 400000))%>%
    dplyr::select(row.id)%>%
    distinct()
  
  shpFilt <- shpJoin[withinX$row.id,]%>%
    dplyr::select(Cell_ID,layer)
  
  colnames(shpFilt) <- c("Cell_ID","totPPT","geometry")
  
  st_write(shpFilt, paste0(here("Data/prism"),"/",folders[n],"/",folders[n],"_ppt_GT_50mm.shp"), append = FALSE)
  
  print(paste0("Finished ",folders[n]," at: ",Sys.time()))
}


# Make a layer with all storm ppt counts and cumulative.

stormFiles <- list.files(here("Data/prism"),pattern = "50mm.shp",full.names = TRUE, recursive = TRUE)


out <- data.frame()

for(n in 1:length(stormFiles)){
  file <- st_read(stormFiles[n])%>%
    st_drop_geometry()
  out <- rbind(out,file)
}

shp2 <- out%>%
  group_by(Cell_ID)%>%
  mutate(allStormsPPT = sum(totPPT))%>%
  ungroup()%>%
  dplyr::select(Cell_ID,allStormsPPT)%>%
  distinct()%>%
  left_join(template)%>%
  st_as_sf()

colnames(shp2) <- c("Cell_ID","allstorms","geometry") # Shorten names so shapefile driver does not

#ggplot(shp2)+
#  geom_sf(aes(col = allStormsPPT, fill = allStormsPPT))

# Join all of the storm specific data
shps <- list.files(here("Data/prism"), pattern = "50mm.shp$", recursive = TRUE, full.names = TRUE) # Full file path
names <- list.files(here("Data/prism"), pattern = "50mm.shp$", recursive = TRUE, full.names = FALSE) # Short file path

for(n in 1:length(shps)){
  shp <- st_read(shps[n])%>%   # import 1 shp at a time
    st_drop_geometry()%>% # drop geometry
    dplyr::select(Cell_ID,totPPT) # select only ID and value columns
  stormID <- substr(names[n],1,8) # create storm ID
  colnames(shp) <- c("Cell_ID",stormID) # Rename the value column based on storm ID
  shp2 <- shp2%>%   # Add the new column to the existing dataset
    left_join(shp)
}

st_write(shp2, here("Data/prism/pptByStorm.shp"),append = FALSE)


