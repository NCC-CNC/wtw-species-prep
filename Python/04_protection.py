#
# Authors: Dan Wismer
#
# Date: July 17th, 2023
#
# Description: Extracts protected area to each species 
#
# Inputs:  1. ECCC source (range maps or ciritcal habitat)
#          2. CPCAD
#          3. NCC Achievments
#
#
# Outputs: 1. ECCC with populated RANGE_HA and PROTECTION_HA fields
#
#===============================================================================

import arcpy

# Get user input
eccc = arcpy.GetParameterAsText(0)
source = arcpy.GetParameterAsText(1)
cosewic_field = arcpy.GetParameterAsText(2)
sara_field = arcpy.GetParameterAsText(3)
sci_field = arcpy.GetParameterAsText(4)
com_field = arcpy.GetParameterAsText(5)
cpcad = arcpy.GetParameterAsText(6)
ncc = arcpy.GetParameterAsText(7)
prop_field = arcpy.GetParameterAsText(8)
prepped_parks = arcpy.GetParameterAsText(9)
fgdb = "Data/Output/Conserved/Conserved.gdb"
crs = arcpy.Describe(ncc).spatialReference

## STEP 1: PREP PROTECTED AREAS ------------------------------------------------

if prepped_parks:
  
  # SKIP STEP 1
  m = prepped_parks
  
else:  

  # Select and export filtered NCC layer
  arcpy.AddMessage("Selecting: NCC fee simple + conservation agreements properties")
  ncc_lyr = arcpy.MakeFeatureLayer_management(ncc, "ncc_lyr")
  where = "{} LIKE 'Fee Simple%' OR {} LIKE 'Conservation Agreement%'".format(prop_field, prop_field)
  x = arcpy.management.SelectLayerByAttribute(ncc, "NEW_SELECTION", where)
  ncc = arcpy.conversion.ExportFeatures(x, "{}/NCC_FS_CA".format(fgdb))
  
  # Project CPCAD
  arcpy.AddMessage("Projecting: CPCAD to Canada_Albers_WGS_1984")
  cpcad = arcpy.Project_management(cpcad, "{}/CPCAD_PRJ".format(fgdb), crs)
  
  # Select by attribute: CPCAD
  arcpy.AddMessage("Selecting: CPCAD terrestrial biomes")
  cpcad_lyr = arcpy.MakeFeatureLayer_management(cpcad, "cpcad_lyr")
  where = "BIOME = 'T'"
  cpcad_b = arcpy.management.SelectLayerByAttribute(cpcad_lyr, "NEW_SELECTION", where)
  
  # Erase
  arcpy.AddMessage("Erasing: NCC from CPCAD")
  e = arcpy.analysis.PairwiseErase(cpcad_b, ncc, "memory/e")
  
  # Dissolve
  arcpy.AddMessage("Dissolving: CPCAD")
  d = arcpy.analysis.PairwiseDissolve(
    in_features = e, 
    out_feature_class= "memory/d",
    multi_part = "SINGLE_PART"
  )
  
  # Merge
  arcpy.AddMessage("Merging: NCC with CPCAD")
  m = arcpy.management.Merge([d, ncc], "{}/PREPPED_PARKS".format(fgdb))
  
  # Delete projection feature
  arcpy.management.Delete("{}/CPCAD_PRJ".format(source))

## STEP 2: PREP ECCC -----------------------------------------------------------

# Project
arcpy.AddMessage("Projecting: ECCC to Canada_Albers_WGS_1984")
p = arcpy.Project_management(eccc, "{}/{}_PRJ".format(fgdb, source), crs)

# Dissolve
arcpy.AddMessage("Dissolving: ECCC by {}".format(cosewic_field))
eccc_dis = arcpy.analysis.PairwiseDissolve(
  in_features = p, 
  out_feature_class = "{}/{}_PROTECTED".format(fgdb, source), 
  dissolve_field = [cosewic_field, sara_field, sci_field, com_field]
)

# Delete projection feature
arcpy.management.Delete("{}/{}_PRJ".format(fgdb, source))

# Get Area Ha
arcpy.management.AddField(eccc_dis,"RANGE_HA","DOUBLE")
with arcpy.da.UpdateCursor(eccc_dis, ["RANGE_HA", "SHAPE@AREA"]) as cursor:
    for row in cursor:
      row[0] = round((row[1] / 10000), 2)
      cursor.updateRow(row)

# Add PROTECTION_HA Field (to be populated later)
arcpy.management.AddField(eccc_dis,"PROTECTION_HA","DOUBLE")

## STEP 3: Extract protection HA -----------------------------------------------

# Intersect
arcpy.AddMessage("Intersecting: Prepped protected with prepped ECCC")
i =  arcpy.analysis.PairwiseIntersect([eccc_dis, m], "memory/i")

# Build dictionary: HA
arcpy.AddMessage("... extract overlap area")
ha = {}
with arcpy.da.SearchCursor(i, [cosewic_field, "SHAPE@AREA"]) as cursor:
    for row in cursor:
        id, area = row[0], row[1]
        if id not in ha:
            ha[id] = round((area / 10000), 2) 
        else:
            ha[id] += round((area / 10000), 2)


# Join HA dictionary to ECCC
with arcpy.da.UpdateCursor(eccc_dis, [cosewic_field, "PROTECTION_HA"]) as cursor:
    for row in cursor:
        id = row[0]
        if id in ha:
            row[1] = ha[id]
        else:
            row[1] = 0
        cursor.updateRow(row) 
