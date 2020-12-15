library(tidyverse)
library(plotly)
library(sf)
library(here)

SMAP_Stats_Files <- data.frame(path = list.files(here("Data/SMAP/SMAP_Stats"), pattern = ".csv", full.names = TRUE),
                               ID = substr(list.files(here("Data/SMAP/SMAP_Stats"), pattern = ".csv", full.names = FALSE),12,19))

si <- read.csv(here("Data/NOAA/stormStats.csv"))

ppt <- st_read(here("Data/prism/pptByStorm.shp"))%>%
  select(!al112016)

nlcd <- st_read(here("Data/nlcd/NLCD_2016_SE_Zonal_Stats.shp"))

dfAll <- data.frame()

for(i in 4:ncol(ppt)-1){
  df <- select(ppt,c(1,i))%>%
    st_drop_geometry()
  colnames(df) <- tolower(colnames(df))
  
  smapPath <- SMAP_Stats_Files%>%
    filter(ID == colnames(df)[2])
  
  smapdf <- read.csv(smapPath$path)
  
  join <- df%>%
    left_join(smapdf, by=c("cell_id"="Cell_ID"))
  
  colnames(join)[2] <- "ppt_mm"
  
  # Remove areas where there was not enough rain
  filt <- join%>%
    filter(!is.na(ppt_mm))
  
  # Join it to NLCD shapefile
  sfOut <- nlcd%>%
    left_join(join, by = c("Cell_ID" = "cell_id"))
  
  
  # Write a new shapefile for each storm
  write.csv(sfOut, paste0(here("Data/Analysis"),"/",colnames(df)[2],"_combo.shp"))
  
  # create a singular csv for all storms
  dfJoin <- sfOut%>%
    st_drop_geometry()
  
  dfAll <- rbind(dfAll, dfJoin)

}

# Write the csv with all data
write.csv(dfAll, here("Data/Analysis/AllStorms_Combo.csv"))

