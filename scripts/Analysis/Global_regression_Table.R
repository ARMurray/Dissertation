library(DT)

# Data tables

global <- read.csv(here("Data/Analysis/Regressions_Global.csv"))%>%
  select(!X)%>%
  mutate(Ind_Var = recode(Ind_Var, ant_SM = "Antecedent SM",
                          Mean_Slope = "Mean Slope",
                          ppt_mm = "PPT",
                          yDay = "Day of Year"),
         T_Stat = round(T_Stat,3),
         p_val = round(p_val,6),
         R2 = round(R2,3))

datatable(global,rownames = FALSE,
          colnames = c('Independent Variable', 'NLCD Class', 'T Statistic', 'P - Value', 'R^2',"N"))%>%
  formatStyle("R2", backgroundColor = styleInterval(c(.1,.2,.3,.4,.5,.6), c("#d73027","#fc8d59","#fee08b","#ffffbf","#d9ef8b","#91cf60","#1a9850")))%>%
  formatStyle("p_val",backgroundColor = styleInterval(c(.0005,.005,.05),c("#1a9850","#91cf60","#d9ef8b","#d73027")))%>%
  formatStyle(
    'NLCD_Class', backgroundColor = styleEqual(c("Cultivated Crops","Deciduous Forest","Developed High Intensity",
                                                 "Developed, Low Intensity","Developed, Medium Intensity",
                                                 "Developed, Open Space","Emergent Herbaceous Wetlands",
                                                 "Evergreen Forest","Grassland/Herbaceous","Mixed Forest",
                                                 "Pasture/Hay","Shrub/Scrub","Woody Wetlands"),
                                               c("#AE7229", "#6CA966","#AB0101",
                                                 "#DC9881","#F10100",
                                                 "#E1CDCE","#71A4C1",
                                                 "#1D6533","#EDECCD","#BDCC93",
                                                 "#DDD83E","#D1BB82","#BAD7ED"
                                                 ))
  )


# Make a table for storm by storm

bystorm <- read.csv(here("Data/Analysis/regressionsByStorm.csv"))%>%
  select(!X)%>%
  mutate(Ind_Var = recode(Ind_Var, ant_SM = "Antecedent SM",
                          Mean_Slope = "Mean Slope",
                          ppt_mm = "PPT",
                          yDay = "Day of Year"),
         T_Stat = round(T_Stat,3),
         p_val = round(p_val,6),
         R2 = round(R2,3))

datatable(bystorm,rownames = FALSE,
          colnames = c('Independent Variable', 'NLCD Class', 'T Statistic', 'P - Value', 'R^2',"N"))%>%
  formatStyle("R2", backgroundColor = styleInterval(c(.1,.2,.3,.4,.5,.6), c("#d73027","#fc8d59","#fee08b","#ffffbf","#d9ef8b","#91cf60","#1a9850")))%>%
  formatStyle("p_val",backgroundColor = styleInterval(c(.0005,.005,.05),c("#1a9850","#91cf60","#d9ef8b","#d73027")))%>%
  formatStyle(
    'NLCD_Class', backgroundColor = styleEqual(c("Cultivated Crops","Deciduous Forest","Developed High Intensity",
                                                 "Developed, Low Intensity","Developed, Medium Intensity",
                                                 "Developed, Open Space","Emergent Herbaceous Wetlands",
                                                 "Evergreen Forest","Grassland/Herbaceous","Mixed Forest",
                                                 "Pasture/Hay","Shrub/Scrub","Woody Wetlands"),
                                               c("#AE7229", "#6CA966","#AB0101",
                                                 "#DC9881","#F10100",
                                                 "#E1CDCE","#71A4C1",
                                                 "#1D6533","#EDECCD","#BDCC93",
                                                 "#DDD83E","#D1BB82","#BAD7ED"
                                               ))
  )
