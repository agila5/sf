#' @name valid
#' @param NA_on_exception logical; if TRUE, for polygons that would otherwise raise a GEOS error (exception, e.g. for a POLYGON having more than zero but less than 4 points, or a LINESTRING having one point) return an \code{NA} rather than raising an error, and suppress warning messages (e.g. about self-intersection); if FALSE, regular GEOS errors and warnings will be emitted.
#' @param reason logical; if \code{TRUE}, return a character with, for each geometry, the reason for invalidity, \code{NA} on exception, or \code{"Valid Geometry"} otherwise.
#' @param ... passed on to sfc method
#' @return \code{st_is_valid} returns a logical vector indicating for each geometries of \code{x} whether it is valid.
#' @export
#' @examples
#' p1 = st_as_sfc("POLYGON((0 0, 0 10, 10 0, 10 10, 0 0))")
#' st_is_valid(p1)
#' st_is_valid(st_sfc(st_point(0:1), p1[[1]]), reason = TRUE)
st_is_valid = function(x, ...) UseMethod("st_is_valid")

#' @export
#' @name valid
st_is_valid.sfc = function(x, ..., NA_on_exception = TRUE, reason = FALSE) {
	if (reason) {
		if (NA_on_exception) {
			ret = rep(NA_character_, length(x))
			not_na = !is.na(st_is_valid(x, reason = FALSE))
			ret[not_na] = CPL_geos_is_valid_reason(x)
			ret
		} else
			CPL_geos_is_valid_reason(x)
	} else if (! NA_on_exception) {
		CPL_geos_is_valid(x, as.logical(NA_on_exception))
	} else {
		ret = vector("logical", length(x))
		for (i in seq_along(x))
			ret[i] = CPL_geos_is_valid(x[i], as.logical(NA_on_exception))
		ret
	}
}

#' @export
#' @name valid
st_is_valid.sf = function(x, ...) {
	st_is_valid(st_geometry(x), ...)
}

#' @name valid
#' @export
st_is_valid.sfg = function(x, ...) {
	st_is_valid(st_geometry(x), ...)
}

#' Check validity or make an invalid geometry valid
#'
#' Checks whether a geometry is valid, or makes an invalid geometry valid
#' @name valid
#' @param x object of class \code{sfg}, \code{sfg} or \code{sf}
#' @return Object of the same class as \code{x}
#' @details \code{st_make_valid} uses the \code{lwgeom_makevalid} method also used by the PostGIS command \code{ST_makevalid} if the GEOS version linked to is smaller than 3.8.0, and otherwise the version shipped in GEOS.
#' @examples
#' library(sf)
#' x = st_sfc(st_polygon(list(rbind(c(0,0),c(0.5,0),c(0.5,0.5),c(0.5,0),c(1,0),c(1,1),c(0,1),c(0,0)))))
#' suppressWarnings(st_is_valid(x))
#' y = st_make_valid(x)
#' st_is_valid(y)
#' y %>% st_cast()
#' @export
st_make_valid = function(x) UseMethod("st_make_valid")

#' @export
#' @name valid
st_make_valid.sfg = function(x) {
	st_make_valid(st_geometry(x))[[1]]
}

#' @export
st_make_valid.sfc = function(x) {
	crs = st_crs(x)
	x = if (sf_extSoftVersion()["GEOS"] < "3.8.0") {
			if (!requireNamespace("lwgeom", quietly = TRUE))
				stop("lwgeom required: install that first") # nocov
			lwgeom::lwgeom_make_valid(x)
		} else
			CPL_geos_make_valid(x) # nocov
	st_sfc(x, crs = crs)
}

#' @export
st_make_valid.sf = function(x) {
	st_set_geometry(x, st_make_valid(st_geometry(x)))
}
