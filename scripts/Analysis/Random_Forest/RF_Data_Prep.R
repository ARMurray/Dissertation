library(tidyverse)
library(sf)
library(raster)
library(randomForest)
library(caTools)
library(data.table)

data <- read.csv(here::here("Data/Analysis/AllStorms_Combo.csv"))%>%
  drop_na()%>%
  dplyr::select(Rtrn_Lngth, Dom_LC,ppt_mm,ant_SM,Peak_SM)

## Add Soil Grids Info

actual <- df.param$ParameterValue

statsOut <- data.frame()

for (n in 1:100) {
  print("#########################")
  ID <- paste0("I",str_pad(n,4,pad = "0"))
  print(paste0("Starting Iteration: ", ID))
  start <- Sys.time()
  
  #nparams <- round(runif(1,min = 3, max = 20))
  
  #seq <- round(runif(nparams, min=2, max=27))%>% #Randomly select 10 input parameters
  #  unique()
  
  #df.select <- df.param%>%     # Use the random numbers to select the columns 
  #  select(ParameterValue,seq) # Commented out to randomize mtry instead of inputs
  
  # Separate Training and Testing Sets
  sample = sample.split(df.param$ParameterValue, SplitRatio = .75)
  train = subset(df.param, sample == TRUE)
  test  = subset(df.param, sample == FALSE)
  dim(train)
  dim(test)
  
  # Create Random Forest
  rf <- randomForest(
    ParameterValue ~ .,
    data=train,
    ntree=1000,
    mtry = round(runif(1,5,26))
  )
  
  # Calculate the r2 value
  predicted <- unname(predict(rf,df.param))
  
  R2 <- round(1 - (sum((actual-predicted)^2)/sum((actual-mean(actual))^2)),3)
  
  # Calculate RMSE
  RMSE <- round(caret::RMSE(predicted,actual),3)
  
  # List the Parameters Used
  vars <- colnames(df.param)[2:length(colnames(df.param))]
  
  print("Predictors Included: ")
  print(vars)
  print("Model Results:")
  print(rf)
  print(paste0("R2: ",R2))
  print(paste0("RMSE: ", RMSE))
  
  newrow <- data.frame("ID" = ID, "nTrees" = rf$call$ntree, "mtry" = rf$mtry, "R2" = R2, "RMSE" = RMSE,"nParams" = length(colnames(df.param))-1 ,"Parameters" = paste(vars, collapse="/"))
  statsOut <- rbind(statsOut,newrow)
  
  # Save importance values
  importance <- setDT(as.data.frame(rf$importance),keep.rownames = TRUE)
  colnames(importance) <- c("Parameter","NodePurity")
  write.csv(importance, paste0(here("projects/Texas_Pilot/Random_Forest_Models/Nitrate/Importance"),"/month_",ID,".csv"))
  
  # Save Predicted Values
  write.csv(predicted, paste0(here("projects/Texas_Pilot/Random_Forest_Models/Nitrate/Predicted"),"/month_",ID,".csv"))
  
  write.csv(statsOut, paste0(here("projects/Texas_Pilot/Random_Forest_Models/Nitrate"),"/","Month_Output_Summary_",Sys.Date(),".csv"))
  
  end <- Sys.time()
  
  print(paste0("Completed Iteration: ",ID," in ",round(round(as.numeric(lubridate::seconds(end)-lubridate::seconds(start)))/60,2)," minutes"))
  
  
}

