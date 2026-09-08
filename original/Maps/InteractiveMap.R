#' @title Interactive maps for conservation gap analysis (cga)
#' @name cgamap
#' @description The cgamap function creates a Leaflet map with several interactive layers that highlight various aspects of 
#' of the conservation gap analysis framework presented by Khoury et al. (2019) and executed using the GapAnalysis package  
#' from Carver et al. (2021). 
#' 
#' @param taxon A character object that defines the name of the species/taxon as listed in the occurrence dataset
#' @param sdm A terra::rast() object that represents the expected/modelled distribution of the species/taxon
#' @param sdm_thresh A terra::rast() object that represents a binary distribution of the species/taxon - in our case, we have
#' used the average habitat suitability score for thresholding.
#' @param occurrenceData A dataframe containing occurrence data records, including latitude and longitude, plus relevant metadata 
#' @param buffer A number specifying the width (in metres) of the buffer you wish to encompass around all G record points
#' @param protectedAreas A terra::rast() object that contains WDPA protected areas
#' @param ecoregions An sf object that contains terrestrial ecoregions
#' @param idColum A character object that defines which column of the ecoregions file to use for indexing - in our case, 
#' we have used "ECO_NAME"
#' @param outputDir A character object that defines the output directory to save the interactive map into  
#' 
#' @return An interactive leaflet map saved in html format
#'
#' @references
#' Khoury et al. (2019) Ecological Indicators 98:420-429. doi: 10.1016/j.ecolind.2018.11.016
#' Carver et al. (2021) GapAnalysis: an R package to calculate conservation indicators using spatial information


