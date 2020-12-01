library(FedData)
library(tidyverse)
library(raster)
library(sf)
library(here)

# Load the SMAP template

template <- st_read(here("Data/SMAP/SE_US_SMAP_Template.shp"))%>%
  st_transform("+proj=aea +lat_0=23 +lon_0=-96 +lat_1=29.5 +lat_2=45.5 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs")%>%
  as_Spatial()

nlcd <- raster(here("Data/nlcd/NLCD_2016_se.tif"))


ex <- extract(nlcd,template)



# Import zonal stats (run in ArcGIS to save time)

zonal <- read.csv(here("Data/nlcd/nlcd_2016_se_zonal.csv"))

try <- freq(nlcd)



# Create a function to find the Mode
Mode <- function(x) {
  ux <- unique(x)
  ux=ux[!is.na(ux)]
  ux[which.max(tabulate(match(x, ux)))]
}

# For loop to go cell by cell and calculate NLCD Statistics
df <- data.frame()
for(n in 1:nrow(template)){
  start <- Sys.time()
  row <- template[n,] # Iterate to the current SMAP cell
 
  ID <- row$Cell_ID
 
  crop <- as.data.frame(crop(nlcd,row))%>% # crop the NLCD to the current cell
    filter(!NLCD_2016_se == 128) # Remove NODATA values
 
  mode <- as.numeric(Mode(crop[,1])) # Get the nlcd value that occurs most within that cell
 
  count <- crop%>% # Number of cells that the most common land cover occupies
    filter(NLCD_2016_se == mode)%>%
    nrow()
 
  pctMode <- round((count / nrow(crop))*100,1) # Percent of the cell that the most common landcover occupies
 
  outData <- data.frame(Cell_ID = ID, Dom_LC = mode, modeCells = count, pctMode = pctMode)
 
   df <- rbind(df,outData)
   
   end <- Sys.time()
 
 print(paste0("Iteration ",n," took: ", round(end - start,1)," seconds"))
}

write.csv(df, here("Data/nlcd/nlcd_2016_se_zonal_stats.csv"))


# Map it

map <- st_read(here("Data/SMAP/SE_US_SMAP_Template.shp"))%>%
  left_join(df)

ggplot(map)+
  geom_sf(aes(color = Dom_LC, fill = Dom_LC))
