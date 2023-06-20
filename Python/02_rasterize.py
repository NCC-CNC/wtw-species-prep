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
arcpy.env.pyramid = "PYRAMIDS 0" 

counter = 1
for layer in layers:
  desc = arcpy.Describe(layer)
  name = desc.name
  arcpy.AddMessage("Rasterizing: {} ({}/{})".format(name, counter, len(layers)))
  
  ## polygon to raster
  arcpy.conversion.PolygonToRaster(
    in_features = layer, 
    value_field = "Range_ha", 
    out_rasterdataset = "{}/T_ECCC_{}.tif".format(folder, name),
    cell_assignment = "CELL_CENTER",
    priority_field = "Range_ha",
    cellsize = 1000
  )
  
  ## advance counter
  counter += 1
