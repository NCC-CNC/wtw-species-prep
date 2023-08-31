library(terra)
library(readxl)
library(dplyr)
library(prioritizr)
source("R/fct_matrix_to_raster.R")
source("R/fct_calc_coverage_from_meta.R")

# NCC 1km PU
NCC_1KM_PU <- rast("Data/Input/NCC/NCC_1KM_PU.tif")

# ECCC SAR
META <- read_excel("Data/Output/metadata/WTW_NAT_SPECIES_METADATA.xlsx", sheet = 2)
RIJ <- readRDS("Data/Output/RIJ/RIJ_ECCC_SAR.rds")
meta_contr <- calc_coverage_from_meta(META, units = "ha")
contr <- RIJ * meta_contr$Pixel_Contr 
contr_sum <- Matrix::colSums(contr)
contr_mean <- Matrix::colMeans(contr)
contr_sum_r <- matrix_to_raster(NCC_1KM_PU, contr_sum)
contr_mean_r <- matrix_to_raster(NCC_1KM_PU, contr_mean)
writeRaster(contr_sum_r, "Data/Output/Richness/ECCC_SAR_PCT_CONTR_TO_GOAL_SUM.tif", overwrite = TRUE)
writeRaster(contr_mean_r, "Data/Output/Richness/ECCC_SAR_PCT_CONTR_TO_GOAL_MEAN.tif", overwrite = TRUE)

# NSC END
META <- read_excel("Data/Output/metadata/WTW_NAT_SPECIES_METADATA.xlsx", sheet = 7)
RIJ <- readRDS("Data/Output/RIJ/RIJ_NSC_END.rds")
meta_contr <- calc_coverage_from_meta(META, units = "km")
contr <- RIJ * meta_contr$Pixel_Contr 
contr_sum <- Matrix::colSums(contr)
contr_mean <- Matrix::colMeans(contr)
contr_sum_r <- matrix_to_raster(NCC_1KM_PU, contr_sum)
contr_mean_r <- matrix_to_raster(NCC_1KM_PU, contr_mean)
writeRaster(contr_sum_r, "Data/Output/Richness/NSC_END_PCT_CONTR_TO_GOAL_SUM.tif", overwrite = TRUE)
writeRaster(contr_mean_r, "Data/Output/Richness/NSC_END_PCT_CONTR_TO_GOAL_MEAN.tif", overwrite = TRUE)
