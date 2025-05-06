#
# Authors: Dan Wismer
#
# Date: Aug 24th, 2023
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
library(stringr)
library(sf)
source("R/fct_sci_to_common.R")
source("R/fct_calculate_targets.R")

# Read-in NCC planning unts and existing conservation
ncc_1km <- rast("Data/Input/NCC/NCC_1KM_PU.tif")
protected <- rast("Data/Output/Conserved/Existing_Conservation_ha.tif") 
terra::NAflag(protected) <- 128 # set NA pixel
protected <- protected  / 100 # convert to km2

# Read-in look up tables ----
ECCC_CH_LU <- read_excel("Data/Output/metadata/ECCC_CH_Metadata.xlsx")
ECCC_SAR_LU <- read_csv("Data/Output/metadata/ECCC_SAR_Metadata.csv")
IUCN_LU <- read_csv("Data/Output/metadata/IUCN_Metadata.csv")
NSC_END_LU <- read_excel("Data/Output/metadata/NSC_END_Metadata.xlsx")
NSC_SAR_LU <- read_excel("Data/Output/metadata/NSC_SAR_Metadata.xlsx")
NSC_SPP_LU <- read_excel("Data/Output/metadata/NSC_SPP_Metadata.xlsx")

# Generate protected sparse matrix ----
protected_rij <- prioritizr::rij_matrix(ncc_1km, protected, memory = FALSE)
rownames(protected_rij) <- c("Protected")

# ECCC CH ----------------------------------------------------------------------

## read-in prepped feature class
species <- read_sf("Data/Output/Conserved/Conserved.gdb", "ECCC_CH_PROTECTED") %>% 
  st_drop_geometry() %>%
  mutate(Source = "ECCC_CH") %>%
  mutate(SARA_Status = imap(
      COSEWIC_ID, ~ (filter(ECCC_CH_LU, COSEWIC_ID == .x)$SARA_Status[1]))
  ) %>%  
  mutate(Threat = case_when(
    SARA_Status == 1 ~ "EXT",
    SARA_Status == 2 ~ "END",
    SARA_Status == 3 ~ "THR",
  )) %>%
  mutate(Theme = "SAR Critical Habitat (ECCC)") %>%  
  mutate(File = paste0("T_NAT_ECCC_CH_", Threat, "_COSEWIC_", COSEWIC_ID, ".tif")) %>%
  mutate(Sci_Name = imap(
    COSEWIC_ID, ~ (filter(ECCC_CH_LU, COSEWIC_ID == .x)$SciName[1]))
  ) %>%  
  mutate(Common_Name = imap(
    COSEWIC_ID, ~ (filter(ECCC_CH_LU, COSEWIC_ID == .x)$CommName_E[1]))
  ) %>%  
  mutate(Total_Km2 = RANGE_HA / 100) %>%
  mutate(Protected_Km2 = PROTECTION_HA / 100) %>%
  mutate(Pct_Protected = round(((Protected_Km2 / Total_Km2) * 100), 2)) %>%
  mutate(Goal = calculate_targets(Total_Km2)) %>%
  select(c("Source", "File", "COSEWIC_ID", "Theme", 
           "Sci_Name", "Common_Name", "Threat", "Total_Km2", 
           "Protected_Km2", "Pct_Protected", "Goal")) %>%
  as.data.frame() %>%
  write.xlsx(
    file = 'Data/Output/metadata/WTW_NAT_SPECIES_METADATA.xlsx',
    sheetName = 'ECCC_CH', 
    row.names = FALSE,
    append = TRUE
  )
  
# ECCC SAR ---------------------------------------------------------------------

