#
# Authors: Dan Wismer
#
# Date: Oct 18th, 2023
#
# Description: Rasterize 1km gridded ECCC layers.
#
# Inputs:  1. ECCC gridded feature dataset
#          2. Output tiff folder
#          3. Snap raster (NCc 1km gird)
#
# Outputs: 1. An ECCC .tiff layer.
#
#===============================================================================

import arcpy

# Get inputs

arcpy.env.workspace = "C:/Data/NAT/ECCC/SAR/ECCC_SAR.gdb"
SAR_GRID = arcpy.ListFeatureClasses(feature_dataset = "Grid")
SAR_TIFFS =  "C:/Data/NAT/ECCC/SAR/ECCC_SAR_1KM"

# arcpy.env.workspace = "C:/Data/NAT/ECCC/CH/ECCC_CH.gdb"
# CH_GRID = arcpy.ListFeatureClasses(feature_dataset = "Grid")
# CH_TIFFS =  "C:/Data/NAT/ECCC/CH/ECCC_CH_1KM"

# Set environments
arcpy.env.snapRaster = "C:/Data/PRZ/NAT_DATA/NAT_1KM_20240729/_1km/const.tif"
arcpy.env.extent = "C:/Data/PRZ/NAT_DATA/NAT_1KM_20240729/_1km/const.tif"
arcpy.env.overwriteOutput = True

counter = 1
for layer in SAR_GRID:

  desc = arcpy.Describe(layer)
  name = desc.name
  source = name.split("_")[1]
  
  if source == "SAR":
    out_rasterdataset = "{}/T_NAT_{}.tif".format(SAR_TIFFS, name[:-2])
    dataset_length = len(SAR_GRID)
  else:
    out_rasterdataset = "{}/T_NAT_{}.tif".format(CH_TIFFS, name[:-2])
    dataset_length = len(CH_GRID)
  
  ## select vector cells > 
  lyr = arcpy.MakeFeatureLayer_management(layer, "lyr")
  where = "Range_ha > 0"
  x = arcpy.management.SelectLayerByAttribute(lyr, "NEW_SELECTION", where) 
  ## get record count
  record_count = arcpy.management.GetCount(x)[0]
  
  ## polygon to raster if there are records selected
  if int(record_count) > 0:
    print("Rasterizing: {} ({}/{})".format(name, counter, dataset_length))
    arcpy.conversion.PolygonToRaster(
      in_features = x, 
      value_field = "Range_ha", 
      out_rasterdataset = out_rasterdataset,
      cell_assignment = "CELL_CENTER",
      priority_field = "Range_ha",
      cellsize = 1000,
      build_rat = "DO_NOT_BUILD"
    )
  else:
    # This will happen becuase of rounding. Ex species: SAR_CH_END_COSEWIC_1007, SAR_CH_END_COSEWIC_951 
    arcpy.AddMessage("!!! LESS THEN 0.5 HA, ROUNDING TO 1 HA: {}".format(name))
    
    ## new burn field, 1 ha
    arcpy.management.AddField(layer,"BURN","SHORT")
    with arcpy.da.UpdateCursor(layer, ["BURN"]) as cursor:
        for row in cursor:
          row[0] = 1
          cursor.updateRow(row) 
    
    arcpy.conversion.PolygonToRaster(
      in_features = layer, 
      value_field = "BURN", 
      out_rasterdataset = out_rasterdataset,
      cell_assignment = "CELL_CENTER",
      priority_field = "NONE",
      cellsize = 1000,
      build_rat = "DO_NOT_BUILD"
    )    
    
  ## advance counter
  counter += 1
