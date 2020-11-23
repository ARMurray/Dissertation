library(rhdf5)
library(tidyverse)
library(sf)
library(here)


# This script will extract data from SMAP hdf5 files and join it to a spatial template 
# You need to have a template to join them to spatially and a list of h5 files you want
# to use. I import my entire folder of h5 files but use a filter to refine my analysis.

# Import template, which would have been created using *Ease_Grid_Template.R*. The default (already created)
# is for the southeastern United States

template <- st_read(here("Data/SMAP/SE_US_SMAP_Template.shp"))


# List hdf5 files from SMAP
h5Files <- data.frame("fullPath" = list.files(path = here("Data/SMAP/SPL4SMAU"), pattern = ".h5$", recursive = TRUE, full.names = TRUE),
                      "shortPath" = list.files(path = here("Data/SMAP/SPL4SMAU"), pattern = ".h5$", recursive = TRUE, full.names = FALSE))%>%
  mutate("Date" = lubridate::ymd_hms(substr(shortPath,16,30)))

# Check for missing files
misiing <- h5Files%>%
  filter(Date > lubridate::ymd("2016-08-08") & Date < lubridate::ymd("2017-06-05"))


# Create a filter or leave commented out to include all hdf5 files
#h5Files <- h5Files%>%
#  filter(Date < lubridate::ymd_hms("2016-01-01 00:00:00"))

# create a list of centroids for use with data reorganization
## filter to the template
h5 <- H5Fopen(as.character(h5Files$fullPath[1])) # Open the first h5 file
centroids <- data.frame("x" = as.vector(h5$cell_lon), "y" = as.vector(h5$cell_lat))%>%  # Extract the centroids and stack them vertically
  mutate("Cell_ID" = paste0("x",x,"y",y)) # Create a unique cell ID from the centroid coordinates
  
  
  
outDf <- centroids


# Loop through storms that made landfall and extract SMAP data 
# from their start date, through two weeks after the last storm observation
storms <- read.csv(here("Data/NOAA/stormStats.csv"))%>%
  filter(landfall == "YES")%>%
  mutate(start = lubridate::ymd_hms(start),
         end = lubridate::ymd_hms(end))

for(n in 1:nrow(storms)){
  start <- storms$start[n]
  end <- storms$end[n]
  files <- h5Files%>%
    filter(Date >= start & Date <= end+1209600)
  
  outDf <- centroids
  # Loop through all of the files to export to singular flat file
  for(i in 1:nrow(files)){
    # Open the sub dataset (In our case root zone soil moisture)
    h5sm <- h5read(as.character(files$fullPath[i]),"/Analysis_Data/sm_rootzone_analysis")
    
    # Vectorize in order to join it with coordinates
    vect <- data.frame("RZ_SM" = as.vector(h5sm))%>%
      mutate(RZ_SM = ifelse(RZ_SM == -9999, NA, RZ_SM))
    
    colnames(vect) <- c(paste0("RZ_SM_",h5Files$Date[i]))
    
    outDf <- cbind(outDf, vect)
    
    h5closeAll()
    
    
    print(paste0("Finished: ", i))
    
  }
  outDfFilt <- outDf %>%
    filter(Cell_ID %in% template$Cell_ID)
  
  write.csv(outDfFilt, paste0(here("Data/extractions/"),storms$ID[n],"_SMAP_SM.csv"))
    
  print(paste0("Completed ",storms$Name[n]," at: ",Sys.time()))
}


# You can list all of the contents here:
#h5ls(h5Files[1])