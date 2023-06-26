# wtw-species-prep
### This repo hosts arcpy script tools for ArcPro that:
- Parses [Species at Risk Range Map Extents](https://open.canada.ca/data/en/dataset/d00f8e8c-40c4-435a-b790-980339ce3121) and [Critical Habitat Area](https://open.canada.ca/data/en/dataset/47caa405-be2b-4e9e-8f53-c478ade2ca74) by COSEWICID
- Extracts parsed area that intersect with the 1km vector grid
- Rasterizes the extractions by area (ha)
<p> 
   <img src="https://github.com/NCC-CNC/wtw-species-prep/blob/main/Doc/Imgs/00_parse_eccc.jpg" width="28%" height="28%">
   <img src="https://github.com/NCC-CNC/wtw-species-prep/blob/main/Doc/Imgs/01_intersect_grid.jpg" width="28%" height="28%">
   <img src="https://github.com/NCC-CNC/wtw-species-prep/blob/main/Doc/Imgs/02_rasterize.jpg" width="28%" height="28%">
</p> 

#### A R script is provided to generate the final RIJ species matrix needed for [wtw-data-prep](https://github.com/NCC-CNC/wtw-data-prep)

:triangular_flag_on_post: More to come in this repo ... 
