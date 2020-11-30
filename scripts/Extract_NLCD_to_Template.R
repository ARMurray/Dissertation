library(FedData)
library(tidyverse)
library(raster)
library(sf)
library(here)

# Load the SMAP template

template <- st_read(here("Data/SMAP/SE_US_SMAP_Template.shp"))%>%
  st_transform(4326)

nlcd <- raster("Y:/Data/NLCD/NLCD_2016_Land_Cover_L48_20190424.img")


ex <- extract(nlcd,template)
