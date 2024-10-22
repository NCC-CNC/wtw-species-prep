#
# Authors: Dan Wismer
#
# Date: October 22nd, 2024
#
# Description: Intersects CPCAD + NCC FS and CA to ECCC SAR and CH layers
#
# Inputs:  1. ECCC SAR merged parsed layers
#          2. ECCC CH merged parsed layers
#          3. CPCAD + NCC existing conservation (includes-rollup)
#
#
# Outputs: 1. Populates Protection_Ha field on ECCC_SAR and ECCC_CH layers
#
#===============================================================================

import arcpy

# Get user input
SAR = "C:/Data/NAT/ECCC/SAR/ECCC_SAR.gdb/ECCC_SAR"
SAR_COSEWIC = "COSEWICID"

CH = "C:/Data/NAT/ECCC/CH/ECCC_CH.gdb/ECCC_CH"
CH_COSEWIC = "COSEWIC_ID"

# Includes:
# https://github.com/NCC-CNC/includes-rollup/blob/0815430ca1e35b6066392338a749718c648f72e7/includes_rollup.py#L61-L62
CPCAD_NCC = "C:/Data/NAT/CPCAD/Includes/Includes.gdb/CPCAD_NCC_FS_CA_DISSOLVED"

# Set environment
arcpy.env.overwriteOutput = True

# Intersect
for eccc, cosewic in zip([SAR, CH], [SAR_COSEWIC, CH_COSEWIC]):
  print(eccc)
  print(cosewic)
  
  print("Intersecting: ")
  i =  arcpy.analysis.PairwiseIntersect([eccc, CPCAD_NCC ], "memory/i")

# Build dictionary: HA
  print("... Extract overlap area")
  ha = {}
  with arcpy.da.SearchCursor(i, [str(cosewic), "SHAPE@AREA"]) as cursor:
      for row in cursor:
          id, area = row[0], row[1]
          if id not in ha:
              ha[id] = round((area / 10000), 2)
          else:
              ha[id] += round((area / 10000), 2)


  # Join HA dictionary to ECCC
  arcpy.management.AddField(eccc, "Protection_ha", "DOUBLE")
  with arcpy.da.UpdateCursor(eccc, [cosewic, "Protection_ha"]) as cursor:
      for row in cursor:
          id = row[0]
          if id in ha:
              row[1] = ha[id]
          else:
              row[1] = 0
          cursor.updateRow(row)
  
  # Delete in-memory objects
  arcpy.management.Delete(i)
