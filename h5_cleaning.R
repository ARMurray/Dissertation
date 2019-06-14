library(rhdf5)
library(dplyr)

setwd("D:/OneDrive/OneDrive - University of North Carolina at Chapel Hill/Dissertation/SMAP_Downloads/135744443/")

h5ls("SMAP_L2_SM_SP_1AIWDV_20180815T113736_20180814T231324_078W32N_R16010_001.h5")

mydata <- h5read("SMAP_L2_SM_SP_1AIWDV_20180815T113736_20180814T231324_078W32N_R16010_001.h5","/Soil_Moisture_Retrieval_Data_3km/disagg_soil_moisture_apm_3km")

files <- as.data.frame(list.files(path = "D:/OneDrive/OneDrive - University of North Carolina at Chapel Hill/Dissertation/SMAP_Downloads/", pattern = ".h5$",recursive = TRUE))
colnames(files) <- "file"
files$Pix_Cent <- as.factor(substr(as.character(files$file),65,70))


files%>%
  group_by(Pix_Cent)%>%
  summarise(No_Images=length(Pix_Cent))%>%
  arrange(desc(No_Images))

# Try NCDF4 package? -> https://www.researchgate.net/post/Someone_has_experience_with_SMAP_images
library(ncdf4)

myFile <- nc_open('C:/Users/ARMur/OneDrive - University of North Carolina at Chapel Hill/Dissertation/SMAP_Downloads/135744443/SMAP_L2_SM_SP_1AIWDV_20180815T113736_20180814T231324_078W32N_R16010_001.h5')


# Try this -> https://www.neonscience.org/image-raster-data-r