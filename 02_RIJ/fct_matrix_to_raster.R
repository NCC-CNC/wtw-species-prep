
matrix_to_raster <- function(template_raster, rij) {
  r <- template_raster
  r_val <- r[][!is.na(template_raster[])]
  r_val <- rij
  r[][!is.na(template_raster[])] <- r_val
  return(r)
}