library(terra)
library(readxl)
library(dplyr)
library(prioritizr)
source("R/fct_matrix_to_raster.R")
source("R/fct_calc_coverage_from_meta.R")

# NCC 1km PU
NCC_1KM_PU <- rast("Data/Input/NCC/NCC_1KM_PU.tif")

# ECCC SAR
## goal
META <- read_excel("Data/Output/metadata/WTW_NAT_SPECIES_METADATA.xlsx", sheet = 2)
RIJ <- readRDS("Data/Output/RIJ/RIJ_ECCC_SAR.rds")
meta_contr <- calc_coverage_from_meta(META, units = "ha")
contr <- RIJ * meta_contr$Pixel_Contr 
contr_sum <- Matrix::colSums(contr)
contr_mean <- Matrix::colMeans(contr)
contr_sum_r <- matrix_to_raster(NCC_1KM_PU, contr_sum)
contr_mean_r <- matrix_to_raster(NCC_1KM_PU, contr_mean)
writeRaster(contr_sum_r, "Data/Output/Goals/ECCC_SAR_PCT_CONTR_TO_GOAL_SUM.tif", overwrite = TRUE)
writeRaster(contr_mean_r, "Data/Output/Goals/ECCC_SAR_PCT_CONTR_TO_GOAL_MEAN.tif", overwrite = TRUE)
## richness
richness_ha <- Matrix::colSums(RIJ)
richness_ha_r <- matrix_to_raster(NCC_1KM_PU, richness_ha)
RIJ_N <- RIJ
RIJ_N@x[RIJ_N@x > 1] <- 1 # replace values > 1 with 1 (to get species count)
richness <- Matrix::colSums(RIJ_N)
richness_r <- matrix_to_raster(NCC_1KM_PU, richness)
writeRaster(richness_ha_r, "Data/Output/Richness/ECCC_SAR_SUM_HA.tif", overwrite = TRUE)
writeRaster(richness_r, "Data/Output/Richness/ECCC_SAR_SUM_N.tif", overwrite = TRUE)
rm(RIJ_N) 
gc()

# IUCN AMPH
## goal
META <- read_excel("Data/Output/metadata/WTW_NAT_SPECIES_METADATA.xlsx", sheet = 3)
RIJ <- readRDS("Data/Output/RIJ/RIJ_IUCN_AMPH.rds")
meta_contr <- calc_coverage_from_meta(META, units = "km")
contr <- RIJ * meta_contr$Pixel_Contr 
contr_sum <- Matrix::colSums(contr)
contr_mean <- Matrix::colMeans(contr)
contr_sum_r <- matrix_to_raster(NCC_1KM_PU, contr_sum)
contr_mean_r <- matrix_to_raster(NCC_1KM_PU, contr_mean)
writeRaster(contr_sum_r, "Data/Output/Goals/IUCN_AMPH_PCT_CONTR_TO_GOAL_SUM.tif", overwrite = TRUE)
writeRaster(contr_mean_r, "Data/Output/Goals/IUCN_AMPH_PCT_CONTR_TO_GOAL_MEAN.tif", overwrite = TRUE)
## richness
richness <- Matrix::colSums(RIJ)
richness_r <- matrix_to_raster(NCC_1KM_PU, richness)
writeRaster(richness_r, "Data/Output/Richness/IUCN_AMPH_SUM_N.tif", overwrite = TRUE)

# IUCN BIRD
## goal
META <- read_excel("Data/Output/metadata/WTW_NAT_SPECIES_METADATA.xlsx", sheet = 4)
RIJ <- readRDS("Data/Output/RIJ/RIJ_IUCN_BIRD.rds")
meta_contr <- calc_coverage_from_meta(META, units = "km")
contr <- RIJ * meta_contr$Pixel_Contr 
contr_sum <- Matrix::colSums(contr)
contr_mean <- Matrix::colMeans(contr)
contr_sum_r <- matrix_to_raster(NCC_1KM_PU, contr_sum)
contr_mean_r <- matrix_to_raster(NCC_1KM_PU, contr_mean)
writeRaster(contr_sum_r, "Data/Output/Goals/IUCN_BIRD_PCT_CONTR_TO_GOAL_SUM.tif", overwrite = TRUE)
writeRaster(contr_mean_r, "Data/Output/Goals/IUCN_BIRD_PCT_CONTR_TO_GOAL_MEAN.tif", overwrite = TRUE)
## richness
richness <- Matrix::colSums(RIJ)
richness_r <- matrix_to_raster(NCC_1KM_PU, richness)
writeRaster(richness_r, "Data/Output/Richness/IUCN_BIRD_SUM_N.tif", overwrite = TRUE)

# IUCN MAMM
## goal
META <- read_excel("Data/Output/metadata/WTW_NAT_SPECIES_METADATA.xlsx", sheet = 5)
RIJ <- readRDS("Data/Output/RIJ/RIJ_IUCN_MAMM.rds")
meta_contr <- calc_coverage_from_meta(META, units = "km")
contr <- RIJ * meta_contr$Pixel_Contr 
contr_sum <- Matrix::colSums(contr)
contr_mean <- Matrix::colMeans(contr)
contr_sum_r <- matrix_to_raster(NCC_1KM_PU, contr_sum)
contr_mean_r <- matrix_to_raster(NCC_1KM_PU, contr_mean)
writeRaster(contr_sum_r, "Data/Output/Goals/IUCN_MAMM_PCT_CONTR_TO_GOAL_SUM.tif", overwrite = TRUE)
writeRaster(contr_mean_r, "Data/Output/Goals/IUCN_MAMM_PCT_CONTR_TO_GOAL_MEAN.tif", overwrite = TRUE)
## richness
richness <- Matrix::colSums(RIJ)
richness_r <- matrix_to_raster(NCC_1KM_PU, richness)
writeRaster(richness_r, "Data/Output/Richness/IUCN_MAMM_SUM_N.tif", overwrite = TRUE)

