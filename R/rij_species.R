#
# Authors: Dan Wismer
#
# Date: June 22nd, 2023
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
# Estimated run times: ECCC_CH: ~4 mins
#===============================================================================

library(terra)
library(prioritizr)
library(foreach)
library(parallel)
library(doParallel)

# RIJ output folder
RIJ_OUTPUT <- "Data/Output/RIJ"

# Species folder that has final .tiffs 
ECCC_CH_PATH <- "Data/Output/ECCC_CH"
ECCC_SAR_PATH <- "Data/Output/ECCC_SAR"
IUCN_AMPH_PATH <- "C:/Data/NAT/SPECIES_1km/IUCN_AMPH"
IUCN_BIRD_PATH <- "C:/Data/NAT/SPECIES_1km/IUCN_BIRD"
IUCN_MAMM_PATH <- "C:/Data/NAT/SPECIES_1km/IUCN_MAMM"
IUCN_REPT_PATH <- "C:/Data/NAT/SPECIES_1km/IUCN_REPT"
NSC_END_PATH <- "C:/Data/NAT/SPECIES_1km/NSC_END"
NSC_SAR_PATH <- "C:/Data/NAT/SPECIES_1km/NSC_SAR"
NSC_SPP_PATH <- "C:/Data/NAT/SPECIES_1km/NSC_SPP"

# Vector of sources to loop over
sources <- c(ECCC_CH_PATH) # <-- ADD/REMOVE AS NEEDED

# Loop over data sources
counter = 1
len = length(sources)
for (source in sources) {
  
  start_time <- Sys.time()
  name <- strsplit(source, "/")[[1]][3] # ECC_SAR, ECCC_CH, etc.
  print(paste0("Processing ", counter, " of ", len, ": ", name))
  
  # Set up clusters
  n_cores = detectCores() - 10 # had to reduce cores because I was running out of memory
                               # did something change with prioritizr::rij_matrix? ...
                               # I use to be able to run this with all cores ...
  cl <- makeCluster(n_cores)
  registerDoParallel(cl)    
  
  # Get list of tiffs 
  species <- list.files(source, pattern = ".tif$", full.names = TRUE)
  
  # Split list up into chunks ----
  chunks <- 50 # <--- CHANGE THIS NEED BE
  species_split <- split(
    species, ceiling(seq_along(species) / (length(species) / chunks))
  )
  
  # Build rij matrix in parallel ----
  species_rij <- foreach(
    i = seq_along(species_split), 
    .packages = c("terra", "prioritizr"), 
    .combine = "rbind") %dopar% {
      
      # planning unit raster grid 
      ncc_1km <- rast("Data/Input/NCC/Constant_1KM.tif")
      
      ## read-in species
      species_stack <- terra::rast(species_split[[i]])
      
      ## define NA pixel... 
      ## had to do this because the arcpy PolygonToRaster sets NoData to -128 
      if (name %in% c("ECCC_CH", "ECCC_SAR")) {
        terra::NAflag(species_stack) <- 128
      }

      ## build RIJ matrix
      rij <- prioritizr::rij_matrix(ncc_1km, species_stack)
      return(rij)
    }
  
  # Stop cluster
  stopCluster(cl)
  
  # Save rij to disk
  print("... Saving as .rds")
  saveRDS(species_rij, file.path(RIJ_OUTPUT, paste0("RIJ_", name, ".rds")), compress = TRUE)
  
  ## advance counter
  counter <-  counter + 1
  
  ## clear RAM
  rm(species)
  rm(species_rij)
  gc()
  
  ## end timer
  end_time <- Sys.time()
  print(end_time - start_time)
}