cgamap <- function(taxon, sdm, sdm_thresh, occurrenceData, protectedAreas, ecoregions, buffer, idColumn, outputDir) {

  ### install and load dependencies
  if (!require("pacman")) install.packages("pacman")
  pacman::p_load("terra", "dplyr", "sf","devtools", "raster", "leaflet", "sp", "htmlwidgets")
    
  ### make sure ecoregion dataset will be treated in planar form, not spherical - important for taxa with large distribution ranges
  sf_use_s2(FALSE)
  
  ### prepare the map features
  
  # crop protected areas to original sdm
  pro <- terra::crop(protectedAreas, sdm)
  # mask to model
  proMask <- pro * sdm
  
  # crop protected areas to thresholded sdm
  pro_thresh <- terra::crop(protectedAreas, sdm_thresh)
  # mask to model
  proMask_thresh <- pro_thresh * sdm_thresh
  
  # set id column for easier indexing of all ecoregions in original sdm 
  ecoregions$id_column <- as.data.frame(ecoregions)[,idColumn]
  
  # create polygon outline of sdm to crop ecoregions  
  sdm_poly <- terra::as.polygons(sdm, na.rm = TRUE, round = TRUE) |>
    fillHoles() |>
    st_as_sf() |>
    st_union(by_feature = FALSE)
  # clip ecoregions to sdm
  eco <- st_intersection(ecoregions, sdm_poly)
  # make into spatvector again
  eco <- terra::vect(eco)

  # get all ecoregions in original sdm
  eco$totEco <- terra::zonal(x = sdm, z = eco, fun = "sum",na.rm=TRUE) |> dplyr::pull()
  selectedEcos <- eco[eco$totEco > 0 , ]
  
  # get all ecoregions in thresholded sdm
  eco$totEco_thresh <- terra::zonal(x = sdm_thresh, z = eco, fun = "sum",na.rm=TRUE) |> dplyr::pull()
  selectedEcos_thresh <- eco[eco$totEco_thresh > 0 , ]

  # get all ecoregions in protected areas of thresholded sdm
  eco$totPro <- terra::zonal(x = proMask_thresh , z = eco, fun = "sum",na.rm=TRUE) |> dplyr::pull()
  protectedEcos <- eco[eco$totPro > 0 , ]
  # get unrepresented ecoregions in protected areas
  missingEcosInsitu <- selectedEcos_thresh[!selectedEcos_thresh$id_column %in% protectedEcos$id_column, ]
  
  # create buffer around occurrence points
  occ <- occurrenceData |>
    dplyr::filter(Taxon == taxon & Type == "G_Active") |>
    terra::vect(geom=c("Longitude", "Latitude")) 
  terra::crs(occ) <- "epsg:4326"
  gBuffer <- terra::buffer(x = occ, width = buffer)
  # rasterize the buffer object
  b1 <- terra::rasterize(x = gBuffer, y = sdm_thresh) |> terra::mask(sdm_thresh)
  # find thresholded distribution that is present within buffer
  b2 <- (sdm_thresh == 1) & (b1 == 1)
  
  # get ecoregions in buffer area
  eco$totBuf <- terra::zonal(x = b2, z = eco, fun="sum", na.rm=TRUE) |> unlist()
  exsiturepEcos <- eco[eco$totBuf > 0 , ]
  # get unrepresented ecoregions ex situ
  missingEcosExsitu <- selectedEcos_thresh[!selectedEcos_thresh$id_column %in% exsiturepEcos$id_column, ]
  
  
  ### prepare the map formatting
  
  # occurrence record marker
  H_observations <- makeAwesomeIcon(icon = "flag",
                                      markerColor = "darkblue",
                                      library = "ion")
  H_historicAccs <- makeAwesomeIcon(icon = "flag",
                                     markerColor = "black",
                                     library = "ion")
  G_activeAccs <- makeAwesomeIcon(icon = "flag",
                                     markerColor = "green",
                                     library = "ion")
  
  # colour palette for sdm habitat suitability scores
  pal <- colorNumeric(c("#fed976","#feb24c","#fd8d3c","#fc4e2a","#e31a1c","#bd0026","#800026"), 
                      values(sdm), 
                      na.color = "transparent")
  
  
  ### create the map
 
  map <- leaflet::leaflet() |>
    leaflet::addTiles() |>
    leaflet::addRasterImage(x = sdm, 
                            colors = pal, 
                            opacity = 0.5,
                            maxBytes = 34318113,
                            method = "ngb",
                            group = "Original distribution"
                            ) |>
    leaflet::addRasterImage(x = sdm_thresh,
                            colors = c("#fed976", "#800026"),
                            opacity = 0.5,
                            maxBytes = 34318113,
                            method = "ngb",
                            group = "Thresholded distribution"
                            ) |>
    addLegend(pal = pal, 
              values = values(sdm), 
              title = paste("Habitat suitability")
              ) |>
    leaflet::addPolygons(data = selectedEcos,
                         color = "black",
                         weight = 1,
                         opacity = 1,
                         popup = paste("Ecoregion code: ", selectedEcos$ECO_CODE, "<br>",
                                       "Ecoregion name: ", selectedEcos$ECO_NAME, "<br>"),
                         fillColor = "white",
                         fillOpacity = 0.01
                         ) |>
    leaflet::addRasterImage(x = proMask,
                            color = "black", 
                            opacity = 0.35, 
                            method = "ngb", 
                            group = "Protected areas"
                            ) |>
    leaflet::addPolygons(data = missingEcosInsitu, 
                         color = "black",
                         weight = 1, 
                         opacity = 1, 
                         popup = paste("Ecoregion code: ", missingEcosInsitu$ECO_CODE, "<br>",
                                       "Ecoregion name: ", missingEcosInsitu$ECO_NAME, "<br>"),
                         fillColor = "#6800ff", 
                         fillOpacity = 0.5, 
                         group = "In situ ecoregion gaps"
                         ) |>
    leaflet::addPolygons(data = missingEcosExsitu,
                         color = "black",
                         weight = 1, 
                         opacity = 1, 
                         popup = paste("Ecoregion code: ", missingEcosExsitu$ECO_CODE, "<br>",
                                       "Ecoregion name: ", missingEcosExsitu$ECO_NAME, "<br>"),
                         fillColor = "#f700ff", 
                         fillOpacity = 0.5, 
                         group = "Ex situ ecoregion gaps"
                         ) |>
    addAwesomeMarkers(lat = occurrenceData[occurrenceData$Type=="H_Obs",13], 
                      lng = occurrenceData[occurrenceData$Type=="H_Obs",14],
                      icon = H_observations,
                      popup = paste("Database :", filter(occurrenceData, Type=="H_Obs")$Database, "<br>",
                                    "Basis of record: ", filter(occurrenceData, Type=="H_Obs")$BasisOfRecord, "<br>",
                                    "Latitude :", filter(occurrenceData, Type=="H_Obs")$Latitude, "<br>",
                                    "Longitude :", filter(occurrenceData, Type=="H_Obs")$Longitude, "<br>"
                                    ),
                      group = "H (Observation)"
                      ) |>
    addAwesomeMarkers(lat = occurrenceData[occurrenceData$Type=="H_Historic",13], 
                      lng = occurrenceData[occurrenceData$Type=="H_Historic",14],
                      icon = H_historicAccs,
                      popup = paste("Genesys ID: ", filter(occurrenceData, Type=="H_Historic")$Genesys.ID, "<br>",
                                    "Institute WEIWS instcode: ", filter(occurrenceData, Type=="H_Historic")$Institute.WEIWS.instcode, "<br>",
                                    "Institute ID: ", filter(occurrenceData, Type=="H_Historic")$Institute.ID, "<br>",
                                    "Year of collection: ", filter(occurrenceData, Type=="H_Historic")$Year, "<br>",
                                    "Status: ", filter(occurrenceData, Type=="H_Historic")$Status, "<br>",
                                    "Latitude: ", filter(occurrenceData, Type=="H_Historic")$Latitude, "<br>",
                                    "Longitude: ", filter(occurrenceData, Type=="H_Historic")$Longitude, "<br>"),
                      group = "H (Historic accession)"
                      ) |>
    addAwesomeMarkers(lat = occurrenceData[occurrenceData$Type=="G_Active",13], 
                      lng = occurrenceData[occurrenceData$Type=="G_Active",14],
                      icon = G_activeAccs,
                      popup = paste("Genesys ID: ", filter(occurrenceData, Type=="G_Active")$Genesys.ID, "<br>",
                                    "Institute WEIWS instcode: ", filter(occurrenceData, Type=="G_Active")$Institute.WEIWS.instcode, "<br>",
                                    "Institute ID: ", filter(occurrenceData, Type=="G_Active")$Institute.ID, "<br>",
                                    "Year of collection: ", filter(occurrenceData, Type=="G_Active")$Year, "<br>", 
                                    "Status: ", filter(occurrenceData, Type=="G_Active")$Status, "<br>",
                                    "Latitude: ", filter(occurrenceData, Type=="G_Active")$Latitude, "<br>",
                                    "Longitude: ", filter(occurrenceData, Type=="G_Active")$Longitude, "<br>"),
                      group = "G (Active accession)"
                      ) |>
    leaflet::addPolygons(data = gBuffer, 
                         color = NA,
                         fillColor = "darkgreen", 
                         fillOpacity = 0.3, 
                         group = "G buffer"
                         ) |>
    addLayersControl(baseGroups = c("Original distribution",
                                    "Thresholded distribution"),
                     overlayGroups = c("H (Observation)",
                                       "H (Historic accession)",
                                       "G (Active accession)",
                                       "G buffer",
                                       "Protected areas",
                                       "Ex situ ecoregion gaps",
                                       "In situ ecoregion gaps"),
                     options = layersControlOptions(collapsed = FALSE)
                     ) |>
    addScaleBar(position = "bottomright",
                options = scaleBarOptions(metric = TRUE, 
                                          imperial = FALSE)
                ) |>
    addMiniMap(position = "bottomleft",
               zoomLevelOffset = -6,
               toggleDisplay = TRUE) 

  
  # output
  setwd(outputDir)
  output <- htmlwidgets::saveWidget(map,
                                    file = paste0(taxon,".html"),
                                    title = paste0(taxon, " - distribution model and conservation gaps")
  )
  
  return(output)
  
}