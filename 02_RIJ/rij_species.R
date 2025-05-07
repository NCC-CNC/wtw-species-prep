#
# Authors: Dan Wismer & Marc Edwards
#
# Date: July 5th, 2023
#
# Description: Builds RIJ sparse matrix of 1km .tifs. This analysis uses parrellel
#              processing. 
#
# Inputs:  1. Paths to 1km .tifs
#          2. Output folder
#          Optional:
#          3. define "sources" variable
#          4. number of cores
#          5. chunk size (splitting rasters into equal size lists)
#
# Outputs: 1. sparse matrix saved as .RDS
#
# RUN RECORDER:   
##  ECCC_CH: ~3 mins, 261 species, 6 cores, 50 chunks, last run: July 6th, 2023 
##  ECCC_SAR: ~6 mins, 489 species, 6 cores, 50 chunks, last run: Aug 28th, 2023 
##  ECCC_SAR_AOH: ~6 mins, 456 species, 6 cores, 50 chunks, last run: May 7th, 2025
##  IUCN_AMPH: ~2 mins, 6 cores, 50 chunks
##  IUCN_BIRD_S1: ~3 mins, 192 species, 6 cores, 50 chunks, last run: May 2nd, 2025
##  IUCN_BIRD_S2: ~6 mins, 351 species, 6 cores, 50 chunks, last run: May 2nd, 2025
##  IUCN_BIRD_S3: ~2 mins, 131 species, 6 cores, 50 chunks, last run: May 2nd, 2025
##  IUCN_MAMM: ~3 mins, 6 cores, 50 chunks
##  IUCN_REPT: ~1 mins, 6 cores, 50 chunks
##  NSC_END: ~3 mins, 6 cores, 50 chunks
##  NSC_SAR: ~5 mins, 6 cores, 50 chunks
##  NSC_SPP: NOT COMPLETTING!!! last run: July 6th, 2023
##  SDM: ~ 19 mins, 1448 species, 6 cores, 100 chunks, last run: May 6th, 2025
#===============================================================================

library(terra)
library(prioritizr)
library(foreach)
library(parallel)
library(doParallel)
library(Matrix)

# RIJ output folder
RIJ_OUTPUT <- "Data/Output/RIJ"

# NCC planning unit raster grid 
PU <- rast("Data/Input/NCC/NCC_1KM_PU.tif")
# https://github.com/rspatial/terra/issues/166 
PU <- wrap(PU) # <--- needed for parallel

# Species folder that has final .tiffs 
ECCC_CH_PATH <- "Data/Output/ECCC_CH"
ECCC_SAR_PATH <- "Data/Output/ECCC_SAR"
ECCC_SAR_AOH_PATH <- "C:/Data/NAT/SPECIES_1km/AOH_SAR_Layers_1KM"
IUCN_AMPH_PATH <- "C:/Data/NAT/SPECIES_1km/IUCN_AMPH"
IUCN_BIRD_S1_PATH <- "C:/Data/NAT/SPECIES_1km/IUCN_BIRD/S1_Resident"
IUCN_BIRD_S2_PATH <- "C:/Data/NAT/SPECIES_1km/IUCN_BIRD/S2_Breeding"
IUCN_BIRD_S3_PATH <- "C:/Data/NAT/SPECIES_1km/IUCN_BIRD/S3_Non_Breeding"
IUCN_MAMM_PATH <- "C:/Data/NAT/SPECIES_1km/IUCN_MAMM"
IUCN_REPT_PATH <- "C:/Data/NAT/SPECIES_1km/IUCN_REPT"
NSC_END_PATH <- "C:/Data/NAT/SPECIES_1km/NSC_END"
NSC_SAR_PATH <- "C:/Data/NAT/SPECIES_1km/NSC_SAR"
NSC_SPP_PATH <- "C:/Data/NAT/SPECIES_1km/NSC_SPP"
SDM <- "C:/Data/NAT/SPECIES_1km/SDM_Binary_1KM"

# Named vector of sources to loop over
sources <- c(
  "ECCC_CH" = ECCC_CH_PATH, 
  "ECCC_SAR" = ECCC_SAR_PATH,
  "ECCC_SAR_AOH" = ECCC_SAR_AOH_PATH,
  "IUCN_AMPH" = IUCN_AMPH_PATH,
  "IUCN_BIRD_S1" = IUCN_BIRD_S1_PATH,
  "IUCN_BIRD_S2" = IUCN_BIRD_S2_PATH,
  "IUCN_BIRD_S3" = IUCN_BIRD_S3_PATH,
  "IUCN_MAMM" = IUCN_MAMM_PATH,
  "IUCN_REPT" = IUCN_REPT_PATH,
  "NSC_END" = NSC_END_PATH,
  "NSC_SAR" = NSC_SAR_PATH,
  "NSC_SPP" = NSC_SPP_PATH,
  "SDM" = SDM
)

# RIJ function (needed in foreach %dopar%) ----
batch_rij <- function(PU, tiff_lst, name) {
  ## read-in species
  species_stack <- terra::rast(tiff_lst)
  ## define NA pixel
  if (name %in% c("ECCC_CH", "ECCC_SAR")) {
    terra::NAflag(species_stack) <- 128
  }
  ## build RIJ matrix
  rij <- prioritizr::rij_matrix(rast(PU), species_stack, memory = FALSE)
  rm(species_stack)
  rm(PU)
  return(rij)
}

# Loop over data sources ----
sources <- sources[3:3] # <--- SUBSET NEED BE TO NOT ITERATE OVER ALL SOURCES
for (i in seq_along(sources)) {
  start_time <- Sys.time()
  
  name <- names(sources[i])
  print(paste0("Processing ", i, " of ", length(sources), ": ", name))
  
  # Set up clusters
  n_cores = detectCores() - 10 # <-- CHANGE NUMBER OF CORES NEED BE
  cl <- makeCluster(n_cores)
  registerDoParallel(cl)    
  
  # Get list of tiffs 
  species <- list.files(sources[i], pattern = ".tif$", full.names = TRUE)
  print(paste0("... number of species: ", length(species)))
  
  # Split list up into chunks ----
  chunks <- 50 # <--- CHANGE NUMBER OF "CHUNKS" NEED BE
  species_split <- split(
    species, ceiling(seq_along(species) / (length(species) / chunks))
  )
  
  print(paste0("... number of tifs in each chunk: ~", length(species_split[[1]])))
  
  # Build rij matrix in parallel ----
  species_rij <- foreach(
    j = seq_along(species_split), 
    .packages = c("terra", "prioritizr"), 
    .combine = "rbind",
    .multicombine = TRUE,
    .inorder = TRUE) %dopar% {
      
      ## build species RIJ 
      species_rij <- batch_rij(PU, species_split[[j]], name)
    
    }
    
  # Stop cluster
  stopCluster(cl)
  
  # Save rij to disk
  print("... Saving as .rds")
  saveRDS(species_rij, file.path(RIJ_OUTPUT, paste0("RIJ_", name, ".rds")), compress = TRUE)
  
  ## clear RAM
  rm(species)
  rm(species_rij)
  gc()

  ## end timer
  end_time <- Sys.time()
  print(end_time - start_time)
}
