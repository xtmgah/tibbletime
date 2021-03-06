#' A simple wrapper of [lubridate::floor_date()]
#'
#' This is a thin wrapper around a [lubridate::floor_date()] that works
#' for `hms`, `yearmon`, and `yearqtr` classes as well.
#'
#' @inheritParams lubridate::floor_date
#'
#' @examples
#'
#' data(FB)
#' dplyr::mutate(FB, date2 = floor_index(date, "year"))
#'
#' time_test <- create_series('00:00:00'~'12:00:00',
#'                            '1 minute', class = "hms")
#'
#' dplyr::mutate(time_test, date2 = floor_index(date, "hour"))
#'
#' @seealso [lubridate::floor_date()]
#'
#' @export
floor_index <- function(x, unit = "seconds") {
  UseMethod("floor_index")
}

#' @export
floor_index.default <- function(x, unit = "seconds") {
  lubridate::floor_date(x, unit)
}

#' @export
floor_index.hms <- function(x, unit = "seconds") {
  floored <- floor_index(as.POSIXct(x), unit)
  hms::as.hms(floored, attr(floored, "tzone"))
}

#' @export
floor_index.yearmon <- function(x, unit = "seconds") {
  zoo::as.yearmon(floor_index(zoo::as.Date(x), unit))
}

#' @export
floor_index.yearqtr <- function(x, unit = "seconds") {
  zoo::as.yearqtr(floor_index(zoo::as.Date(x), unit))
}
