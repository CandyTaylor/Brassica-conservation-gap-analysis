### Example of input required to run cgamap function ###

# set workding directory
setwd("PATH/TO/INPUT/DIRECTORY")

# load original ecoregions dataset downloaded from https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/WTLNRG
ecos <- shapefile("./terrestrial-ecoregions-TNC/tnc_terr_ecoregions.shp") |>
  sf::st_as_sf()

# load protected areas dataset 
pros <- rast("./wdpa_rasterized_all.tif") |>
  terra::project(ecos)
# note: make sure your sdm and protected areas rasters have the same resolution.
# use the terra::disagg() function if needed. 

# load occurrence data
occData <- read.csv("OccurrenceData.csv")

# load original sdm raster
sdm <- raster("./TaxonName_optimal_model_prediction.asc") |> 
  terra::rast()

# load binary (i.e. thresholded) sdm raster used for gap analysis 
sdm_thresh <- raster("./TaxonName_BINARY_AVthresh.asc") |>
  terra::rast()

# source the cgamap function 
source("./InteractiveMap.R")

# run the function
mymap <- cgamap(taxon = "Taxon Name", 
                sdm = sdm, 
                sdm_thresh = sdm_thresh, 
                occurrenceData = occData, 
                protectedAreas = pros, 
                ecoregions = ecos, 
                idColumn = "ECO_NAME", 
                outputDir = "./PATH/TO/OUTPUT/DIRECTORY")
