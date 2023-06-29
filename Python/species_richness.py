#
# Authors: Dan Wismer
#
# Date: June 28th, 2023
#
# Description: Generates species richness with option to subset by threat level. 
#              ie. a) sums up total area and b) sums up count 
#     
# Inputs:  1. Species rasters
#          2. Source name
#          3. Threat level
#          4. output FDGB
#
# Outputs: 1. Cumulative area ha raster
#          2. Count of species that intersect raster
#
#===============================================================================

import arcpy
from arcpy.sa import *

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

# Get user input
species = arcpy.GetParameterAsText(0).split(";")
folder = arcpy.GetParameterAsText(1)
source = arcpy.GetParameterAsText(2)
threat = arcpy.GetParameterAsText(3)

# Set threat code and wildcard
arcpy.AddMessage("Threat: {}".format(threat))
if threat != "All":
  threat = get_sara_status(threat)
  wildcard = "*{}*".format(threat)
else: 
  threat = "ALL"
  wildcard = "*"

# Get list of species .tifs if folder is provided
if folder:
  arcpy.env.workspace = folder
  species = arcpy.ListRasters(wildcard, "TIF")
  
# Mosaic - sum
arcpy.AddMessage(" ... Generating cumulative area. N = {}" .format(len(species)))
arcpy.MosaicToNewRaster_management(
  input_rasters = species,
  output_location = "Data/Output/Richness",
  raster_dataset_name_with_extension = "{}_{}_HA_SUM.tif".format(source, threat),
  pixel_type = "16_BIT_UNSIGNED",
  number_of_bands = 1,
  mosaic_method = "SUM"
)

# Reclass
arcpy.AddMessage("... Prepping rasters")
species_count = []
counter = 1
for x in species:
  arcpy.AddMessage("   ... {} ({}/{})".format(x, counter, len(species)))
  binary = Con(x, 1)
  species_count.append(binary)
  counter += 1
  
# Mosaic - count
arcpy.AddMessage("... Generating species count" .format(len(species)))
arcpy.MosaicToNewRaster_management(
  input_rasters = species_count, 
  output_location = "Data/Output/Richness", 
  raster_dataset_name_with_extension = "{}_{}_N.tif".format(source, threat),
  pixel_type = "16_BIT_UNSIGNED",
  number_of_bands = 1,
  mosaic_method = "SUM"
)
