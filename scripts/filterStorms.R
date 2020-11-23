# This script loads all atlantic cyclone activity and determines which made landfall

library(tidyverse)
library(sf)
library(USAboundaries)
library(lubridate)
library(here)

# Load the U.S. Boundary and filter to southeast
se <- us_boundaries(resolution = 'low')%>%
  filter(name %in% c("Puerto Rico","Texas","Louisiana","Mississippi","Alabama","Florida","Georgia","South Carolina","North Carolina","Virginia","Maryland","Delaware"))%>%
  st_union()%>%
  st_as_sf()

#plot(st_geometry(se))

# List all point files from NOAA
pts <- list.files(here("Data/NOAA/officialTracks"), recursive = TRUE, pattern = "pts.shp$",full.names = TRUE)
fileNames <- list.files(here("Data/NOAA/officialTracks"), recursive = TRUE, pattern = "pts.shp$",full.names = FALSE)

df <- data.frame()
  
for(n in 1:length(pts)){
  sf <- st_read(pts[n])%>%
  st_transform(crs = 4326)
# Check for intersections
  intersects <- st_intersects(se,sf) # Check an intersection between the U.S. and the storm points
  landfall <- ifelse(as.character(intersects)=="integer(0)", "NO","YES") # Determine if it made landfall in U.S.
  
  # Create a data fram which lists important storm stats
  sf$dateTime <- ymd_hm(paste0(sf$YEAR,"/",sf$MONTH,"/",sf$DAY," ",substr(sf$HHMM,1,2),":",substr(sf$HHMM,3,4))) # Create a date column
  start <- sf$dateTime[1] # First storm observation
  end <- sf$dateTime[nrow(sf)] # Last storm observation
  maxIntensity <- max(sf$INTENSITY) # Max wind speed
  max <- sf%>%
    filter(INTENSITY == maxIntensity)
  name <- max$STORMNAME[1] # Storm name at peak intensity
  maxss <- max(sf$SS) # Max Hurricane Category
  id <- substr(fileNames[n],6,13) # NOAA storm ID
  outDF <- data.frame(ID = id, Name = name, start = start, end = end, maxIntensity = maxIntensity,maxSS = maxss, landfall = landfall)

  df <- rbind(df,outDF) # Add to output data frame
}

write.csv(df, here("Data/NOAA/stormStats.csv"))

# Can use this to make it spatial
#tst <- sf %>% 
#  group_by(BASIN) %>%
#  summarise(do_union = FALSE) %>%
#  st_cast("LINESTRING")


ggplot(se)+
  geom_sf()+
  geom_sf(data = sf, color = 'red')+
  geom_sf(data = try, color = 'blue')
<- 