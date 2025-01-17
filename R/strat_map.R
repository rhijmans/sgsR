#' Map 2 stratified rasters
#'
#' @description Map stratified rasters to a combined stratification.
#'
#' @family stratify functions
#'
#' @inheritParams strat_breaks
#' @inheritParams strat_poly
#' @param sraster spatRaster. Primary stratification raster.
#' @param sraster2 spatRaster. Secondary stratification raster.
#' @param stack Logical. Default = \code{FALSE}. If \code{TRUE}, output raster will be
#' 3 layers: \code{strata, strata2, stratamapped}.
#' @param details Logical. If \code{FALSE} (default) output is a mapped stratified spatRaster object.
#' If \code{TRUE} return a list where \code{$outRaster} is the mapped stratified raster, and
#' \code{$lookUp} is the lookup table for the stratification.
#'
#' @section Mapping:
#' The mapping algorithm will take the stratification from \code{sraster} and combine it with
#' overlying strata values in \code{sraster2}. This will result in a \code{stratamapped} attribute
#' where the values from both inputs are combined.
#'
#' i.e.
#'
#' If \code{strata = 1} and \code{strata2 = 1} then \code{stratamapped = 11}.
#'
#' If \code{strata = 2} and \code{strata2 = 14} then \code{stratamapped = 214}.
#'
#' @examples
#' #--- load input metrics raster ---#
#' raster <- system.file("extdata", "sraster.tif", package = "sgsR")
#' sraster <- terra::rast(raster)
#'
#' #--- read polygon coverage ---#
#' poly <- system.file("extdata", "inventory_polygons.shp", package = "sgsR")
#' fri <- sf::st_read(poly)
#'
#' #--- stratify polygon coverage ---#
#' #--- specify polygon attribute to stratify ---#
#'
#' attribute <- "NUTRIENTS"
#'
#' #--- specify features within attribute & how they should be grouped ---#
#' #--- as a single vector ---#
#'
#' features <- c("poor", "rich", "medium")
#'
#' srasterfri <- strat_poly(
#'   poly = fri,
#'   attribute = attribute,
#'   features = features,
#'   raster = sraster
#' )
#'
#' #--- map srasters ---#
#' strat_map(
#'   sraster = srasterfri,
#'   sraster2 = sraster
#' )
#'
#' strat_map(
#'   sraster = srasterfri,
#'   sraster2 = sraster,
#'   stack = TRUE,
#'   details = TRUE
#' )
#' @importFrom methods is
#'
#' @return A spatRaster object.
#'
#' @author Tristan R.H. Goodbody
#'
#' @export


