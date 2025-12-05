#' @title Create a binary species distribution model (SDM)
#' @name binarySDM 
#' @description Calculates habitat suitability score statistics and creates a binary SDM model that uses the average
#' habitat suitability score for thresholding
#' 
#' @param taxon A character object that defines the name of the species/taxon as listed in the occurrence dataset
#' @param model A raster object that represents the expected/modelled distribution of the species/taxon
#' @param occData A dataframe containing occurrence data records, including longitude and latitude in columns 3 and 4 
#' @param outputDir A character object that defines the output directory to save the interactive map into  
#' 
#' @return A binary SDM model that has been thresholded using the average habitat suitability score


binarySDM <- function(model, occData, taxon, outputDir) {
  
  ### install and load dependencies
  if (!require("pacman")) install.packages("pacman")
  pacman::p_load("raster")
  
  ### Summarise habitat suitability scores
  
  # extract suitability scores from sdm
  SuitabilityScores <- raster::extract(model, occData[,3:2]) #note: columns = longitude:latitude
  # remove NAs
  SuitabilityScores <- SuitabilityScores[complete.cases(SuitabilityScores)]
  
  # calculate average habitat suitability score for thresholding  
  SS_av <- mean(SuitabilityScores)
  
  # print metrics - view distribution of habitat scores
  print(summary(SuitabilityScores))
  
  # plot suitability score distribution
  hist(SuitabilityScores, main = "Habitat suitability", xlab = "Values", ylab = "Frequency", xlim = c(0,1), breaks=(seq(0,1,0.1)))
  
  ### reclassify sdm raster into binary format using the average habitat suitability score for thresholding
  
  M <- c(0, SS_av, 0,  SS_av, 1, 1) 
  rclmat <- matrix(M, ncol=3, byrow=TRUE) 
  binary <- raster::reclassify(model, rcl = rclmat)
  
  # set output directory
  setwd(outputDir)
  # write reclassified sdm raster
  output <- writeRaster(binary,
                        file = paste0(taxon, "._BINARY_AVthresh.asc"), 
                        format = "ascii")  

  return(output)
  
}
