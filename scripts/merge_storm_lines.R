library(tidyverse)
library(sf)
library(here)

# Import storm info

df <- read.csv(here("Data/NOAA/stormStats.csv"))%>%
  filter(landfall == "YES")%>%
  mutate(ID = tolower(ID))


# List all line shapefiles
list <- data.frame(path = list.files(here("Data/NOAA/officialTracks/"),recursive = TRUE,full.names = TRUE, pattern = "lin.shp$"))

files <- list%>%
  mutate(ID = substr(path,63,70))%>%
  filter(ID %in% df$ID)




# Write to a separate folder
#for(n in 1:nrow(files)){
#  sf <- st_read(files[n,1])
#  st_write(sf, paste0(here("Data/NOAA/officialTracks/landfalls"),"/",files[n,2],"_lin.shp"))
#}

sf <- st_read(files[1,1])%>%
  st_union()%>%
  st_as_sf()%>%
  mutate(ID = files[1,2])


for(n in 2:nrow(files)){
  strm <- st_read(files[n,1])%>%
    filter(st_is_valid(geometry) == TRUE)%>%
    st_union()%>%
    st_as_sf()%>%
    mutate(ID = files[n,2])%>%
    select(ID)
  
  sf <- rbind(sf,strm)
}

st_write(sf, here("Data/NOAA/officialTracks/landfalls/allstorms_lin.shp"))
