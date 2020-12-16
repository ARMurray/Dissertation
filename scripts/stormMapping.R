library(tidyverse)
library(sf)
library(lubridate)
library(plotly)
library(here)

# List all of the storm SMAP extraction files
storms <- list.files(here("Data/extractions/"), full.names = TRUE)

# Import one storm
storm <- read.csv(storms[1])

# Import the spatial template and join the storm data to it
stormSF <- st_read(here("Data/SMAP/SE_US_SMAP_Template.shp"))%>%
  left_join(storm)

ggplot(stormSF)+
  geom_sf(aes(fill = RZ_SM_2015.04.19.03.00.00, color = RZ_SM_2015.04.19.03.00.00), lwd = 0)



# Pivot to long
stormLong <- storm%>%
  select(!c(X,x,y))%>%
  pivot_longer(!Cell_ID, names_to = "timestamp",values_to = "SM")%>%
  left_join(template)%>%
  mutate(dateTime = ymd_hms(paste0(substr(timestamp,7,10),"/",substr(timestamp,12,13),"/",substr(timestamp,15,16),
                                   " ",substr(timestamp,18,19),":",substr(timestamp,21,22),":",substr(timestamp,24,25))))%>%
  st_as_sf()


map <- stormLong%>%
  st_transform(4326)
ggplot(map)+
  geom_sf(aes(fill = RZ_SM_2015.04.19.03.00.00, color = RZ_SM_2015.04.19.03.00.00), lwd = 0)+
  transition_states(dateTime,
                    transition_length = 2,
                    state_length = 1)

wideWGS <- stormSF%>%
  select(!c(X,x,y))%>%
  st_transform(4326)

plot_geo(wideWGS)%>%
  add_sf(fillcolor = ~RZ_SM_2015.04.20.03.00.00)