# IUCN REPT
## goal
META <- read_excel("Data/Output/metadata/WTW_NAT_SPECIES_METADATA.xlsx", sheet = 6)
RIJ <- readRDS("Data/Output/RIJ/RIJ_IUCN_REPT.rds")
meta_contr <- calc_coverage_from_meta(META, units = "km")
contr <- RIJ * meta_contr$Pixel_Contr 
contr_sum <- Matrix::colSums(contr)
contr_mean <- Matrix::colMeans(contr)
contr_sum_r <- matrix_to_raster(NCC_1KM_PU, contr_sum)
contr_mean_r <- matrix_to_raster(NCC_1KM_PU, contr_mean)
writeRaster(contr_sum_r, "Data/Output/Goals/IUCN_REPT_PCT_CONTR_TO_GOAL_SUM.tif", overwrite = TRUE)
writeRaster(contr_mean_r, "Data/Output/Goals/IUCN_REPT_PCT_CONTR_TO_GOAL_MEAN.tif", overwrite = TRUE)
## richness
richness <- Matrix::colSums(RIJ)
richness_r <- matrix_to_raster(NCC_1KM_PU, richness)
writeRaster(richness_r, "Data/Output/Richness/IUCN_REPT_SUM_N.tif", overwrite = TRUE)

# NSC END
## goal
META <- read_excel("Data/Output/metadata/WTW_NAT_SPECIES_METADATA.xlsx", sheet = 7)
RIJ <- readRDS("Data/Output/RIJ/RIJ_NSC_END.rds")
meta_contr <- calc_coverage_from_meta(META, units = "km")
contr <- RIJ * meta_contr$Pixel_Contr 
contr_sum <- Matrix::colSums(contr)
contr_mean <- Matrix::colMeans(contr)
contr_sum_r <- matrix_to_raster(NCC_1KM_PU, contr_sum)
contr_mean_r <- matrix_to_raster(NCC_1KM_PU, contr_mean)
writeRaster(contr_sum_r, "Data/Output/Goals/NSC_END_PCT_CONTR_TO_GOAL_SUM.tif", overwrite = TRUE)
writeRaster(contr_mean_r, "Data/Output/Goals/NSC_END_PCT_CONTR_TO_GOAL_MEAN.tif", overwrite = TRUE)
## richness
richness <- Matrix::colSums(RIJ)
richness_r <- matrix_to_raster(NCC_1KM_PU, richness)
writeRaster(richness_r, "Data/Output/Richness/NSC_END_SUM_N.tif", overwrite = TRUE)

# NSC SAR
## goal
META <- read_excel("Data/Output/metadata/WTW_NAT_SPECIES_METADATA.xlsx", sheet = 8)
RIJ <- readRDS("Data/Output/RIJ/RIJ_NSC_SAR.rds")
meta_contr <- calc_coverage_from_meta(META, units = "km")
contr <- RIJ * meta_contr$Pixel_Contr 
contr_sum <- Matrix::colSums(contr)
contr_mean <- Matrix::colMeans(contr)
contr_sum_r <- matrix_to_raster(NCC_1KM_PU, contr_sum)
contr_mean_r <- matrix_to_raster(NCC_1KM_PU, contr_mean)
writeRaster(contr_sum_r, "Data/Output/Goals/NSC_SAR_PCT_CONTR_TO_GOAL_SUM.tif", overwrite = TRUE)
writeRaster(contr_mean_r, "Data/Output/Goals/NSC_SAR_PCT_CONTR_TO_GOAL_MEAN.tif", overwrite = TRUE)
## richness
richness <- Matrix::colSums(RIJ)
richness_r <- matrix_to_raster(NCC_1KM_PU, richness)
writeRaster(richness_r, "Data/Output/Richness/NSC_SAR_SUM_N.tif", overwrite = TRUE)

# NSC SPP
## goal
META <- read_excel("Data/Output/metadata/WTW_NAT_SPECIES_METADATA.xlsx", sheet = 9)
RIJ <- readRDS("Data/Output/RIJ/RIJ_NSC_SPP.rds")
meta_contr <- calc_coverage_from_meta(META, units = "km")
contr <- RIJ * meta_contr$Pixel_Contr 
contr_sum <- Matrix::colSums(contr)
contr_mean <- Matrix::colMeans(contr)
contr_sum_r <- matrix_to_raster(NCC_1KM_PU, contr_sum)
contr_mean_r <- matrix_to_raster(NCC_1KM_PU, contr_mean)
writeRaster(contr_sum_r, "Data/Output/Goals/NSC_SPP_PCT_CONTR_TO_GOAL_SUM.tif", overwrite = TRUE)
writeRaster(contr_mean_r, "Data/Output/Goals/NSC_SPP_PCT_CONTR_TO_GOAL_MEAN.tif", overwrite = TRUE)
## richness
richness <- Matrix::colSums(RIJ)
richness_r <- matrix_to_raster(NCC_1KM_PU, richness)
writeRaster(richness_r, "Data/Output/Richness/NSC_SPP_SUM_N.tif", overwrite = TRUE)
