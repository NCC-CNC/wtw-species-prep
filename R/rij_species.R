library(raster)
library(prioritizr)
library(foreach)
library(parallel)
library(doParallel)

# RIJ output folder
RIJ_OUTPUT <- "Data/Output/RIJ"

# Species folder that has final .tiffs 
ECCC_CH_PATH <- "Data/Output/ECCC_CH"
ECCC_SAR_PATH <- "Data/Output/ECCC_SAR"

# Vector of sources to loop over
sources <- c(ECCC_SAR_PATH) # <-- ADD/REMOVE AS NEEDED

# Loop over data sources
counter = 1
len = length(sources)
for (source in sources) {
  
  start_time <- Sys.time()
  name <- strsplit(source, "/")[[1]][3] # ECC_SAR, ECCC_CH, etc.
  print(paste0("Processing ", counter, " of ", len, ": ", name))
  
  # Set up clusters
  n_cores = detectCores() - 2
  cl <- makeCluster(n_cores)
  registerDoParallel(cl)    
  
  # Get list of tiffs 
  species <- list.files(source, pattern = ".tif$", full.names = TRUE)
  
  # Split list up into chunks ----
  chunks <- 5 # <--- CHANGE THIS NEED BE
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