## read-in prepped feature class
species <- read_sf("Data/Output/Conserved/Conserved.gdb", "ECCC_SAR_PROTECTED") %>% 
  st_drop_geometry() %>%
  mutate(Source = "ECCC_SAR") %>%
  mutate(Threat = case_when(
    SAR_STAT_E == "Extirpated" ~ "EXT",
    SAR_STAT_E == "Endangered" ~ "END",
    SAR_STAT_E == "Threatened" ~ "THR",
    SAR_STAT_E == "Special Concern" ~ "SPC",
    SAR_STAT_E == "No Status" ~ "NOS",
    SAR_STAT_E == "Not at Risk" ~ "NAR"
  )) %>%
  mutate(Theme = "SAR Ranges (ECCC)") %>%  
  mutate(File = paste0("T_NAT_ECCC_SAR_", Threat, "_COSEWIC_", COSEWICID, ".tif")) %>%
  rename(Sci_Name = SCI_NAME) %>%
  rename(Common_Name = COM_NAME_E) %>%
  rename(COSEWIC_ID = COSEWICID) %>%
  mutate(Total_Km2 = RANGE_HA / 100) %>%
  mutate(Protected_Km2 = PROTECTION_HA / 100) %>%
  mutate(Pct_Protected = round(((Protected_Km2 / Total_Km2) * 100), 2)) %>%
  mutate(Goal = calculate_targets(Total_Km2)) %>%
  select(c("Source", "File", "COSEWIC_ID", "Theme", 
           "Sci_Name", "Common_Name", "Threat", "Total_Km2", 
           "Protected_Km2", "Pct_Protected", "Goal")) %>%
  as.data.frame() %>%
  write.xlsx(
    file = 'Data/Output/metadata/WTW_NAT_SPECIES_METADATA.xlsx',
    sheetName = 'ECCC_SAR', 
    row.names = FALSE,
    append = TRUE
  )

# IUCN AMPH --------------------------------------------------------------------

## read-in prepped RIJ
species_rij <- readRDS("Data/Output/RIJ/RIJ_IUCN_AMPH.rds")
## intersect species with protected areas
proteced_species <- rbind(species_rij, protected_rij) 
proteced_X_species <- proteced_species [, proteced_species ["Protected",] > 0]
proteced_X_species_tbl <- Matrix::rowSums(proteced_X_species, na.rm = TRUE) %>%
  as_tibble(rownames = "File") %>%
  rename(Protected_Km2 = value )

## build data frame
species_tbl <- Matrix::rowSums(species_rij, na.rm = TRUE) %>%
  as_tibble(rownames = "File") %>%
  rename(Total_Km2 = value) %>%
  left_join(proteced_X_species_tbl) %>%
  mutate(File = paste0(File, ".tif")) %>%
  mutate(Source = "IUCN_AMPH", .before = File) %>%
  mutate(Pct_Protected = round(((Protected_Km2 / Total_Km2) * 100), 2)) %>%
  mutate(Goal = calculate_targets(Total_Km2)) %>%  
  as.data.frame()

## add scientific name, common name, threat, theme, file and goal
species_tbl <- species_tbl %>%
  mutate(
    Sci_Name = imap(
      File, ~ (filter(IUCN_LU, File_Name == .x)$File_Name)),
    .after = File) %>%
  mutate(
    Common_Name = imap(
      File, ~ (filter(IUCN_LU, File_Name == .x)$Common_Name)),
    .after = Sci_Name) %>%
  mutate(
    Threat =  imap(
      File, ~ (filter(IUCN_LU, File_Name == .x)$Red_List)),
    .after = Common_Name
  ) %>%
  mutate(
    Theme = "Amphibians (IUCN AOH)", .after = File
  ) %>%
  mutate(
    File = paste0("T_NAT_IUCN_AMPH_", File)
  ) 

## write to excel
write.xlsx(
  species_tbl, 
  file = 'Data/Output/metadata/WTW_NAT_SPECIES_METADATA.xlsx',
  sheetName = 'IUCN_AMPH', 
  row.names = FALSE, 
  append = TRUE
)

# IUCN BIRD --------------------------------------------------------------------

## read-in prepped RIJ
species_rij <- readRDS("Data/Output/RIJ/RIJ_IUCN_BIRD.rds")
## intersect species with protected areas
proteced_species <- rbind(species_rij, protected_rij) 
proteced_X_species <- proteced_species [, proteced_species ["Protected",] > 0]
proteced_X_species_tbl <- Matrix::rowSums(proteced_X_species, na.rm = TRUE) %>%
  as_tibble(rownames = "File") %>%
  rename(Protected_Km2 = value )

