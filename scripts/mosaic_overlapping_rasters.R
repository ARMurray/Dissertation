library(raster)
library(gdalUtils)
library(here)
library(dplyr)

# Set the date you want to mosaic in the format: 'yyyymmdd'
date <- '20180921'

# SMAP images overlap eachother and also have a large number of NA values
# In many cases, NA values from one raster overlap real values in another
# raster. The function below will mosaic multiple rasters together but in cases
# where pixels overlap will default to the higher number. NA values in SMAP come
# as '-9999' so this allows NA values to be removed in favor of real values

mosaicList <- function(rasList){
  
  #Internal function to make a list of raster objects from list of files.
  ListRasters <- function(list_names) {
    raster_list <- list() # initialise the list of rasters
    for (i in 1:(length(list_names))){ 
      grd_name <- list_names[i] # list_names contains all the names of the images in .grd format
      raster_file <- raster::raster(grd_name)
      raster_file <- projectRaster(raster_file, snap, method = "ngb")
    }
    raster_list <- append(raster_list, raster_file) # update raster_list at each iteration
  }
  
  #convert every raster path to a raster object and create list of the results
  raster.list <-sapply(rasList, FUN = ListRasters)
  
  # edit settings of the raster list for use in do.call and mosaic
  names(raster.list) <- NULL
  #####This function deals with overlapping areas
  raster.list$fun <- max
  #raster.list$tolerance <- 0.1
  
  #run do call to implement mosaic over the list of raster objects.
  mos <- do.call(raster::mosaic, raster.list)
  
  #set crs of output
  crs(mos) <- crs(x = raster(rasList[1]))
  return(mos)
}

raster_files <- list.files(path =here("SMAP_GeoTIFFs"),pattern = date,full.names = TRUE )
snap <- raster(resolution = c(0.02839512,0.02433336), xmn = -120, xmx = -60, ymn = 0, ymx = 60, crs = "+proj=longlat +datum=WGS84 +no_defs") 
mosaic_layer <- mosaicList(raster_files )%>%
  trim()
plot(mosaic_layer)

writeRaster(mosaic_layer,paste0(here("SMAP_Mosaics_by_Date"),"/SMAP_Mosaic_",date,".tif"), overwrite = TRUE)
