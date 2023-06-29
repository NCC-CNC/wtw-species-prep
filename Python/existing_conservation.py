#
# Authors: Dan Wismer
#
# Date: June 26th, 2023
#
# Description: Generates WTW include layer using CPCAD terrestrial biomes and 
#              NCC fee simpple and conservation agreement properties. 
#
# Inputs:  1. NCC 1km vector grid
#          2. CPCAD layer
#          3. NCC accomplishments layer
#          4. Property field (from NCC layer)
#          5. Output FGDB
#
# Outputs: 1. Vector 1km include layer
#          2. Raster 1km include layer
#
# Estimated run time: 10-20 minutes
#===============================================================================

import arcpy
from arcpy import env
from arcpy.sa import *
import os 

# Get user input
grid = arcpy.GetParameterAsText(0)
cpcad = arcpy.GetParameterAsText(1)
ncc = arcpy.GetParameterAsText(2)
prop_field = arcpy.GetParameterAsText(3) # " FIRST_PCL_"
fgdb = arcpy.GetParameterAsText(4)

# Get script path and set snap raster
script_dir = os.path.dirname(os.path.abspath(__file__))
parent_dir = os.path.dirname(script_dir)
snap = "{}/Data/Input/NCC/Constant_1KM_IDX.tif".format(parent_dir)

# Select and export filtered NCC layer
arcpy.AddMessage("... Selecting fee simple + conservation agreements properties")
ncc_lyr = arcpy.MakeFeatureLayer_management(ncc, "ncc_lyr")
where = "{} LIKE 'Fee Simple%' OR {} LIKE 'Conservation Agreement%'".format(prop_field, prop_field)
x = arcpy.management.SelectLayerByAttribute(ncc, "NEW_SELECTION", where)
ncc = arcpy.conversion.ExportFeatures(x, "{}/NCC_FS_CA".format(fgdb))

# Project CPCAD
arcpy.AddMessage("... Projecting CPCAD to Canada_Albers_WGS_1984")
crs = arcpy.Describe(ncc).spatialReference
cpcad = arcpy.Project_management(cpcad, "{}/CPCAD_PRJ".format(fgdb), crs)

# Create feature layer
cpcad_lyr = arcpy.MakeFeatureLayer_management(cpcad, "cpcad_lyr")

# Select by attribute: CPCAD
where = "BIOME = 'T'"
arcpy.AddMessage("... CPCAD, Select by attribute: {}".format(where))
x = arcpy.management.SelectLayerByAttribute(cpcad_lyr, "NEW_SELECTION", where)

# Merg (has overlap)
arcpy.AddMessage("... Merging CPCAD and NCC")
m = arcpy.management.Merge([x, ncc], "memory/m")

# A FASTER APPROACH TO SELECT BY LOCATION? (I tried this approach for fun)------
# Add new burn field
arcpy.management.AddField(m, "BURN", "SHORT")
with arcpy.da.UpdateCursor(m, ["BURN"]) as cursor:
    for row in cursor:
      row[0] = 1
      cursor.updateRow(row)

# Rasterize
arcpy.AddMessage("... Rasterizing CPCAD+NCC: maximum combied area")
# Set environments
arcpy.env.snapRaster = snap
# Rasterize
r = arcpy.conversion.PolygonToRaster(
  in_features = m,
  value_field = "BURN",
  out_rasterdataset = "memory/r1.tif",
  cell_assignment = "MAXIMUM_COMBINED_AREA",
  priority_field = "BURN",
  cellsize = 1000,
  build_rat = "DO_NOT_BUILD"
)

# Assign PUID to raster
r_idx = Con(r, snap)
r_idx.save("{}/r_idx.tif".format(os.path.dirname(fgdb)))

# Raster to point
arcpy.AddMessage("... Raster to point")
p = arcpy.conversion.RasterToPoint (
  in_raster = r_idx,
  out_point_features = "memory/p".format(fgdb)
)

# Buffer points by 500m
arcpy.AddMessage("... Buffer points by 500m")
b = arcpy.analysis.Buffer(p, "memory/b", 500)

