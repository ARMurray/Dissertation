library(tidyverse)
library(tidyr)
library(here)

files <- data.frame(fullPath = list.files(here("Data/extractions/"), full.names = TRUE, pattern = ".csv"),
                    names = tolower(substr(list.files(here("Data/extractions/"), full.names = FALSE, pattern = ".csv"),1,8)))%>%
  filter(!names == "al112016")

# Import storm info
stormInfo <- read.csv(here("Data/NOAA/stormStats.csv"))%>%
  mutate(ID = tolower(ID))%>%
  filter(landfall == "YES")%>%
  filter(!ID == "al112016")

# For loop to calculate all SMAP stats by cell for each storm

for(n in 1:nrow(files)){
  csv <- read.csv(files$fullPath[n])%>%
    select(!c(X,x,y))%>%
    pivot_longer(!Cell_ID, names_to = "dateTime",values_to = "SM")%>%
    mutate(timeFix = ifelse(nchar(dateTime) == 16, paste0(dateTime,".00.00.00"),dateTime))%>% # Midnight timestamps dropped HMS so needd to fix here
    mutate(dateTime = lubridate::ymd_hms(paste0(substr(timeFix,7,10),"/",substr(timeFix,12,13),"/",substr(timeFix,15,16)," ",substr(timeFix,18,19),"-",substr(timeFix,21,22),"-",substr(timeFix,24,25))),
         storm = files$names[n])%>%
    select(!timeFix) # Drop the timeFix field
  
  # Find Peak Soil Moisture
  peak <- csv%>%
    group_by(Cell_ID)%>%
    mutate(Peak_SM = max(SM))%>%
    ungroup()%>%
    filter(Peak_SM == SM)%>%
    select(Cell_ID, dateTime, Peak_SM)%>%
    distinct()
  
  colnames(peak) <- c("Cell_ID","Peak_Time","Peak_SM")
  
  # Get landfall dateTime
  lfall <- stormInfo%>%
    filter(ID %in% files$names[n])%>%
    select(lFall_dateTime)%>%
    as.character

  # Find pre-landfall soil moisture by extracting SM 12 hours before landfall, except for IMELDA, we use 6 hours because it ddeveloped so quickly
  preLFALL <- csv%>%
    filter(ifelse(storm == "al112019", dateTime == lubridate::round_date(lubridate::ymd_hms(lfall),"3 hours")-lubridate::hm("06:00"),
           dateTime == lubridate::round_date(lubridate::ymd_hms(lfall),"3 hours")-lubridate::hm("12:00")))%>%
    select(Cell_ID,dateTime,SM)
  
  colnames(preLFALL) <- c("Cell_ID","ant_SM_time","ant_SM")
  
  # Find Minimum post-maximum soil moisture
  postLFALL <- csv%>%
    left_join(peak)%>%
    filter(dateTime > Peak_Time)%>%
    group_by(Cell_ID)%>%
    mutate(min_SM = min(SM))%>%
    ungroup()%>%
    filter(min_SM == SM)%>%
    select(Cell_ID, dateTime, min_SM)%>%
    distinct()
  
  colnames(postLFALL) <- c("Cell_ID","minSM_Time","min_SM")
  
  # find time to return to pre-landfall Soil moisture
  return <- csv%>%
    left_join(peak)%>%
    filter(dateTime > Peak_Time)%>%
    left_join(preLFALL)%>%
    filter(SM <= ant_SM)%>%
    group_by(Cell_ID)%>%
    mutate("First_Return" = min(dateTime))%>%
    select(Cell_ID,Peak_Time, First_Return)%>%
    distinct()%>%
    mutate("Time_to_Return" = as.numeric(difftime(First_Return,Peak_Time), units="hours"))%>%
    select(!Peak_Time)
  
  colnames(return) <- c("Cell_ID","Rtrn_Time","Rtrn_Lngth")
  
  # Join all stats together and save
  SMAPstats <- preLFALL%>% # Start with baseline (antecedent SM)
    left_join(peak)%>% # add peak soil moisture
    left_join(postLFALL)%>% # Add post-max minimum soil moisture
    left_join(return)%>%
    mutate(storm = files$names[n])
  
  write.csv(SMAPstats, paste0(here("Data/SMAP/SMAP_Stats"),"/SMAP_Stats_",files$names[n],".csv"))
  
  print(paste0("Finished ", files$names[n], "at: ",Sys.time()))
}