## build data frame
species_tbl <- Matrix::rowSums(species_rij, na.rm = TRUE) %>%
  as_tibble(rownames = "File") %>%
  rename(Total_Km2 = value) %>%
  left_join(proteced_X_species_tbl) %>%
  mutate(File = paste0(File, ".tif")) %>%
  mutate(Source = "IUCN_BIRD", .before = File) %>%
  mutate(Pct_Protected = round(((Protected_Km2 / Total_Km2) * 100), 2)) %>%
  mutate(Goal = calculate_targets(Total_Km2)) %>%  
  as.data.frame()

## add scientific name, common name, season, threat, theme and file
species_tbl <- species_tbl %>%
  mutate(
    Sci_Name = imap(
      File, ~ (filter(IUCN_LU, File_Name == .x)$File_Name)),
    .after = File) %>%
  mutate(
    Common_Name = imap(
      File, ~ (filter(IUCN_LU, File_Name == .x)$Common_Name)),
    .after = Sci_Name) %>%
  mutate(
    Season = imap(
      File, ~ (filter(IUCN_LU, File_Name == .x)$Season)),
    .after = Sci_Name) %>%  
  mutate(
    Threat =  imap(
      File, ~ (filter(IUCN_LU, File_Name == .x)$Red_List)),
    .after = Common_Name
  ) %>%
  mutate(
    Theme = "Birds (IUCN AOH)", .after = File
  ) %>%
  mutate(
    File = paste0("T_NAT_IUCN_BIRD_", File)
  )

species_tbl$Season <- unlist(species_tbl$Season)
species_tbl$Common_Name <- unlist(species_tbl$Common_Name)

species_tbl <- species_tbl %>%
  mutate(
  Common_Name = 
    case_when(
      Season == "1" ~  paste0(Common_Name, " (resident)"),
      Season == "2" ~  paste0(Common_Name, " (breeding)"),
      Season == "3" ~  paste0(Common_Name, " (non-breeding)"),
      TRUE ~ Common_Name
    )
  )
  
## write to excel
write.xlsx(
  species_tbl, 
  file = 'Data/Output/metadata/WTW_NAT_SPECIES_METADATA.xlsx',
  sheetName = 'IUCN_BIRD', 
  row.names = FALSE, 
  append = TRUE
)

# IUCN MAMM --------------------------------------------------------------------

## read-in prepped RIJ
species_rij <- readRDS("Data/Output/RIJ/RIJ_IUCN_MAMM.rds")
## intersect species with protected areas
proteced_species <- rbind(species_rij, protected_rij) 
proteced_X_species <- proteced_species [, proteced_species ["Protected",] > 0]
proteced_X_species_tbl <- Matrix::rowSums(proteced_X_species, na.rm = TRUE) %>%
  as_tibble(rownames = "File") %>%
  rename(Protected_Km2 = value )

## build data frame
species_tbl <- Matrix::rowSums(species_rij, na.rm = TRUE) %>%
  as_tibble(rownames = "File") %>%
  rename(Total_Km2 = value) %>%
  left_join(proteced_X_species_tbl) %>%
  mutate(File = paste0(File, ".tif")) %>%
  mutate(Source = "IUCN_MAMM", .before = File) %>%
  mutate(Pct_Protected = round(((Protected_Km2 / Total_Km2) * 100), 2)) %>%
  mutate(Goal = calculate_targets(Total_Km2)) %>%
  as.data.frame()

## add scientific name, common name, threat, theme and file
species_tbl <- species_tbl %>%
  mutate(
    Sci_Name = imap(
      File, ~ (filter(IUCN_LU, File_Name == .x)$Sci_Name)),
    .after = File) %>%
  mutate(
    Common_Name = imap(
      File, ~ (filter(IUCN_LU, File_Name == .x)$Common_Name)),
    .after = Sci_Name) %>%
  mutate(
    Threat =  imap(
      File, ~ (filter(IUCN_LU, File_Name == .x)$Red_List)),
    .after = Common_Name
  ) %>%
  mutate(
    Theme = "Mammals (IUCN AOH)", .after = File
  ) %>%
  mutate(
    File = paste0("T_NAT_IUCN_MAMM_", File)
  )

## write to excel
write.xlsx(
  species_tbl, 
  file = 'Data/Output/metadata/WTW_NAT_SPECIES_METADATA.xlsx',
  sheetName = 'IUCN_MAMM', 
  row.names = FALSE, 
  append = TRUE
)