strat_map <- function(sraster,
                      sraster2,
                      stack = FALSE,
                      filename = NULL,
                      overwrite = FALSE,
                      plot = FALSE,
                      details = FALSE
                      ) {

  #--- global variables ---#
  strata <- strata2 <- sraster_cat <- sraster2_cat <- value <- NULL

  #--- error handling ---#

  if (!inherits(sraster, "SpatRaster")) {
    stop("'sraster' must be type SpatRaster.", call. = FALSE)
  }

  if (!inherits(sraster2, "SpatRaster")) {
    stop("'sraster2' must be type SpatRaster.", call. = FALSE)
  }

  if (!is.logical(stack)) {
    stop("'stack' must be type logical.", call. = FALSE)
  }

  if (!is.logical(overwrite)) {
    stop("'overwrite' must be type logical.", call. = FALSE)
  }

  if (!is.logical(plot)) {
    stop("'plot' must be type logical.", call. = FALSE)
  }

  if (!is.logical(details)) {
    stop("'details' must be type logical.", call. = FALSE)
  }

  #--- error handling for raster inputs ---#

  if (terra::nlyr(sraster) > 1) {
    stop("'sraster' must only contain 1 layer. Please subset the layer you would like to use for mapping.", call. = FALSE)
  }

  if (terra::nlyr(sraster2) > 1) {
    stop("'sraster2' must only contain 1 layer. Please subset the layer you would like to use for mapping.", call. = FALSE)
  }

  suppressWarnings(
    if (!grepl("strata", names(sraster))) {
      stop("A layer name containing 'strata' does not exist within 'sraster'.", call. = FALSE)
    }
  )

  suppressWarnings(
    if (!grepl("strata", names(sraster2))) {
      stop("A layer name containing 'strata' does not exist within 'sraster2'.", call. = FALSE)
    }
  )

  #--- check that extents and resolutions of sraster and sraster2 match ---#

  if (isFALSE(terra::compareGeom(sraster, sraster2, stopOnError = FALSE))) {
    stop("Extents of 'sraster' and 'sraster2' do not match.", call. = FALSE)
  }
  
  if (isFALSE(terra::compareGeom(sraster, sraster2, stopOnError = FALSE, ext = FALSE, res = TRUE))) {
    stop("Spatial resolutions of 'sraster' and 'sraster2' do not match.", call. = FALSE)
  }

  #--- map stratification rasters ---#
  
  
#  if(!is.null(terra::cats(sraster)[[1]])){
   if (is.factor(sraster)[1]) {
    message("'sraster' has factor values. Converting to allow mapping.")

## levels returns a list with data.frames with the 2 columns that matter (ID, value)
## whereas cats might return many
#    srastcats <- terra::cats(sraster) %>%
    srastcats <- terra::levels(sraster) %>%
       as.data.frame() %>%
      dplyr::rename(cat = 2) %>%
#      dplyr::mutate(value = value + 1)
      dplyr::mutate(value = value)

## catalyze creates a multi-layer raster if there are multiple attributes. 
## Here you just want to remove the levels.
    
#    sraster <- sraster %>%
#      terra::catalyze(.)
      levels(sraster) <- NULL   
  }

  
#  if(!is.null(terra::cats(sraster2)[[1]])){
   if (is.factor(sraster2)[1]) {
    message("'sraster2' has factor values. Converting to allow mapping.")
    
#    srastcats2 <- terra::cats(sraster2) %>%
    srastcats2 <- terra::levels(sraster2) %>%
      as.data.frame() %>%
      dplyr::rename(cat = 2) %>%
#      dplyr::mutate(value = value + 1)
      dplyr::mutate(value = value)
    
    #sraster2 <- sraster2 %>%
    #  terra::catalyze(.)
      levels(sraster2) <- NULL   

  }

  joined <- c(sraster, sraster2)
  names(joined) <- c("strata", "strata2")

## perhaps things would be simpler if you did not to do the 
## business with the levels you do above, and used "as.data.frame" here
## because you would get the factor labels if there are any.

#  featuresJoin <- terra::as.data.frame(joined, na.rm=FALSE)

  featuresJoin <- terra::values(joined, dataframe = TRUE)

  oclass <- featuresJoin %>%
    dplyr::group_by(strata, strata2) %>%
    #--- ensure NA's are transfered ---#
    dplyr::mutate(stratamapped = ifelse(is.na(strata) | is.na(strata2), NA, paste0(strata,strata2)))

  #--- create lookUp table ---#

  lookUp <- dplyr::distinct(oclass) %>%
    stats::na.omit() %>%
    as.data.frame()
  
  #--- if stratum variables were categorical add the categories to the lookUp table ---#
  
  if(exists("srastcats")){

    lookUp <- dplyr::left_join(lookUp, srastcats, by=c("strata" = "value")) %>%
      dplyr::rename(sraster_cat = names(srastcats)[2])

    #--- sometimes values are factors

    if(any(is.na(lookUp$sraster_cat))){

      lookUp$sraster_cat <- lookUp$strata

    }

    if(!exists("srastcats2")){

        lookUp <- lookUp %>%
          dplyr::mutate(stratamapped_cat = paste0(sraster_cat,"_",strata2)) %>%
          dplyr::select(-sraster_cat)

    }
  }

  if(exists("srastcats2")){

    lookUp <- dplyr::left_join(lookUp, srastcats2, by=c("strata2" = "value")) %>%
      dplyr::rename(sraster2_cat = names(srastcats2)[2])

    if(any(is.na(lookUp$sraster2_cat))){

      lookUp$sraster2_cat <- lookUp$strata2

    }

    if(exists("srastcats")){

      lookUp <- lookUp %>%
        dplyr::mutate(stratamapped_cat = paste0(sraster_cat,"_",sraster2_cat)) %>%
        dplyr::select(-sraster2_cat, -sraster_cat)

    } else {

      lookUp <- lookUp %>%
        dplyr::mutate(stratamapped_cat = paste0(strata,"_",sraster2_cat)) %>%
        dplyr::select(-sraster2_cat)

    }

  }

  #--- set newly stratified values ---#

  rout <- terra::setValues(sraster, as.integer(oclass$stratamapped))
  names(rout) <- "strata"

  if (isTRUE(stack)) {
    message("Stacking sraster, sraster2, and their combination (stratamapped).")

    #--- stack 3 rasters if requested ---#

    routstack <- c(sraster, sraster2, rout)
    names(routstack) <- c("strata", "strata2", "stratamapped")
  }

  #--- if not stacking rename for output ---#

  if (exists("routstack")) {
    rout <- routstack
  }


  #--- plot if requested

  if (isTRUE(plot)) {
    terra::plot(rout, type = "classes")
  }

  #--- write file to disc ---#

  if (!is.null(filename)) {
    
    if (!is.character(filename)) {
      stop("'filename' must be type character.", call. = FALSE)
    }

    #--- write file to disc depending on whether 'stack' was specified ---#

    if (isTRUE(stack)) {
      terra::writeRaster(x = routstack, filename = filename, overwrite = overwrite)
      message("Output stack written to disc.")
    } else {
      terra::writeRaster(x = rout, filename = filename, overwrite = overwrite)
      message("Output raster written to disc.")
    }
  }

  #--- output details if desired ---#

  if (isTRUE(details)) {

    #--- output metrics details along with stratification raster ---#

    output <- list(raster = rout, lookUp = lookUp)

    #--- output samples dataframe ---#

    return(output)
  } else {

    #--- just output raster ---#

    return(rout)
  }
}
