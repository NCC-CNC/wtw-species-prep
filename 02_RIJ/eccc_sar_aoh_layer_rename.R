
eccc_sar_aoh_path <- "C:/Data/NAT/SPECIES_1km/AOH_SAR_Layers_1KM"
eccc_sar_aoh_RENAME_path <- "C:/Data/NAT/SPECIES_1km/AOH_SAR_Layers_1KM_rename"
eccc_sar_aoh <- list.files(eccc_sar_aoh_path, pattern = ".tif$", full.names = TRUE)

NCC_CRS <- terra::rast("C:/Data/PRZ/NAT_DATA/NAT_1KM_20240729/_1km/Idx.tif") |>
  terra::crs()

for (i in seq_along(eccc_sar_aoh)) {
  r <- rast(eccc_sar_aoh[i])
  base_with_extention <- basename(eccc_sar_aoh[i])
  base <- tools::file_path_sans_ext(basename(eccc_sar_aoh[i]))
  names(r) <- base
  crs(r) <- NCC_CRS # update CRS name from unknown to Canada_Albers_WGS_1984.
  writeRaster(r, file.path(eccc_sar_aoh_RENAME_path, base_with_extention), overwrite = TRUE)
}
