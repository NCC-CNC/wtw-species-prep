#
# Authors: Dan Wismer
#
# Date: June 19th, 2023
#
# Description: Extracts ECCC "intermediate" layer area to the 1km grid
#
# Inputs:  1. NCC 1km vector grid
#          2. ECCC "intermediate" layers
#          3. Output FDGB
#
# Outputs: 1. A 1km gridded ECCC layer with area extracted.
#
#===============================================================================

import arcpy
import os

# Get user input
grid = arcpy.GetParameterAsText(0)
layers = arcpy.GetParameterAsText(1).split(";")
fgdb = arcpy.GetParameterAsText(2)

# Get script path
script_dir = os.path.dirname(os.path.abspath(__file__))
parent_dir = os.path.dirname(script_dir)
snap = "{}/Data/Input/NCC/Constant_1KM.tif".format(parent_dir)

counter = 1
for layer in layers:
  desc = arcpy.Describe(layer)
  name = desc.name
  arcpy.AddMessage("Processing: {} ({}/{})".format(name, counter, len(layers)))
  
  ## get area of layer
  km2 = 0
  with arcpy.da.SearchCursor(layer, ["SHAPE@AREA"]) as cursor:
      for row in cursor:
          km2 += round(row[0] / 1000000)
  arcpy.AddMessage("... Area: ~{} km2".format(format(km2, ",")))
          
  ## Go directly to rasterizing 
  if (km2 > 2000000):
    arcpy.AddMessage("... BIG RANGE! can not get proportion")
    arcpy.AddMessage("... Rasterizing using maximum combined area")
    
    ## new burn field, 100 ha
    arcpy.management.AddField(layer,"BURN","SHORT")
    with arcpy.da.UpdateCursor(layer, ["BURN"]) as cursor:
        for row in cursor:
          row[0] = 100
          cursor.updateRow(row) 

    # Set environments
    arcpy.env.snapRaster = snap
    arcpy.env.extent = snap
    # Rasterize
    arcpy.conversion.PolygonToRaster(
      in_features = layer, 
      value_field = "BURN", 
      out_rasterdataset = "{}/T_ECCC_{}.tif".format(os.path.dirname(fgdb), name),
      cell_assignment = "MAXIMUM_COMBINED_AREA",
      priority_field = "Range_ha",
      cellsize = 1000,
      build_rat = "DO_NOT_BUILD"
  )
  
  else:
  
    ## select by location
    arcpy.AddMessage("... Select by location")
    x = arcpy.management.SelectLayerByLocation(grid, "INTERSECT", layer)
    
    ## export
    arcpy.AddMessage("... Exporting feature")
    ncc = arcpy.conversion.ExportFeatures(x, "{}/{}".format(fgdb, name))
    
    ## intersect 
    x_ncc = arcpy.analysis.Intersect([layer, ncc], "memory/int")
    
    # Build dictionary: HA
    arcpy.AddMessage("... Building Range_ha field")
    ha = {}
    with arcpy.da.SearchCursor(x_ncc, ["gridcode", "SHAPE@AREA"]) as cursor:
        for row in cursor:
            id, area = row[0], row[1]
            if id not in ha:
                ha[id] = round(area / 10000) # round to 1ha
            else:
                ha[id] += round(area / 10000) # round to 1ha
                
    # Join HA dictionary to polygon attribute table 
    arcpy.management.AddField(ncc,"Range_ha","DOUBLE")
    with arcpy.da.UpdateCursor(ncc, ["gridcode", "Range_ha"]) as cursor:
        for row in cursor:
            id = row[0]
            if id in ha:
                row[1] = ha[id]
            else:
                row[1] = 0
            cursor.updateRow(row)  
    
    # Km2 field
    arcpy.AddMessage("... Building Range_km2 field")
    arcpy.management.AddField(ncc,"Range_km2","DOUBLE")
    with arcpy.da.UpdateCursor(ncc, ["Range_ha", "Range_km2"]) as cursor:
        for row in cursor:
          row[1] = row[0] / 100
          cursor.updateRow(row) 
        
  # Advance counter
  counter += 1
 
