library(raster)
library(gdalUtils)
library(dplyr)
library(stringr)

# Identify the folder which contains all of the SMAP data files (both .h5 and .xml files)
folder <- here("SMAP_Downloads")

# Identify the folder you want to write the output GeoTiffs to.
outFolder <- here("SMAP_GeoTIFFs")

# List the .h5 files (These are the raster without spatial extents)
h5Files <- list.files(path = folder, pattern = ".h5$", recursive = TRUE)

# List the .xml files (These have the spatial extents for the rasters)
xmlFiles <- list.files(path = here("SMAP_Downloads"), pattern = ".iso.xml$", recursive = TRUE)

# Here we will iterate through the folder file by file and convert the seperate
# H5 and xml files to singular GeoTIFFs

start <- Sys.time()

for(n in 1:length(h5Files)){
  h5 <- paste0(folder,"/",h5Files[n])
  # Convert from H5 to GeoTiff and save it (This still won't have any spatial reference info)
  gdal_translate(h5,paste0(outFolder,"/",substr(h5Files[n],1,nchar(h5Files[n])-3),".tif"), of = "GTiff", sd_index = 86,verbose=TRUE, overwrite = TRUE)
  # Import the GeoTIff and assign the correct projection (global cylindrical EASE-Grid 2.0 (Brodzik et al. 2012))
  raster <- raster(paste0(outFolder,"/",substr(h5Files[n],1,nchar(h5Files[n])-3),".tif"))
  projection(raster) <- "+proj=cea +lon_0=0 +lat_ts=30 +x_0=0 +y_0=0 +ellps=WGS84 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs"
  # Import the xml file
  xmlLines <- readLines(paste0(folder,"/",xmlFiles[n]))
  xmlString <- toString(xmlLines)
  # Find the start of the extent coordinates
  coordsStartLoc <- str_locate(xmlString,"srsName=\"http://www.opengis.net/def/crs/EPSG/4326\">")
  coordsStartLoc <- coordsStartLoc[!is.na(coordsStartLoc)][2]
  # Find the end of the extent coordinates
  coordsEndLoc <- str_locate(xmlString,"</gml:posList>")
  coordsEndLoc <- coordsEndLoc[!is.na(coordsEndLoc)][1]
  # Extract the coordinates
  coords <- substr(xmlString,coordsStartLoc+1,coordsEndLoc-1)
  coords <- str_split(coords, " ", simplify = TRUE)
  options(digits = 15)
  xmin <- as.numeric(coords[2])
  xmax <- as.numeric(coords[4])
  ymin <- as.numeric(coords[5])
  ymax <- as.numeric(coords[1])
  # Project the raster to standard WGS84 so units are decimal degrees
  wgs84 <- projectRaster(raster, crs = "+proj=longlat +datum=WGS84 +no_defs")
  wgs84 <- setExtent(wgs84,extent(xmin,xmax,ymin,ymax))%>%
    trim()
  # Write the GeoTIFF with correct spatial extent
  writeRaster(wgs84,paste0(outFolder,"/",substr(h5Files[n],1,nchar(h5Files[n])-3),".tif"),overwrite=TRUE)
}

end <- Sys.time()
print(paste0("Converted: ",length(h5Files)," files to GeoTiffs in: ",end-start))
