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

# Get user input
grid = arcpy.GetParameterAsText(0)
layers = arcpy.GetParameterAsText(1).split(";")
fgdb = arcpy.GetParameterAsText(2)

counter = 1
for layer in layers:
  desc = arcpy.Describe(layer)
  name = desc.name
  arcpy.AddMessage("Processing: {} ({}/{})".format(name, counter, len(layers)))

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
              ha[id] = round(area / 10000, 4)
          else:
              ha[id] += round(area / 10000, 4)
              
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
 
