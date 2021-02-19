library(tidyverse)
library(ncdf4)
library(raster)
library(sf)
library(here)
library(MODIS)
library(spatialEco)

storminfo <- read.csv(here("Data/NOAA/stormStats.csv"))%>%
  filter(landfall == "YES")%>%
  mutate(Name = tolower(Name))%>%
  dplyr::select(ID,Name)

laifiles <- list.files(here("Data/LAI/"), pattern = ".tif", recursive = TRUE, full.names = TRUE)
lainames <- list.files(here("Data/LAI/"), pattern = ".tif", recursive = TRUE, full.names = FALSE)

# Template for SMAP pixels
template <- st_read(here("Data/SMAP/SE_US_SMAP_Template.shp"))

# Create output csv
outcsv <- template%>%
  st_drop_geometry()%>%
  dplyr::select(Cell_ID)

# Iterate through storms to create a table of mean LAI per SMAP pixel
# Create matching storm names
names <- as.data.frame(lainames)%>%
  separate(lainames,into = c("storm","path"), sep = "/")%>%
  mutate(fullpath = laifiles,
         storm = tolower(storm))%>%
  left_join(storminfo, by = c("storm" = "Name"))

for(n in 1:nrow(names)){
  storm <- names$storm[n]
  
  print(paste0("Starting: ",storm," --- ",Sys.time()))
  
  rast <- raster(names$fullpath[n])%>%
    projectRaster(rast, crs = 3975)
  
  # Reclassify
  m <- c(100, 256, 0)
  rclmat <- matrix(m, ncol=3, byrow=TRUE)
  rc <- reclassify(reg, rclmat)
  
  print(paste0("Computing Zonal Statistics... ",Sys.time()))
  
  # Zonal Statistics
  zonal <- zonal.stats(template, rc, stats = "mean")
  
  # Create output table for each storm
  
  out <- outcsv%>%
    cbind(zonal)
  
  write.csv(out, paste0(here("Data/LAI/Zonal"),"/",storm,"_mean_LAI.csv"))

  print(paste0("Finished: ",storm," --- ",Sys.time()))
  
}

