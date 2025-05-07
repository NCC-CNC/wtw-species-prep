
eccc_sar_aoh_path <- "C:/Data/NAT/SPECIES_1km/AOH_SAR_Layers_1KM"
eccc_sar_aoh_RENAME_path <- "C:/Data/NAT/SPECIES_1km/AOH_SAR_Layers_1KM_rename"
eccc_sar_aoh <- list.files(eccc_sar_aoh_path, pattern = ".tif$", full.names = TRUE)

for (i in seq_along(eccc_sar_aoh)) {
  r <- rast(eccc_sar_aoh[i])
  base_with_extention <- basename(eccc_sar_aoh[i])
  base <- tools::file_path_sans_ext(basename(eccc_sar_aoh[i]))
  names(r) <- base
  writeRaster(r, file.path(eccc_sar_aoh_RENAME_path,base_with_extention), overwrite = TRUE)
}
