# Soil Grids Extractor
## Instructions available: https://git.wur.nl/isric/soilgrids/soilgrids.notebooks/-/blob/master/markdown/wcs_from_R.md

library(XML)
library(tidyverse)
library(tidyr)
library(rgdal)
library(sf)
library(gdalUtils)
library(here)

# Set variables of interest

vars <- c("bdod","cec","cfvo","clay","nitrogen","phh2o","sand","silt","soc","ocd","ocs")
depths <- c("0-5cm","5-15cm","15-30cm","30-60cm","60-100cm","100-200cm")
qs <- c("Q0.5","q0.50","q0.95")

voi = "nitrogen" # variable of interest
depth = "5-15cm"
quantile = "Q0.5"

# Make a list of all VOI layers we want to download.
voiDF <- expand.grid(vars,depths)%>%
  mutate(voi = paste0(Var1,"_",Var2,"_","Q0.5"))

#voi_layer = paste(voi,depth,quantile, sep="_") # layer of interest 


# Import SMAP Template
smap <- st_read(here("Data/SMAP/SE_US_SMAP_Template.shp"))%>%
  st_transform('+proj=igh +lat_0=0 +lon_0=0 +datum=WGS84 +units=m +no_defs')

# Set bounding information
# Get bounding box for Texas
#tx <- USAboundaries::us_states()%>%
#  dplyr::filter(name == "Texas")%>%
#  st_transform('+proj=igh +lat_0=0 +lon_0=0 +datum=WGS84 +units=m +no_defs')

st_bbox(smap)

# Homolosine
xmin <- -11122440
xmax <- -8896461
ymin <- 2720837
ymax <- 4216124 

# Bounding box in the form of (xmin,ymax,xmax,ymin)
bb=c(xmin,ymax,xmax,ymin)

igh='+proj=igh +lat_0=0 +lon_0=0 +datum=WGS84 +units=m +no_defs'

# Subset if you need to
voiDF <- voiDF%>%
  filter(voi %in% c("phh2o_5-15cm_Q0.5"))

# Redo clay 100-200cm, SOC 100-200cm, nitrogen 0-5, phh2o 5-15, sand 100-200

print(paste0("Began at: ",Sys.time()))
for(i in 1:nrow(voiDF)){
  voi <- voiDF$Var1[i]
  voi_layer <- voiDF$voi[i]
  
  wcs_path = paste0("https://maps.isric.org/mapserv?map=/map/",voi,".map") # Path to the WCS. See maps.isric.org
  wcs_service = "SERVICE=WCS"
  wcs_version = "VERSION=2.0.1" # This works for gdal >=2.3; "VERSION=1.1.1" works with gdal < 2.3.
  
  
  # Describe the coverage layer
  ## define the request as DescribeCoverage and we create a string for the full request using also the variables previously defined
  wcs_request = "DescribeCoverage" 
  
  wcs = paste(wcs_path, wcs_service, wcs_version, wcs_request, sep="&")
  
  # create a XML that can be used with the gdalinfo utility after being saved to disk: 
  l1 <- newXMLNode("WCS_GDAL")
  l1.s <- newXMLNode("ServiceURL", wcs, parent=l1)
  l1.l <- newXMLNode("CoverageName", voi_layer, parent=l1)
  
  # Save to local disk
  xml.out = here("Data/SoilGrids/SEUS/xml/sg.xml")
  saveXML(l1, file = xml.out)
  
  # Finally we use gdalinfo to get the description of the layer
  gdalinfo(here("Data/SoilGrids/Texas/xml/sg.xml"))
  
  
  # Example 2: Download a Tiff for a region of interest (ROI)
  
  wcs = paste(wcs_path,wcs_service,wcs_version,sep="&")
  
  # Then we create a XML that can be used with the gdal utility after being saved to disk:
  l1 <- newXMLNode("WCS_GDAL")
  l1.s <- newXMLNode("ServiceURL", wcs, parent=l1)
  l1.l <- newXMLNode("CoverageName", voi_layer, parent=l1)
  
  # Save to local disk
  xml.out = here("Data/SoilGrids/SEUS/xml/sg.xml")
  saveXML(l1, file = xml.out)
  
  # Finally we use gdal_translate to get the geotiff locally.
  file.out <- paste0(here("Data/SoilGrids/SEUS/tif"),"/",voi_layer,".tif")
  
  gdal_translate(xml.out, file.out,
                 tr=c(250,250), projwin=bb,
                 projwin_srs = igh, co=c("TILED=YES","COMPRESS=DEFLATE","PREDICTOR=2","BIGTIFF=YES","GDAL_HTTP_UNSAFESSL=YES"),
                 verbose=TRUE
  )
  
  print(paste0("Finished ",voi_layer, "at: ",Sys.time()))
  
}
  