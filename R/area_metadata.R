#
# Authors: Dan Wismer
#
# Date: June 26th, 2023
#
# Description: Builds species area metadata. This includes total range/habitat
#              area and area of range/habitat that is currently protected.
#
# Inputs:  1. Species RIJ data
#          2. Existing Conservation raster
#
# Outputs: 1. Metadata on each species layer (.xlsl)
#
#===============================================================================

library(terra)
library(prioritizr)
library(tibble)
library(dplyr)
library(Matrix)
library(xlsx)

# Read-in NCC planning unts and existing conservation
ncc_1km <- rast("Data/Input/NCC/Constant_1KM.tif")
# protected <- rast("Data/Output/Conserved/Existing_Conservation.tif")
# DELETE LATER
protected <- rast("C:/Github/natdata-to-aoi/data/national/protected/CPCAD_NCC_FS_CA.tif")

# Generate protected sparse matrix ----
protected_rij <- prioritizr::rij_matrix(ncc_1km, protected)
rownames(protected_rij) <- c("Protected")

# ECCC CH ----------------------------------------------------------------------
species_rij <- readRDS("Data/Output/RIJ/RIJ_ECCC_CH.rds")
proteced_species <- rbind(species_rij, protected_rij) 
proteced_X_species <- proteced_species [, proteced_species ["Protected",] > 0]
proteced_X_species_tbl <- Matrix::rowSums(proteced_X_species, na.rm = TRUE) %>%
  as_tibble(rownames = "File") %>%
  rename(Protected_Ha = value )

## build tibble
species_tbl <- Matrix::rowSums(species_rij, na.rm = TRUE) %>%
  as_tibble(rownames = "File") %>%
  rename(Total_HA = value) %>%
  left_join(proteced_X_species_tbl) %>%
  mutate(File = paste0(File, ".tif")) %>%
  mutate(Source = "ECCC_CH", .before = File)

## write to excel
write.xlsx(
  species_tbl, 
  file = 'Data/Output/metadata/Species_Area.xlsx',
  sheetName = 'ECCC_CH', 
  row.names = FALSE, 
  append = TRUE
)

# ECCC SAR ---------------------------------------------------------------------
species_rij <- readRDS("Data/Output/RIJ/RIJ_ECCC_SAR.rds")
proteced_species <- rbind(species_rij, protected_rij) 
proteced_X_species <- proteced_species [, proteced_species ["Protected",] > 0]
proteced_X_species_tbl <- Matrix::rowSums(proteced_X_species, na.rm = TRUE) %>%
  as_tibble(rownames = "File") %>%
  rename(Protected_Ha = value )

## build tibble
species_tbl <- Matrix::rowSums(species_rij, na.rm = TRUE) %>%
  as_tibble(rownames = "File") %>%
  rename(Total_HA = value) %>%
  left_join(proteced_X_species_tbl) %>%
  mutate(File = paste0(File, ".tif")) %>%
  mutate(Source = "ECCC_SAR", .before = File) %>%
  mutate(Pct_Protected = round(((Protected_Ha / Total_HA) * 100), 2)) %>%
  as.data.frame()

## write to excel
write.xlsx(
  species_tbl, 
  file = 'Data/Output/metadata/Species_Area.xlsx',
  sheetName = 'ECCC_SAR', 
  row.names = FALSE, 
  append = TRUE
)

