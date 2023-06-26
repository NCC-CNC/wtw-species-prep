# Where To Work Species Prep

Python/arcpy and R scripts designed to prep species source data to the 1km grid and generate metadata. Outputs from this workflow are needed for [wtw-data-prep](https://github.com/NCC-CNC/wtw-data-prep).

---

### Arcpy script tools for ArcPro
- Parses [Species at Risk Range Map Extents](https://open.canada.ca/data/en/dataset/d00f8e8c-40c4-435a-b790-980339ce3121) and [Critical Habitat Area](https://open.canada.ca/data/en/dataset/47caa405-be2b-4e9e-8f53-c478ade2ca74) by COSEWICID
- Extracts parsed area that intersect with the 1km vector grid
- Rasterizes the extractions by area (ha)
<p align="center"> 
   <img src="https://github.com/NCC-CNC/wtw-species-prep/blob/main/Doc/Imgs/00_parse_eccc.jpg" width="32%" height="32%">
   <img src="https://github.com/NCC-CNC/wtw-species-prep/blob/main/Doc/Imgs/01_intersect_grid.jpg" width="32%" height="32%">
   <img src="https://github.com/NCC-CNC/wtw-species-prep/blob/main/Doc/Imgs/02_rasterize.jpg" width="32%" height="32%">
</p> 

- Generates the WTW include layer by intersecting CPCAD terrestrial biomes and NCC fee simple and conservation agreement properties with the 1km grid

**Toolbox**

<img src="https://github.com/NCC-CNC/wtw-species-prep/blob/main/Doc/Imgs/toolbox.JPG" width="25%" height="25%">

---

### R scripts
- `rij_species.R` : generates RIJ sparse matrix of species and saves output as **.rds**
- `iucn_metadata.R` builds IUCN metadata csv
- `area_metadata.R` builds species metadata on total range/habitat and range/habitat that is currently protected

---

### Notes
⚠️  Repo does not come with input data
