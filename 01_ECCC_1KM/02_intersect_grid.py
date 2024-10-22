#
# Authors: Dan Wismer
#
# Date: Oct 10th, 2024
#
# Description: Extracts ECCC "parsed" layer area to the 1km grid
#
# Inputs:  1. Parsed ECCC feature dataset
#          2. Output FGDB
#          3. Output TIFF folder
#          4. Snap raster (NCC 1km grid)
#
# Outputs: 1. A 1km gridded ECCC layer with area extracted.
#
#===============================================================================

import arcpy

# Get inputs
GRID = "C:/Data/PRZ/GRID1KM/NCC_1KM_IDX.shp"

arcpy.env.workspace = "C:/Data/NAT/ECCC/SAR/ECCC_SAR.gdb"
SAR_PARSED = arcpy.ListFeatureClasses(feature_dataset = "Parsed")
SAR_FGDB = "C:/Data/NAT/ECCC/SAR/ECCC_SAR.gdb/Grid"
SAR_TIFFS =  "C:/Data/NAT/ECCC/SAR/ECCC_SAR_1KM"

# arcpy.env.workspace = "C:/Data/NAT/ECCC/CH/ECCC_CH.gdb"
# CH_PARSED = arcpy.ListFeatureClasses(feature_dataset = "Parsed")
# CH_FGDB = "C:/Data/NAT/ECCC/CH/ECCC_CH.gdb/Grid"
# CH_TIFFS =  "C:/Data/NAT/ECCC/CH/ECCC_CH_1KM"

# Get environments
SNAP = "C:/Data/PRZ/NAT_DATA/NAT_1KM_20240729/_1km/const.tif"
arcpy.env.overwriteOutput = True

counter = 1
for layer in (SAR_PARSED):

  desc = arcpy.Describe(layer)
  name = desc.name
  source = name.split("_")[1]
  
  if source == "SAR":
    out_rasterdataset = "{}/T_NAT_{}.tif".format(SAR_TIFFS, name) 
    dataset_length = len(SAR_PARSED)
    fgdb = SAR_FGDB
  else:
    out_rasterdataset = "{}/T_NAT_{}.tif".format(CH_TIFFS, name) 
    dataset_length = len(CH_PARSED)
    fgdb = CH_FGDB
    
  print(out_rasterdataset)
  print("Processing: {} ({}/{})".format(name, counter, dataset_length))
  
  ## get area of layer
  km2 = 0
  with arcpy.da.SearchCursor(layer, ["SHAPE@AREA"]) as cursor:
      for row in cursor:
          km2 += round(row[0] / 1000000)
  arcpy.AddMessage("... Area: ~{} km2".format(format(km2, ",")))
          
  ## Go directly to rasterizing 
  if (km2 > 2000000):
    print("... BIG RANGE! can not get proportion")
    print("... Rasterizing using maximum combined area")
    
    ## new burn field, 100 ha
    arcpy.management.AddField(layer,"BURN","SHORT")
    with arcpy.da.UpdateCursor(layer, ["BURN"]) as cursor:
        for row in cursor:
          row[0] = 100
          cursor.updateRow(row) 

    # Set environments
    arcpy.env.snapRaster = SNAP
    arcpy.env.extent = SNAP
  
    # Rasterize
    arcpy.conversion.PolygonToRaster(
      in_features = layer, 
      value_field = "BURN", 
      out_rasterdataset = out_rasterdataset,
      cell_assignment = "MAXIMUM_COMBINED_AREA",
      priority_field = "Range_ha",
      cellsize = 1000,
      build_rat = "DO_NOT_BUILD"
  )
  
  else:
  
    ## select by location
    print("... Select by location")
    x = arcpy.management.SelectLayerByLocation(GRID, "INTERSECT", layer)
    ## export
    print("... Exporting feature")
    ncc = arcpy.conversion.ExportFeatures(x, "{}/{}_X".format(fgdb, name))
    
    ## intersect 
    x_ncc = arcpy.analysis.PairwiseIntersect([layer, ncc], "memory/int")
    
    # Build dictionary: HA
    print("... Building Range_ha field")
    ha = {}
    with arcpy.da.SearchCursor(x_ncc, ["NCCID", "SHAPE@AREA"]) as cursor:
        for row in cursor:
            id, area = row[0], row[1]
            if id not in ha:
                ha[id] = round(area / 10000) # round to 1ha
            else:
                ha[id] += round(area / 10000) # round to 1ha
                
    # Join HA dictionary to polygon attribute table 
    arcpy.management.AddField(ncc,"Range_ha","DOUBLE")
    with arcpy.da.UpdateCursor(ncc, ["NCCID", "Range_ha"]) as cursor:
        for row in cursor:
            id = row[0]
            if id in ha:
                row[1] = ha[id]
            else:
                row[1] = 0
            cursor.updateRow(row)  
    
    # Km2 field
    print("... Building Range_km2 field")
    arcpy.management.AddField(ncc,"Range_km2","DOUBLE")
    with arcpy.da.UpdateCursor(ncc, ["Range_ha", "Range_km2"]) as cursor:
        for row in cursor:
          row[1] = row[0] / 100
          cursor.updateRow(row) 
        
  # Advance counter
  counter += 1
 
