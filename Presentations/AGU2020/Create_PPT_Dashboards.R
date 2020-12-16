library(sf)
library(tidyverse)
library(tidyr)
library(here)

# Load Storm Names and info
NOAA <- read.csv(here("Data/NOAA/stormStats.csv"))%>%
  mutate(ID = tolower(ID))

# Load PPT calcs by storm
sf <- st_read(here("Data/prism/pptByStorm.shp"))%>%
  st_transform(4326)

colnames(sf) <- tolower(colnames(sf))

long <- sf%>%
  pivot_longer(cols = starts_with("al"), names_to = "Storm", values_to = "ppt_mm")%>%
  left_join(NOAA, by = c("Storm" = "ID"))%>%
  mutate(Name = ifelse(Storm == "allstorms","All Storms",Name),
         nameYear = paste0(Name," (",substr(lFall_dateTime,1,4),")"),
         Storm = ifelse(Storm == "allstorms","allstorm",Storm),
         Class = ifelse(ppt_mm <100,"< 100",
                        ifelse(ppt_mm < 250, "100 - 250",
                               ifelse(ppt_mm < 500, "250 - 500",
                                      ifelse(ppt_mm < 750, "500 - 750",
                                             ifelse(ppt_mm < 1000, "750 - 1000",
                                                    ifelse(ppt_mm > 1000,"> 1,000", NA)))))))%>%
  filter(!is.na(ppt_mm))%>%
  st_as_sf()


# Don't run 'allstorms' and round data to make smaller
long <- long%>%
  filter(!Storm == "allstorm")%>%
  select(!X)%>%
  mutate(ppt_mm = as.integer(ppt_mm))

pal <- c("#4FC3F8","#19A6D4","#1B5CB0","#8E4DC8","#FF25F5")

# Creat NLCD pallette:
nlcdCols <- data.frame(Class = c("Open Water","Developed, Open Space","Developed, Low Intensity","Developed, Medium Intensity",
                                 "Developed High Intensity","Deciduous Forest","Evergreen Forest", "Mixed Forest","Shrub/Scrub",
                                 "Grassland/Herbaceous","Pasture/Hay","Cultivated Crops", "Woody Wetlands","Emergent Herbaceous Wetlands"),
                       Color = c("#486DA2","#E1CDCE","#DC9881","#F10100","#AB0101","#6CA966","#1D6533","#BDCC93","#D1BB82",
                                 "#EDECCD","#DDD83E","#AE7229","#BAD7ED","#71A4C1"))


library("rmarkdown")

# Filter so I can run those not completed yet
stormsList <- data.frame(storm = unique(long$Storm))
#sub <- stormsList[15:nrow(stormsList),]


# For Harvey we need to reduce the file size so we'll fikter to >100mm

# in a single for loop
#  1. define subgroup
#  2. render output
for (storm in stormsList){
  subgroup <- long%>%
    filter(Storm == storm)
  render(here("Presentations/AGU2020/Cyclone_PPT_Template.Rmd"),output_file = here("Presentations/AGU2020/dashboards",paste0(subgroup$Name[1],"_Dashboard",'.html')))    
  
  print(paste0("Finshed: ", storm))  
}
