#
# Authors: Dan Wismer
#
# Date: June 20th, 2023
#
# Description: Rasterize 1km gridded ECCC layers.
#
# Inputs:  1. NCC 1km raster grid
#          2. ECCC gridded layers
#          3. Output folder
#
# Outputs: 1. An ECCC .tiff layer.
#
#===============================================================================

import arcpy

# Get user input
grid = arcpy.GetParameterAsText(0)
layers = arcpy.GetParameterAsText(1).split(";")
fgdb = arcpy.GetParameterAsText(2)
folder = arcpy.GetParameterAsText(3)

# Set environments
arcpy.env.snapRaster = grid
arcpy.env.extent = grid

# List layers if fgdb is provided
if fgdb:
  arcpy.env.workspace = fgdb
  layers = arcpy.ListFeatureClasses(wild_card = "*COSEWIC*")

counter = 1
for layer in layers:
  desc = arcpy.Describe(layer)
  name = desc.name
  
  ## select vector cells > 
  lyr = arcpy.MakeFeatureLayer_management(layer, "lyr")
  where = "Range_ha > 0"
  x = arcpy.management.SelectLayerByAttribute(lyr, "NEW_SELECTION", where) 
  ## get record count
  record_count = arcpy.management.GetCount(x)[0]
  
  ## polygon to raster if there are records selected
  if int(record_count) > 0:
    arcpy.AddMessage("Rasterizing: {} ({}/{})".format(name, counter, len(layers)))
    arcpy.conversion.PolygonToRaster(
      in_features = x, 
      value_field = "Range_ha", 
      out_rasterdataset = "{}/T_NAT_ECCC_{}.tif".format(folder, name),
      cell_assignment = "CELL_CENTER",
      priority_field = "Range_ha",
      cellsize = 1000,
      build_rat = "DO_NOT_BUILD"
    )
  else:
    # This will happen becuase of rounding. Ex species: CH_END_COSEWIC_1007
    arcpy.AddMessage("!!! LESS THEN 0.5 HA, ROUNDING TO 1 HA: {}".format(name))
    arcpy.conversion.PolygonToRaster(
      in_features = layer, 
      value_field = "OBJECTID", 
      out_rasterdataset = "{}/T_NAT_ECCC_{}.tif".format(folder, name),
      cell_assignment = "CELL_CENTER",
      priority_field = "NONE",
      cellsize = 1000,
      build_rat = "DO_NOT_BUILD"
    )    
    
  ## advance counter
  counter += 1
