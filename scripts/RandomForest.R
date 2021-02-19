library(tidyverse)
library(plotly)
library(here)
library(randomForest)
library(caTools)
library(data.table)

# Read in Data for all storms
df <- read.csv(here("Data/Analysis/AllStorms_Combo.csv"))

# Bring in LAI
storminfo <- read.csv(here("Data/NOAA/stormStats.csv"))%>%
  filter(landfall == "YES")%>%
  mutate(Name = tolower(Name))%>%
  dplyr::select(ID,Name)
## Create long dataset with Cell ID, storm name and LAI value to join
laifiles <- data.frame(Path = list.files(here("Data/LAI/Zonal"), full.names = TRUE),
                       Name = list.files(here("Data/LAI/Zonal"), full.names = FALSE))%>%
  separate(Name, into = c("Name","Stat","Var"), sep = "_")%>%
  left_join(storminfo)%>%
  mutate(ID = tolower(ID))



long <- data.frame()

for (n in 1:nrow(laifiles)) {
  csv <- read.csv(laifiles$Path[n])%>%
    mutate(storm = laifiles$ID[n])%>%
    dplyr::select(!X)
  colnames(csv) <- c("Cell_ID","LAI","storm")
  
  long <- rbind(long,csv)
  
}


# Bring in Slope
slope <- read.csv(here("Data/SEUS_Mean_Slope.csv"))%>%
  dplyr::select(CELL_ID, MEAN)


# Join dataset and remove rows with NA values
join <- df%>%
  left_join(long, by = c("Cell_ID","storm"))%>%
  left_join(slope, by = c("Cell_ID" = "CELL_ID"))

# Select Random Forest inputs
rfdf <- join%>%
  dplyr::select(Rtrn_Lngth,Class,modeCells,ppt_mm,ant_SM,Peak_SM,LAI,MEAN)%>%
  drop_na()
colnames(rfdf) <- c("Rtrn_Lngth","NLCD","NLCD_Purity","Ppt","Ant_SM","Peak_SM","LAI","Mean_Slope")

# Table of pixel occurences
tblsub <- join%>%
  dplyr::select(Cell_ID,Rtrn_Lngth,Class,modeCells,ppt_mm,ant_SM,Peak_SM,LAI,MEAN)%>%
  drop_na()%>%
  distinct()
tbl <- as.data.frame(table(tblsub$Cell_ID))
colnames(tbl) <- c("Cell_ID","Pixel_Count")
write.csv(tbl, here("Data/Pixel_Count.csv"))

# Histogram of return lengths
ggplot(rfdf)+
  geom_histogram(aes(x = Rtrn_Lngth))+
  labs(title = "Distribution of SM Return Time",x = "Soil Moisture Return Time [Hours]")


actual <- rfdf$Rtrn_Lngth

statsOut <- data.frame()

# Create variables for initial R2 and RMSE which will be iteratively updated
bestR2 <- 0
bestRMSE <- 1000

for (n in 1:100) {
  print("#########################")
  ID <- paste0("I",str_pad(n,4,pad = "0"))
  print(paste0("Starting Iteration: ", ID))
  start <- Sys.time()
  
  nparams <- round(runif(1,min = 3, max = 7))
  
  seq <- round(runif(nparams, min=2, max=8))%>% #Randomly select 10 input parameters
    unique()
  
  df.select <- rfdf%>%     # Use the random numbers to select the columns 
    dplyr::select(Rtrn_Lngth,seq) # Commented out to randomize mtry instead of inputs
  
  # Separate Training and Testing Sets
  sample = sample.split(rfdf$Rtrn_Lngth, SplitRatio = .75)
  train = subset(rfdf, sample == TRUE)
  test  = subset(rfdf, sample == FALSE)
  dim(train)
  dim(test)
  
  # Create Random Forest
  rf <- randomForest(
    Rtrn_Lngth ~ .,
    data=train,
    ntree=1000,
    mtry = round(runif(1,2,nparams))
  )
  
  # Calculate the r2 value
  predicted <- unname(predict(rf,rfdf))
  
  R2 <- round(1 - (sum((actual-predicted)^2)/sum((actual-mean(actual))^2)),3)
  
  # Calculate RMSE
  RMSE <- round(caret::RMSE(predicted,actual),3)
  
  # List the Parameters Used
  vars <- colnames(rfdf)[2:length(colnames(rfdf))]
  
  print("Predictors Included: ")
  print(vars)
  print("Model Results:")
  print(rf)
  print(paste0("R2: ",R2))
  print(paste0("RMSE: ", RMSE))
  
  newrow <- data.frame("ID" = ID, "nTrees" = rf$call$ntree, "mtry" = rf$mtry, "R2" = R2, "RMSE" = RMSE,"nParams" = length(colnames(rfdf))-1 ,"Parameters" = paste(vars, collapse="/"))
  statsOut <- rbind(statsOut,newrow)
  
  # Save importance values
  importance <- setDT(as.data.frame(rf$importance),keep.rownames = TRUE)
  colnames(importance) <- c("Parameter","NodePurity")
  write.csv(importance, paste0(here("scripts/Analysis/Random_Forest/RF_Outputs/Importance"),"/month_",ID,".csv"))
  
  # Save Predicted Values
  write.csv(predicted, paste0(here("scripts/Analysis/Random_Forest/RF_Outputs/Predicted"),"/month_",ID,".csv"))
  
  write.csv(statsOut, paste0(here("scripts/Analysis/Random_Forest/RF_Outputs/Rtrn_Lngth"),"/","Output_Summary_",Sys.Date(),".csv"))
  
  # If this model is the best one (Lowest RMSE and highest R2), then save it.
  if(R2 > bestR2 & RMSE < bestRMSE){
    save(rf,file = here("scripts/Analysis/Random_Forest/RF_Outputs/BestModel/Rtrn_Lngth_Best_RF.RData"))
    bestR2 <- R2
    bestRMSE <- RMSE
    print("****************************")
    print("* FOUND A BETTER MODEL!!!! *")
    print("****************************")
  }
  
  end <- Sys.time()
  
  print(paste0("Completed Iteration: ",ID," at ",Sys.time()," in ",round(round(as.numeric(lubridate::seconds(end)-lubridate::seconds(start)))/60,2)," minutes"))
  
  
}

# Save stats out
write.csv(statsOut, paste0(here("scripts/Analysis/Random_Forest/RF_Outputs/Rtrn_Lngth"),"/","Output_Summary_",Sys.Date(),".csv"))

