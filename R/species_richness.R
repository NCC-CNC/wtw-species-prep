#
# Authors: Dan Wismer
#
# Date: June 28th, 2023
#
# Description: Generates cumulative area raster and number of species raster 
#
# Inputs:  1. Paths to 1km .tifs
#          2. Output path for species richness rasters 
#
#
# Outputs: 1. Cumulative area raster
#         2. Count of species raster
#
#===============================================================================

library(terra)
library(pbapply)

## Start timer
start_time <- Sys.time()

# Get list of tifs
ECCC_CH_LST <- list.files("Data/Output/ECCC_CH", pattern='.tif$', full.names = TRUE)
ECCC_SAR_LST <- list.files("Data/Output/ECCC_SAR", pattern='.tif$', full.names = TRUE)

# ECCC_CH ----
SPECIES <-  rast(ECCC_CH_LST)
# Reclassify into binary
terra::NAflag(SPECIES ) <- 128
BINARY <- pblapply(SPECIES , function(x) {
  x[x > 0] <- 1
})

# Get cumulative area
HA_SUM <- sum(SPECIES , na.rm = TRUE)
writeRaster(HA_SUM, "Data/Output/Richness/ECCC_CH_HA_SUM.tif", overwrite = TRUE)

# Get count of species
N <- sum(BINARY, na.rm = TRUE)
writeRaster(N, "Data/Output/Richness/ECCC_CH_N.tif", overwrite = TRUE)

# ECCC_CH ----
SPECIES <-  rast(ECCC_SAR_LST)
# Reclassify into binary
terra::NAflag(SPECIES) <- 128
BINARY <- pblapply(SPECIES , function(x) {
  x[x > 0] <- 1
})

# Get cumulative area
HA_SUM <- sum(SPECIES , na.rm = TRUE)
writeRaster(HA_SUM, "Data/Output/Richness/ECCC_SAR_HA_SUM.tif", overwrite = TRUE)

# Get count of species
N <- sum(BINARY, na.rm = TRUE)
writeRaster(N, "Data/Output/Richness/ECCC_SAR_N.tif", overwrite = TRUE)

## End timer
end_time <- Sys.time()
end_time - start_time
