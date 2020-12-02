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
         nameYear = paste0(Name," (",substr(lFall_dateTime,1,4),")"))%>%
  filter(!is.na(ppt_mm))%>%
  st_as_sf()


library("rmarkdown")

# in a single for loop
#  1. define subgroup
#  2. render output
for (storm in unique(long$Storm)){
  subgroup <- long%>%
    filter(Storm == storm)
  render(here("Presentations/AGU_2020/Cyclone_PPT_Template.Rmd"),output_file = here("Presentations/AGU_2020/dashboards",paste0(subgroup$Name,"_PPT",'.html')))    

  print(paste0("Finshed: ", id))  
}
