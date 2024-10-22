#
# Authors: Dan Wismer
#
# Date: Oct 10th, 2024
#
# Description: Parses ECCC Critical Habitat / Species at Risk Range Map layers
#              by COSEWIC ID. 
#
# Inputs:  1. Source ECCC layer
#          2. COSEWIC field name
#          3. SARA field name
#          4. Scientrific field name
#          5. Common field name
#          6. Output FGDB
#
# Outputs: 1. a feature class for each unique COSEWIC ID. ex. CH_END_COSEWIC_2
#
#===============================================================================

import arcpy

# User defined functions -------------------------------------------------------

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

# ------------------------------------------------------------------------------

# Get input
## ECCC Species at Risk Range Map Extents:
## https://data-donnees.az.ec.gc.ca/data/species/protectrestore/range-map-extents-species-at-risk-canada
ECCC_SAR = "C:/Data/NAT/ECCC/SAR/Species at Risk Range Map Extents.gdb/SpeciesAtRiskRangeMapExtents"
SAR_COSEWIC = "COSEWICID"
SAR_SARA = "SAR_STAT_E"
SAR_SCI = "SCI_NAME"
SAR_COM = "COM_NAME_E"
SAR_FGDB = "C:/Data/NAT/ECCC/SAR/ECCC_SAR.gdb"

## ECCC Critical Habitat
## https://open.canada.ca/data/en/dataset/47caa405-be2b-4e9e-8f53-c478ade2ca74
ECCC_CH = "C:/Data/NAT/ECCC/CH/CriticalHabitat.gdb/CriticalHabitatArea"
CH_COSEWIC = "COSEWIC_ID"
CH_SARA = "SARA_Status"
CH_SCI = "SciName"
CH_COM = "CommName_E"
CH_FGDB = "C:/Data/NAT/ECCC/CH/ECCC_CH.gdb"

# Get environments
## cordinate reference system
CRS = arcpy.Describe("C:/Data/PRZ/GRID1KM/NCC_1KM_PU.shp").spatialReference
arcpy.env.overwriteOutput = True

# Project to Canada Albers WGS 1984
print("... Projecting: Canada_Albers_WGS_1984")
sar = arcpy.Project_management(ECCC_SAR, "{}/ECCC_SAR_ALBERS".format(SAR_FGDB), CRS)
ch = arcpy.Project_management(ECCC_CH, "{}/ECCC_CH_ALBERS".format(CH_FGDB), CRS)

# Dissolve
print("... Dissolving by: COSEWIC, SARA, English and Sci Name Field")
sar_dis = arcpy.management.Dissolve(
  in_features = sar, 
  out_feature_class = "{}/ECCC_SAR_DISSOLVED".format(SAR_FGDB), 
  dissolve_field = [SAR_COSEWIC, SAR_SARA, SAR_SCI, SAR_COM]
)

ch_dis = arcpy.management.Dissolve(
  in_features = ch, 
  out_feature_class = "{}/ECCC_CH_DISSOLVED".format(CH_FGDB), 
  dissolve_field = [CH_COSEWIC, CH_SCI, CH_COM],
  statistics_fields = [[CH_SARA, "MIN"]],  # Needed for COSEWIC-846, Blanding's Turtle and COSEWIC-846 Massasuga
)
arcpy.management.AlterField(ch_dis, 'MIN_SARA_Status', CH_SARA, CH_SARA)

# Add Range_ha and Range_km2 fields
arcpy.management.AddFields(sar_dis, [["Range_ha", "DOUBLE"], ["Range_km2", "DOUBLE"]])
arcpy.management.AddFields(ch_dis, [["Range_ha", "DOUBLE"], ["Range_km2", "DOUBLE"]])

# Calculate area
arcpy.AddMessage("... Calculating Area HA and KM2")
arcpy.management.CalculateGeometryAttributes(sar_dis, [["Range_ha", "AREA"]], "#", "HECTARES")
arcpy.management.CalculateGeometryAttributes(sar_dis, [["Range_km2", "AREA"]], "#", "SQUARE_KILOMETERS")

arcpy.management.CalculateGeometryAttributes(ch_dis, [["Range_ha", "AREA"]], "#", "HECTARES")
arcpy.management.CalculateGeometryAttributes(ch_dis, [["Range_km2", "AREA"]], "#", "SQUARE_KILOMETERS")


# Get unique species by COSEWIC ID
sar_cids = get_unique_values(sar_dis, SAR_COSEWIC)
ch_cids = get_unique_values(ch_dis, CH_COSEWIC)

# Create feature layer
sar_lyr = arcpy.MakeFeatureLayer_management(sar_dis, "sar_lyr")
ch_lyr = arcpy.MakeFeatureLayer_management(ch_dis, "ch_lyr")

# Parse out SAR species --------------------------------------------------------
counter = 1
for cid in sar_cids:
  print("...    Parsing ECCC SAR COSEWIC {} ({}/{})".format(cid, counter, len(sar_cids)))

  ## select by attribute
  where = "{} = {}".format(SAR_COSEWIC, cid)
  x = arcpy.management.SelectLayerByAttribute(sar_lyr , "NEW_SELECTION", where)

  ## get SARA status
  with arcpy.da.SearchCursor(x, [SAR_SARA]) as cursor:
    for row in cursor:
      sara = get_sara_status(row[0])
      break

  ## export
  output = output = "{}/Parsed/ECCC_SAR_{}_COSEWIC_{}".format(SAR_FGDB, sara, cid)
  arcpy.conversion.ExportFeatures(x, output)

  ## advance counter
  counter += 1
  
# Parse out CH species ---------------------------------------------------------
counter = 1
for cid in ch_cids:
  print("...    Parsing ECCC CH COSEWIC {} ({}/{})".format(cid, counter, len(ch_cids)))

  ## select by attribute
  where = "{} = {}".format(CH_COSEWIC, cid)
  x = arcpy.management.SelectLayerByAttribute(ch_lyr , "NEW_SELECTION", where)

  ## get SARA status
  with arcpy.da.SearchCursor(x, [CH_SARA]) as cursor:
    for row in cursor:
      sara = get_sara_status(row[0])
      break

  ## export
  output = output = "{}/Parsed/ECCC_CH_SAR_{}_COSEWIC_{}".format(CH_FGDB, sara, cid)
  arcpy.conversion.ExportFeatures(x, output)

  ## advance counter
  counter += 1

# Merge parsed layers
print("Merge parsed SAR")
arcpy.env.workspace = "C:/Data/NAT/ECCC/SAR/ECCC_SAR.gdb"
sar_parsed = arcpy.ListFeatureClasses(feature_dataset = "Parsed")
arcpy.management.Merge(sar_parsed, "{}/ECCC_SAR".format(SAR_FGDB))

# Merge parsed layers
print("Merge parsed CH")
arcpy.env.workspace = "C:/Data/NAT/ECCC/CH/ECCC_CH.gdb"
ch_parsed = arcpy.ListFeatureClasses(feature_dataset = "Parsed")
arcpy.management.Merge(ch_parsed, "{}/ECCC_CH".format(CH_FGDB))
