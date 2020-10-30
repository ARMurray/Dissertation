library(rhdf5)
library(tidyverse)
library(sf)
library(here)


# This script takes an h5 file from SMAP and creates a template polygon layer to use with SMAP data
# This script completely relies on the sf package and does not require the traditional GDAL tools



# Identify the folder which contains all of the SMAP data files (both .h5 and .xml files)
folder <- here("Data/SMAP/SPL4SMAU")

# List the .h5 files (These are the raster without spatial extents)
h5Files <- list.files(path = folder, pattern = ".h5$", recursive = TRUE, full.names = TRUE)

file <- open <- H5Fopen(h5Files[1])

centroids <- data.frame("x" = as.vector(open$cell_lon), "y" = as.vector(open$cell_lat))%>%
  mutate("z" = paste0("x",x,"y",y))

# Filter to Southeast U.S.: 
seus <- centroids%>%
  filter(x > -100 & x < -74 & y > 20 & y < 38)

# Convert lat lon to sf points layer and make sure it is using EASE Grid 2.0
pts <- sf::st_as_sf(seus, coords = c("x", "y"), 
                              crs = 4326, agr = "constant")%>%
  st_transform(crs = 6933)

# Create voronoi polygons from the centroids
polys <-st_voronoi(st_union(pts))%>%
  st_as_sf()%>%
  st_cast()%>%
  st_join(pts)


# Calculate area in order to remove the border polygons
polys$area <- st_area(polys)


# Remove the border polygons
export <- polys%>%
  filter(as.numeric(area) < 100000000)%>%
  select(z)

# Give better column names
colnames(export) <- c("Cell_ID","geometry")


# Export a shapefile
st_write(export, here("Data/SMAP/SE_US_SMAP_Template.shp"), append = FALSE)

