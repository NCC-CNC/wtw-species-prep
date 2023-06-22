#
# Authors: Dan Wismer
#
# Date: June 22nd, 2023
#
# Description: Build IUCN metadata needed for wtw-data-prep. Columns include:
#              IUCNID, Source, Group, File_Name, Sci_Name, Common_Name, Season,
#              Red_List.
#
# Inputs:  1. IUCN paths to 1km .tifs
#          3. Output folder
#
# Outputs: 1. Metadata on each IUCN layer
#
#===============================================================================

# NOTE ----
# A IUCN Red List API -v3 token is needed for taxize package: 
# http://apiv3.iucnredlist.org/api/v3/token
# Once the token is received, add it to your .Renviron file. It should look 
# something like this:
# IUCN_REDLIST_KEY = "85222fc6deec8f764209dbae8ccd81d1c565cc16c6"

library(taxize)
library(terra)
library(stringr)
library(dplyr)
library(purrr)
library(readr)

# Start timer (~40 mins)
start_time <- Sys.time()

# Set output CSV folder
OUTPUT <- "Data/Output/metadata"

# Set paths
IUCN_AMPH_PATH <- "C:/Data/NAT/SPECIES_1km/IUCN_AMPH"
IUCN_BIRD_PATH <- "C:/Data/NAT/SPECIES_1km/IUCN_BIRD"
IUCN_MAMM_PATH <- "C:/Data/NAT/SPECIES_1km/IUCN_MAMM"
IUCN_REPT_PATH <- "C:/Data/NAT/SPECIES_1km/IUCN_REPT"

# Get tiff list
IUCN_AMPH <- list.files(IUCN_AMPH_PATH, pattern='.tif$', full.names = F)
IUCN_BIRD <- list.files(IUCN_BIRD_PATH, pattern='.tif$', full.names = F)
IUCN_MAMM <- list.files(IUCN_MAMM_PATH, pattern='.tif$', full.names = F)
IUCN_REPT <- list.files(IUCN_REPT_PATH, pattern='.tif$', full.names = F)
IUCN_ALL <- list(AMPH = IUCN_AMPH, BIRD = IUCN_BIRD, MAMM = IUCN_MAMM, REPT = IUCN_REPT)

# Build empty df
iucn_df <- data.frame(
  IUCNID = as.numeric(),
  Source = as.character(),
  Group = as.character(),
  File_Name = as.character(),
  Sci_Name = as.character(),
  Common_Name = as.character(),
  Season = as.character(),
  Red_List = as.character()
)

# Get the sci name and season from the original file name
file_2_sci <- function(file_name) {
  sci_name <- gsub("_", " ", file_name)
  sci_name <- gsub(" aoh.tif", "", sci_name)
  last_char <- str_sub(sci_name, -1)
  if (!is.na(as.numeric(last_char))) {
    season <- last_char
    sci_name <- gsub('.{2}$', "", sci_name)
  } else {
    sci_name <- sci_name
    season <- NA_character_
  }
  return(c(sci_name, season))
}

# Processing fields from file name ----
for (i in seq_along(IUCN_ALL)) {
  for (j in seq_along(IUCN_ALL[[i]])) {
    ## get sci name and season
    ss <- file_2_sci(IUCN_ALL[[i]][j])
    ## populate 
    id <- 0
    source <- "IUCN"
    group <- names(IUCN_ALL[i])
    file_name <- IUCN_ALL[[i]][j]
    sci_name <- ss[1]
    com_name <- ""
    season <- if (is.na(ss[2])) "" else ss[2]
    red_list <- ""
    ## create new row
    new_row <- c(id, source, group, file_name, sci_name, com_name, season, red_list)
    ## append to df
    iucn_df <- structure(rbind(iucn_df, new_row), .Names = names(iucn_df))    
  }
}

# Populate IUCN id, this takes sometime ...
iucn_df <- iucn_df %>%
  mutate(IUCNID = iucn_id(Sci_Name))

# Populate common name, this takes sometime ... 
iucn_df <- iucn_df %>%
  mutate(Common_Name = (taxize::sci2comm(Sci_Name, db = "iucn"))) %>%
  mutate(Common_Name = replace(Common_Name, length(Common_Name) > 1, map(Common_Name, first))) %>%
  mutate(Common_Name = unlist(Common_Name))

# Populate red list
iucn_df <- iucn_df %>%
  mutate(Red_List = iucn_status(iucn_summary(Sci_Name)))

# MANUAL UPDATE: I had to Google these species that "taxize" did not get
# named list: file name = c(common name, red list, iucn id)
manual_update <- list("Antigone_canadensis_2_aoh.tif" = c("Sandhill Crane", "LC", 1),
                      "Cyanecula_svecica_2_aoh.tif" = c("Bluethroat", "LC", 2),
                      "Falcipennis_canadensis_1_aoh.tif" = c("Spruce Grouse", "LC", 3),
                      "Falcipennis_franklinii_1_aoh.tif" = c("Franklin's Grouse", "LC", 4),
                      "Regulus_calendula_1_aoh.tif" = c("Ruby-Crowned Kinglet", "LC", 5),
                      "Regulus_calendula_2_aoh.tif" = c("Ruby-Crowned Kinglet", "LC", 6),
                      "Microtus_oeconomus_aoh.tif" = c("Tundra Vole", "LC", 7),
                      "Myodes_gapperi_aoh.tif" = c("Southern Red-Backed Vole", "LC", 8),
                      "Myodes_rutilus_aoh.tif" = c("Northern Red-Backed Vole", "LC", 9),
                      "Pipistrellus_subflavus_aoh.tif" = c("Tricolored Bat", "LC", 10),
                      "Sorex_monticolus_aoh.tif" = c("Montane Shrew", "LC", 11),
                      "Pantherophis_gloydi_aoh.tif" = c("Eastern Fox Snake", "LC", 12))

# Update common name from manual list
# .x is the value and .y is the index
iucn_df <- iucn_df %>%
  mutate(
    Common_Name = imap(
      File_Name, ~ ifelse(
        .x %in% names(manual_update), manual_update[[.x]][1], Common_Name[.y]
        )
      )
    )
  
# Update red list from manual list
iucn_df <- iucn_df %>%
  mutate(
    Red_List = imap(
      File_Name, ~ ifelse(
        .x %in% names(manual_update), manual_update[[.x]][2], Red_List[.y]
        )
      )
    )

# Update iucn id from manual list
iucn_df <- iucn_df %>%
  mutate(
    IUCNID = imap(
      File_Name, ~ ifelse(
        .x %in% names(manual_update), manual_update[[.x]][3], IUCNID[.y]
        )
      )
    )

# Write to .csv ----
write_csv(iucn_df, file.path(OUTPUT, "IUCN_Metadata.csv"))

# End timer
end_time <- Sys.time()
print(end_time - start_time)