# Create 1km grid from buffer points
arcpy.AddMessage("... Build 1km grid")
parks_1km = arcpy.MinimumBoundingGeometry_management(
  in_features = b,
  out_feature_class = "{}/Existing_Conservation".format(fgdb),
  geometry_type = "ENVELOPE"
)

# ------------------------------------------------------------------------------

# Intersection to create gridded includes
arcpy.AddMessage("... Intersecting to grid")
x_parks = arcpy.analysis.PairwiseIntersect([m, parks_1km], "memory/i")

# Disolve by grid_code
arcpy.AddMessage("... Dissolving by planning unit")
x_parks_d = arcpy.analysis.PairwiseDissolve(x_parks, "memory/d", ["grid_code"])
 
# Build dictionary: HA
arcpy.AddMessage("... Building Range_ha field")
ha = {}
with arcpy.da.SearchCursor(x_parks_d, ["grid_code", "SHAPE@AREA"]) as cursor:
    for row in cursor:
        id, area = row[0], row[1]
        if id not in ha:
            ha[id] = round(area / 10000) # round to 1ha
        else:
            ha[id] += round(area / 10000) # round to 1ha
            
# Join HA dictionary to gridded includes attribute table 
arcpy.management.AddField(parks_1km,"Range_ha","DOUBLE")
with arcpy.da.UpdateCursor(parks_1km, ["grid_code", "Range_ha"]) as cursor:
    for row in cursor:
        id = row[0]
        if id in ha:
            row[1] = ha[id]
        else:
            row[1] = 0
        cursor.updateRow(row)  

# Km2 field
arcpy.AddMessage("... Building Range_km2 field")
arcpy.management.AddField(parks_1km,"Range_km2","DOUBLE")
with arcpy.da.UpdateCursor(parks_1km, ["Range_ha", "Range_km2"]) as cursor:
    for row in cursor:
      row[1] = row[0] / 100
      cursor.updateRow(row)
      
# Defining cut-off
threshold = 50 # <--- CHANGE???
arcpy.AddMessage("... Defining cut-off at {} ha".format(threshold))
arcpy.management.AddField(parks_1km,"Include","DOUBLE")
with arcpy.da.UpdateCursor(parks_1km, ["Include", "Range_ha"]) as cursor:
    for row in cursor:
      if row[1] >= threshold:
        row[0] = 1
      else:
        row[0] = 0
      cursor.updateRow(row)  
      
# Select includes
parks_1km_lyr = arcpy.MakeFeatureLayer_management(parks_1km, "parks_1km_lyr")

# Select by attribute
arcpy.AddMessage("... Selecting Rage_ha > 0")
where = "Range_ha > 0"
x = arcpy.management.SelectLayerByAttribute(parks_1km_lyr , "NEW_SELECTION", where)

# Rasterize includes as a continuous output
arcpy.AddMessage("... Raterizing existing conservation")
arcpy.env.extent = snap # set extent
arcpy.conversion.PolygonToRaster(
  in_features = x, 
  value_field = "Range_ha", 
  out_rasterdataset = "{}/Existing_Conservation_ha.tif".format(os.path.dirname(fgdb)),
  cell_assignment = "CELL_CENTER",
  priority_field = "Range_ha",
  cellsize = 1000,
  build_rat = "DO_NOT_BUILD"
)   

# Select by attribute
arcpy.AddMessage("... Selecting includes")
where = "Include = 1"
x = arcpy.management.SelectLayerByAttribute(parks_1km_lyr , "NEW_SELECTION", where)

# Rasterize includes as binary output
arcpy.AddMessage("... Raterizing includes")
arcpy.conversion.PolygonToRaster(
  in_features = x, 
  value_field = "Include", 
  out_rasterdataset = "{}/Existing_Conservation.tif".format(os.path.dirname(fgdb)),
  cell_assignment = "CELL_CENTER",
  priority_field = "Include",
  cellsize = 1000,
  build_rat = "DO_NOT_BUILD"
)
