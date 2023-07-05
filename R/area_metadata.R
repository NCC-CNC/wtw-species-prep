#
# Authors: Dan Wismer
#
# Date: July 5th, 2023
#
# Description: Builds species metadata. This includes total range/habitat
#              area and area of range/habitat that is currently protected.
#
# Inputs:  1. Species RIJ data
#          2. Existing Conservation raster
#          3. metadata spreadsheets
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
library(readxl)
library(readr)
library(purrr)
source("R/fct_sci_to_common.R")

# Read-in NCC planning unts and existing conservation
ncc_1km <- rast("Data/Input/NCC/NCC_1KM_PU.tif")
protected <- rast("Data/Output/Conserved/Existing_Conservation.tif")

# Read-in look up tables ----
ECCC_CH_LU <- read_excel("Data/Output/metadata/ECCC_CH_Metadata.xlsx")
ECCC_SAR_LU <- read_csv("Data/Output/metadata/ECCC_SAR_Metadata.csv")
IUCN_LU <- read_csv("Data/Output/metadata/IUCN_Metadata.csv")
# NSC_END_LU <- read_excel(file.path(table_path,  "NSC_END_Metadata.xlsx"))
# NSC_SAR_LU <- read_excel(file.path(table_path, "NSC_SAR_Metadata.xlsx"))
# NSC_SPP_LU <- read_excel(file.path(table_path, "NSC_SPP_Metadata.xlsx"))

# Generate protected sparse matrix ----
protected_rij <- prioritizr::rij_matrix(ncc_1km, protected, memory = FALSE)
rownames(protected_rij) <- c("Protected")

# ECCC CH ----

## read-in prepped RIJ
species_rij <- readRDS("Data/Output/RIJ/RIJ_ECCC_CH.rds")
## intersect species with protected areas
proteced_species <- rbind(species_rij, protected_rij) 
proteced_X_species <- proteced_species [, proteced_species ["Protected",] > 0]
proteced_X_species_tbl <- Matrix::rowSums(proteced_X_species, na.rm = TRUE) %>%
  as_tibble(rownames = "File") %>%
  rename(Protected_Ha = value)

## build data frame
species_tbl <- Matrix::rowSums(species_rij, na.rm = TRUE) %>%
  as_tibble(rownames = "File") %>%
  rename(Total_Ha = value) %>%
  left_join(proteced_X_species_tbl) %>%
  mutate(File = paste0(File, ".tif")) %>%
  mutate(Source = "ECCC_CH", .before = File) %>%
  mutate(Pct_Protected = round(((Protected_Ha / Total_Ha) * 100), 2)) %>%
  as.data.frame()

## add scientific name, common name and threat
species_tbl <- species_tbl %>%
  mutate(
    Sci_Name = imap(
      File, ~ (ch_cosewicid_to_name(
        LUT = ECCC_CH_LU,
        cosewicid = tail(unlist(strsplit(strsplit(.x, ".tif")[[1]][1], "_")), 1),
        name_type = "sci")
      )), .after = File) %>%
  mutate(
    Common_Name = imap(
      File, ~ (ch_cosewicid_to_name(
        LUT = ECCC_CH_LU,
        cosewicid = tail(unlist(strsplit(strsplit(.x, ".tif")[[1]][1], "_")), 1),
        name_type = "common")
      )), .after = Sci_Name) %>%
  mutate(
    Threat =  imap(
      File, ~ (unlist(strsplit(strsplit(.x, ".tif")[[1]][1], "_"))[4])),
    .after = Common_Name
  )
  
## write to excel
write.xlsx(
  species_tbl, 
  file = 'Data/Output/metadata/Species_Metadata.xlsx',
  sheetName = 'ECCC_CH', 
  row.names = FALSE
)

# ECCC SAR ----

## read-in prepped RIJ
species_rij <- readRDS("Data/Output/RIJ/RIJ_ECCC_SAR.rds")
## intersect species with protected areas
proteced_species <- rbind(species_rij, protected_rij) 
proteced_X_species <- proteced_species [, proteced_species ["Protected",] > 0]
proteced_X_species_tbl <- Matrix::rowSums(proteced_X_species, na.rm = TRUE) %>%
  as_tibble(rownames = "File") %>%
  rename(Protected_Ha = value )

## build data frame
species_tbl <- Matrix::rowSums(species_rij, na.rm = TRUE) %>%
  as_tibble(rownames = "File") %>%
  rename(Total_Ha = value) %>%
  left_join(proteced_X_species_tbl) %>%
  mutate(File = paste0(File, ".tif")) %>%
  mutate(Source = "ECCC_SAR", .before = File) %>%
  mutate(Pct_Protected = round(((Protected_Ha / Total_Ha) * 100), 2)) %>%
  as.data.frame()

## add scientific name, common name an threat
species_tbl <- species_tbl %>%
  mutate(
    Sci_Name = imap(
      File, ~ (sar_cosewicid_to_name(
        LUT = ECCC_SAR_LU,
        cosewicid = tail(unlist(strsplit(strsplit(.x, ".tif")[[1]][1], "_")), 1),
        name_type = "sci")
      )), .after = File) %>%
  mutate(
    Common_Name = imap(
      File, ~ (sar_cosewicid_to_name(
        LUT = ECCC_SAR_LU,
        cosewicid = tail(unlist(strsplit(strsplit(.x, ".tif")[[1]][1], "_")), 1),
        name_type = "common")
      )), .after = Sci_Name) %>%
  mutate(
    Threat =  imap(
      File, ~ (unlist(strsplit(strsplit(.x, ".tif")[[1]][1], "_"))[4])),
    .after = Common_Name
  )
  
## write to excel
write.xlsx(
  species_tbl, 
  file = 'Data/Output/metadata/Species_Metadata.xlsx',
  sheetName = 'ECCC_SAR', 
  row.names = FALSE, 
  append = TRUE
)
