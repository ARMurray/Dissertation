library(tidyverse)
library(sf)
library(here)
library(leaflet)

shps <- list.files("C:/Users/HP/OneDrive - University of North Carolina at Chapel Hill/Dissertation/Data/Official_NOAA_Tracks/",
                   pattern = "pts.shp$",recursive = TRUE, full.names = TRUE)


test <- st_read(shps[8])

leaflet(test)%>%
  addTiles()%>%
  addMarkers()


sf <- st_read(shps[1])%>%
  select(c("STORMNAME","DTG","YEAR","MONTH","DAY","HHMM","MSLP","BASIN","STORMNUM","STORMTYPE","INTENSITY","SS","LAT","LON","geometry" ))%>%
  st_transform(crs = 4326)

for(n in 2:length(shps)){
  shp <- st_read(shps[n])%>%
    select(c("STORMNAME","DTG","YEAR","MONTH","DAY","HHMM","MSLP","BASIN","STORMNUM","STORMTYPE","INTENSITY","SS","LAT","LON","geometry" ))%>%
    st_transform(crs=4326)
  sf <- rbind(sf,shp)
}

leaflet(sf)%>%
  addTiles()%>%
  addCircleMarkers(
    radius = 6,
    color = "#6aa14d",
    stroke = TRUE, fillOpacity = 0.6
  )

st_write(sf, here("Data/NOAA/NOAA_Storm_Points_2015_2019.shp"))
