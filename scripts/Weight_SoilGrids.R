library(tidyverse)
library(raster)
library(here)


# List variables and depths
vars <- c("bdod","cec","cfvo","clay","nitrogen","phh2o","sand","silt","soc","ocd","ocs")
depths <- c("0-5cm","5-15cm","15-30cm","30-60cm","60-100cm","100-200cm")

# Create data frame with values, depts and layer names
voiDF <- expand.grid(vars,depths)%>%
  mutate(voi = paste0(Var1,"_",Var2,"_","Q0.5"))
colnames(voiDF) <- c("VOI","Depth", "VOI_Layer")

# Get File paths of reach raster which was downloaded using 'SoilGrids_Extractor.R'
names <- as.data.frame(str_sub(list.files(here("Data/SoilGrids/SEUS/tif"), pattern = ".tif$", full.names = FALSE),end=-5))
files <- as.data.frame(list.files(here("Data/SoilGrids/SEUS/tif"), pattern = ".tif$", full.names = TRUE))%>%
  cbind(names)
colnames(files) <- c("Path","VOI_Layer")

voiInfo <- voiDF%>%
  left_join(files)%>% # Add Filenames
  filter(!is.na(Path))%>% # Remove missing paths (Should just be carbon stocks since they are not yet avail)
  separate(Depth,sep = "-",into = c("Top","Bottom"))%>%   # Create columns for top and bottom of horizon
  mutate(Bottom = str_sub(Bottom, end=-3), # remove 'cm' so we can convert to numeric
         Thickness = as.numeric(Bottom) - as.numeric(Top), # Calculate thickness
         Weight = Thickness / 200)   # Calculate the wight based on thickness divided by total (200 cm)

# Run a for loop to iterate through VOIs and export a weighted raster for each tif
for(var in unique(voiInfo$VOI)){
  varsub <- voiInfo%>%
    filter(VOI == var)
  print(paste0("Starting ",var, " at: ", Sys.time()))
  for(n in 1:nrow(varsub)){
    rast <-  raster(varsub$Path[n])*varsub$Weight[n]
    writeRaster(rast, paste0(here("Data/SoilGrids/SEUS/tif_weighted"),"/",varsub$VOI_Layer[n],"_weighted.tif"))
  }
  print(paste0("Completed ",var, " at: ",Sys.time()))
}

# Add weighted rasters together by value to create a single raster for 0-200 cm for each value
for(var in unique(voiInfo$VOI)){
  print(paste0("Starting ",var, " at: ", Sys.time()))
  rastlist <- list.files(path = here("Data/SoilGrids/SEUS/tif_weighted"), pattern=var, all.files=TRUE, full.names=TRUE)
  allrasters <- stack(rastlist) #Import the rasters of that value
  rastSum <- sum(allrasters) # Add weighted rasters together to create single raster
  writeRaster(rastSum, paste0(here("Data/SoilGrids/SEUS/tif_weighted_sum"),"/",var,"_weighted_0-200cm.tif"))
  print(paste0("Completed ",var, " at: ",Sys.time()))
}
