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
folder = arcpy.GetParameterAsText(2)

# Set environments
arcpy.env.snapRaster = grid
arcpy.env.extent = grid

counter = 1
for layer in layers:
  desc = arcpy.Describe(layer)
  name = desc.name
  
  ## select vector cells > 
  lyr = arcpy.MakeFeatureLayer_management(layer, "lyr")
  where = "Range_ha > 0"
  x = arcpy.management.SelectLayerByAttribute(lyr, "NEW_SELECTION", where)  
  
  ## polygon to raster
  arcpy.AddMessage("Rasterizing: {} ({}/{})".format(name, counter, len(layers)))
  arcpy.conversion.PolygonToRaster(
    in_features = x, 
    value_field = "Range_ha", 
    out_rasterdataset = "{}/T_ECCC_{}.tif".format(folder, name),
    cell_assignment = "CELL_CENTER",
    priority_field = "Range_ha",
    cellsize = 1000,
    build_rat = "DO_NOT_BUILD"
  )
  
  ## advance counter
  counter += 1