# IUCN REPT --------------------------------------------------------------------

## read-in prepped RIJ
species_rij <- readRDS("Data/Output/RIJ/RIJ_IUCN_REPT.rds")
## intersect species with protected areas
proteced_species <- rbind(species_rij, protected_rij) 
proteced_X_species <- proteced_species [, proteced_species ["Protected",] > 0]
proteced_X_species_tbl <- Matrix::rowSums(proteced_X_species, na.rm = TRUE) %>%
  as_tibble(rownames = "File") %>%
  rename(Protected_Km2 = value )

## build data frame
species_tbl <- Matrix::rowSums(species_rij, na.rm = TRUE) %>%
  as_tibble(rownames = "File") %>%
  rename(Total_Km2 = value) %>%
  left_join(proteced_X_species_tbl) %>%
  mutate(File = paste0(File, ".tif")) %>%
  mutate(Source = "IUCN_REPT", .before = File) %>%
  mutate(Pct_Protected = round(((Protected_Km2 / Total_Km2) * 100), 2)) %>%
  mutate(Goal = calculate_targets(Total_Km2)) %>%
  as.data.frame()

## add scientific name, common name, threat, theme and file
species_tbl <- species_tbl %>%
  mutate(
    Sci_Name = imap(
      File, ~ (filter(IUCN_LU, File_Name == .x)$Sci_Name)),
    .after = File) %>%
  mutate(
    Common_Name = imap(
      File, ~ (filter(IUCN_LU, File_Name == .x)$Common_Name)),
    .after = Sci_Name) %>%
  mutate(
    Threat =  imap(
      File, ~ (filter(IUCN_LU, File_Name == .x)$Red_List)),
    .after = Common_Name
  ) %>%
  mutate(
    Theme = "Reptiles (IUCN AOH)", .after = File
  ) %>%
  mutate(
    File = paste0("T_NAT_IUCN_REPT_", File)
  )

## write to excel
write.xlsx(
  species_tbl, 
  file = 'Data/Output/metadata/WTW_NAT_SPECIES_METADATA.xlsx',
  sheetName = 'IUCN_REPT', 
  row.names = FALSE, 
  append = TRUE
)

# NSC END --------------------------------------------------------------------

## read-in prepped RIJ
species_rij <- readRDS("Data/Output/RIJ/RIJ_NSC_END.rds")
## intersect species with protected areas
proteced_species <- rbind(species_rij, protected_rij) 
proteced_X_species <- proteced_species [, proteced_species ["Protected",] > 0]
proteced_X_species_tbl <- Matrix::rowSums(proteced_X_species, na.rm = TRUE) %>%
  as_tibble(rownames = "File") %>%
  rename(Protected_Km2 = value )

## build data frame
species_tbl <- Matrix::rowSums(species_rij, na.rm = TRUE) %>%
  as_tibble(rownames = "File") %>%
  rename(Total_Km2 = value) %>%
  left_join(proteced_X_species_tbl) %>%
  mutate(File = paste0(File, ".tif")) %>%
  mutate(Source = "NSC_END", .before = File) %>%
  mutate(Pct_Protected = round(((Protected_Km2 / Total_Km2) * 100), 2)) %>%
  mutate(Goal = calculate_targets(Total_Km2)) %>%
  as.data.frame()

## add scientific name, common name, threat, theme and file
species_tbl <- species_tbl %>%
  mutate(
    Sci_Name = imap(
      File, ~ str_replace_all(str_replace_all(.x, "_", " "), ".tif", "")),
    .after = File) %>%
  mutate(
    Common_Name = imap(
      Sci_Name, ~ nsc_end_to_name(NSC_END_LU, .x)), # reference NSC_END metadata
    .after = Sci_Name) %>%
  mutate(
    Threat = "", .after = Common_Name
    ) %>%
  mutate(
    Theme = "Endemic Species (NSC)", .after = File
  ) %>%
  mutate(
    File = paste0("T_NAT_NSC_END_", File)
  )

## write to excel
write.xlsx(
  species_tbl, 
  file = 'Data/Output/metadata/WTW_NAT_SPECIES_METADATA.xlsx',
  sheetName = 'NSC_END', 
  row.names = FALSE, 
  append = TRUE
)

