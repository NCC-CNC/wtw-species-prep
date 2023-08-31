calc_coverage_from_meta <- function(meta, units = "ha") {
  
  if (units == "ha") {
    scaler = 100
  } else {
    scaler = 1
  }
  
  coverage_meta <- meta %>%
    mutate(
      Goal_Area = (Total_Km2 * Goal) * scaler,
      Contr_Pct = (1 / Goal_Area) * 100,
      Pixel_Contr = if_else(Contr_Pct > 100, 100, Contr_Pct)
    ) %>% 
    arrange(File)
  
  return(coverage_meta)
  
}