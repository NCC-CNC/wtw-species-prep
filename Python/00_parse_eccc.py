#
# Authors: Dan Wismer
#
# Date: June 19th, 2023
#
# Description: Parses ECCC Critical Habitat / Species at Risk Range Map layers
#              by COSEWIC ID. 
#
# Inputs:  1. Source ECCC layer
#          2. field names
#          3. output projection
#          4. output FDGB
#
# Outputs: 1. a feature class for each unique COSEWIC ID. ex. CH_END_COSEWIC_2
#
#===============================================================================

import arcpy

# Unique values in field function
def get_unique_values(table, field):
    with arcpy.da.SearchCursor(table, [field]) as cursor:
        return sorted({row[0] for row in cursor})
      
# Sara status 
def get_sara_status(code):
  if code == 0:
    return "" # NULL
  elif code == 1 or code == "Extirpated":
    return "EXT" # extirpated
  elif code == 2 or code == "Endangered":
    return "END" # endangered
  elif code == 3 or code == "Threatened":
    return "THR" # threatened
  elif code == 4 or code == "Special Concern":
    return "SPC" # special concern
  elif code == 5 or code == "No Status":
    return "NOS" # no status
  elif code == 6 or code == "Not at Risk":
    return "NAR" # not at risk

# Get output prefix
def get_prefix(source):
  if source[0] == "C":
    return "CH"
  else:
    return "SAR"

# Get user input
eccc = arcpy.GetParameterAsText(0)
source = arcpy.GetParameterAsText(1)
cosewic_field = arcpy.GetParameterAsText(2)
sara_field = arcpy.GetParameterAsText(3)
sci_field = arcpy.GetParameterAsText(4)
com_field = arcpy.GetParameterAsText(5)
crs = arcpy.GetParameterAsText(6)
fgdb = arcpy.GetParameterAsText(7)

# Get prefix
prefix = get_prefix(source)

# Project to Canada Albers WGS 1984
arcpy.AddMessage("... Projecting: Canada_Albers_WGS_1984")
eccc = arcpy.Project_management(eccc, "{}/xECCC_{}_PRJx".format(fgdb, prefix), crs)

# Dissolve
arcpy.AddMessage("... Dissolving by: {}".format(cosewic_field, ))
output = "{}/ECCC_{}".format(fgdb,prefix)
dissolve_fields = [cosewic_field, sara_field, sci_field, com_field]
eccc_dis = arcpy.management.Dissolve(eccc, output, dissolve_fields)

# Add Range_ha and Range_km2 fields
arcpy.management.AddFields(eccc_dis, [["Range_ha", "DOUBLE"], ["Range_km2", "DOUBLE"]])

# Calculate area
arcpy.AddMessage("... Calculating Area HA and KM2")
arcpy.management.CalculateGeometryAttributes(eccc_dis, [["Range_ha", "AREA"]], "#", "HECTARES")
arcpy.management.CalculateGeometryAttributes(eccc_dis, [["Range_km2", "AREA"]], "#", "SQUARE_KILOMETERS")

# Get unique species by COSEWIC ID
cwids = get_unique_values(eccc_dis, cosewic_field)
# Create feature layer
eccc_lyr = arcpy.MakeFeatureLayer_management(eccc_dis, "eccc_lyr")

# Parse out species ----
counter = 1
for cwid in cwids:
  arcpy.AddMessage("...    Parsing COSEWIC {} ({}/{})".format(cwid, counter, len(cwids)))

  ## select by attribute
  where = "{} = {}".format(cosewic_field, cwid)
  x = arcpy.management.SelectLayerByAttribute(eccc_lyr , "NEW_SELECTION", where)

  ## get SARA status
  with arcpy.da.SearchCursor(x, [sara_field]) as cursor:
    for row in cursor:
      sara = get_sara_status(row[0])
      break

  ## export
  output = output = "{}/{}_{}_COSEWIC_{}".format(fgdb, prefix, sara, cwid)
  arcpy.conversion.ExportFeatures(x, output)

  ## advance counter
  counter += 1
  