# NSC SAR --------------------------------------------------------------------

## read-in prepped RIJ
species_rij <- readRDS("Data/Output/RIJ/RIJ_NSC_SAR.rds")
## intersect species with protected areas
proteced_species <- rbind(species_rij, protected_rij) 
proteced_X_species <- proteced_species [, proteced_species ["Protected",] > 0]
proteced_X_species_tbl <- Matrix::rowSums(proteced_X_species, na.rm = TRUE) %>%
  as_tibble(rownames = "File") %>%
  rename(Protected_Km2 = value )

## build data frame
species_tbl <- Matrix::rowSums(species_rij, na.rm = TRUE) %>%
  as_tibble(rownames = "File") %>%
  rename(Total_Km2 = value) %>%
  left_join(proteced_X_species_tbl) %>%
  mutate(File = paste0(File, ".tif")) %>%
  mutate(Source = "NSC_SAR", .before = File) %>%
  mutate(Pct_Protected = round(((Protected_Km2 / Total_Km2) * 100), 2)) %>%
  mutate(Goal = calculate_targets(Total_Km2)) %>%
  as.data.frame()

## add scientific name, common name, threat, theme and file
species_tbl <- species_tbl %>%
  mutate(
    Sci_Name = imap(
      File, ~ str_replace_all(str_replace_all(.x, "_", " "), ".tif", "")),
    .after = File) %>%
  mutate(
    Common_Name = imap(
      Sci_Name, ~ nsc_sar_to_name(NSC_SAR_LU, .x)), # reference NSC_SAR metadata
    .after = Sci_Name) %>%
  mutate(
    Threat = "", .after = Common_Name
    ) %>%
  mutate(
    Theme = "SAR (NSC)", .after = File
  ) %>%
  mutate(
    File = paste0("T_NAT_NSC_SAR_", File)
  )

## write to excel
write.xlsx(
  species_tbl, 
  file = 'Data/Output/metadata/WTW_NAT_SPECIES_METADATA.xlsx',
  sheetName = 'NSC_SAR', 
  row.names = FALSE, 
  append = TRUE
)

# NSC SSPP --------------------------------------------------------------------

## read-in prepped RIJ
species_rij <- readRDS("Data/Output/RIJ/RIJ_NSC_SPP.rds")
## intersect species with protected areas
proteced_species <- rbind(species_rij, protected_rij) 
proteced_X_species <- proteced_species [, proteced_species ["Protected",] > 0]
proteced_X_species_tbl <- Matrix::rowSums(proteced_X_species, na.rm = TRUE) %>%
  as_tibble(rownames = "File") %>%
  rename(Protected_Km2 = value )

## build data frame
species_tbl <- Matrix::rowSums(species_rij, na.rm = TRUE) %>%
  as_tibble(rownames = "File") %>%
  rename(Total_Km2 = value) %>%
  left_join(proteced_X_species_tbl) %>%
  mutate(File = paste0(File, ".tif")) %>%
  mutate(Source = "NSC_SPP", .before = File) %>%
  mutate(Pct_Protected = round(((Protected_Km2 / Total_Km2) * 100), 2)) %>%
  mutate(Goal = calculate_targets(Total_Km2)) %>%
  as.data.frame()

## add scientific name, common name, threat, theme and file
species_tbl <- species_tbl %>%
  mutate(
    Sci_Name = imap(
      File, ~ str_replace_all(str_replace_all(.x, "_", " "), ".tif", "")),
    .after = File) %>%
  mutate(
    Common_Name = imap(
      Sci_Name, ~ nsc_spp_to_name(NSC_SPP_LU, .x)), # reference NSC_SPP metadata
    .after = Sci_Name) %>%
  mutate(
    Threat = "", .after = Common_Name
    ) %>%
  mutate(
    Theme = "Common Species (NSC)", .after = File
  ) %>%
  mutate(
    File = paste0("T_NAT_NSC_SPP_", File)
  )

## write to excel
write.xlsx(
  species_tbl, 
  file = 'Data/Output/metadata/WTW_NAT_SPECIES_METADATA.xlsx',
  sheetName = 'NSC_SPP', 
  row.names = FALSE, 
  append = TRUE
)
