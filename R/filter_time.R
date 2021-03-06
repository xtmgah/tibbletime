#' Succinctly filter a `tbl_time` object by its index
#'
#' Use a concise filtering method to filter a `tbl_time` object by its `index`.
#'
#' @param .tbl_time A `tbl_time` object.
#' @param time_formula A period to filter over.
#' This is specified as a `formula`. See `Details`.
#'
#' @details
#'
#' The `time_formula` is specified using the format `from ~ to`.
#' Each side of the `time_formula` is specified as the character
#' `'YYYY-MM-DD HH:MM:SS'`, but powerful shorthand is available.
#' Some examples are:
#' * __Year:__ `'2013' ~ '2015'`
#' * __Month:__ `'2013-01' ~ '2016-06'`
#' * __Day:__ `'2013-01-05' ~ '2016-06-04'`
#' * __Second:__ `'2013-01-05 10:22:15' ~ '2018-06-03 12:14:22'`
#' * __Variations:__ `'2013' ~ '2016-06'`
#'
#' The `time_formula` can also use a one sided formula.
#' * __Only dates in 2015:__ `~'2015'`
#' * __Only dates March 2015:__ `~'2015-03'`
#'
#' The `time_formula` can also use `'start'` and `'end'` as keywords for
#' your filter.
#' * __Start of the series to end of 2015:__ `'start' ~ '2015'`
#' * __Start of 2014 to end of series:__ `'2014' ~ 'end'`
#'
#' All shorthand dates are expanded:
#' * The `from` side is expanded to be the first date in that period
#' * The `to` side is expanded to be the last date in that period
#'
#' This means that the following examples are equivalent (assuming your
#' index is a POSIXct):
#' * `2015 ~ 2016 == 2015-01-01 + 00:00:00 ~ 2016-12-31 + 23:59:59`
#' * `~2015 == 2015-01-01 + 00:00:00 ~ 2015-12-31 + 23:59:59`
#' * `2015-01-04 + 10:12 ~ 2015-01-05 == 2015-01-04 + 10:12:00 ~ 2015-01-05 + 23:59:59`
#'
#' Special parsing is done for indices of class `hms`. The `from ~ to` time
#' formula is specified as only `HH:MM:SS`.
#' * __Start to 5th second of the 12th hour:__ `'start' ~ '12:00:05'`
#' * __Every second in the 12th hour:__ `~'12'`
#'
#' This function respects [dplyr::group_by()] groups.
#'
#' @rdname filter_time
#'
#' @export
#'
#' @examples
#'
#' # FANG contains Facebook, Amazon, Netflix and Google stock prices
#' data(FANG)
#' FANG <- as_tbl_time(FANG, date) %>%
#'   dplyr::group_by(symbol)
#'
#' # 2013-01-01 to 2014-12-31
#' filter_time(FANG, '2013' ~ '2014')
#'
#' # 2013-05-25 to 2014-06-04
#' filter_time(FANG, '2013-05-25' ~ '2014-06-04')
#'
#' # Using the `[` subset operator
#' FANG['2014'~'2015']
#'
#' # Using `[` and one sided formula for only dates in 2014
#' FANG[~'2014']
#'
#' # Using `[` and column selection
#' FANG['2013'~'2016', c("date", "adjusted")]
#'
#' # Variables are unquoted using rlang
#' lhs_date <- "2013"
#' rhs_date <- as.Date("2014-01-01")
#' filter_time(FANG, lhs_date ~ rhs_date)
#'
#' # Use the keywords 'start' and 'end' to conveniently access ends
#' filter_time(FANG, 'start' ~ '2014')
#'
#' # hms (hour, minute, second) classes have special parsing
#' hms_example <- create_series(~'12:01', 'second', class = 'hms')
#' filter_time(hms_example, 'start' ~ '12:01:30')
#'
#'
filter_time <- function(.tbl_time, time_formula) {
  UseMethod("filter_time")
}

#' @export
filter_time.default <- function(.tbl_time, time_formula) {
  stop("Object is not of class `tbl_time`.", call. = FALSE)
}

#' @export
filter_time.tbl_time <- function(.tbl_time, time_formula) {

  index_quo  <- get_index_quo(.tbl_time)
  tz <- get_index_time_zone(.tbl_time)

  # from/to setup is done inside the call to filter so it is unique to
  # each group
  .tbl_filtered <- dplyr::filter(.tbl_time, {

    # Parse the time_formula, don't convert to dates yet
    tf_list <- parse_time_formula(!! index_quo, time_formula)

    # Could allow for multifilter idea here

    # Then convert to datetime
    from_to <- purrr::map(
      .x = tf_list,
      .f = ~list_to_datetime(!! index_quo, .x, tz = tz)
    )

    # Get sequence creation pieces ready
    from <- from_to[[1]]
    to   <- from_to[[2]]

    # Final assertion of order
    assert_from_before_to(from, to)

    sorted_range_search(!! index_quo, from, to)
  })

  reconstruct(.tbl_filtered, .tbl_time)
}

# Subset operator --------------------------------------------------------------

#' @export
#'
#' @param x Same as `.tbl_time` but consistent naming with base R.
#' @param i A period to filter over. This is specified the same as
#' `time_formula` or can use the traditional row extraction method.
#' @param j Optional argument to also specify column index to subset. Works
#' exactly like the normal extraction operator.
#' @param drop Will always be coerced to `FALSE` by `tibble`.
#'
#' @rdname filter_time
#'
`[.tbl_time` <- function(x, i, j, drop = FALSE) {

  # This helps decide whether i is used for column subset or row subset
  .nargs <- nargs() - !missing(drop)

  # filter_time if required
  if(!missing(i)) {
    if(rlang::is_formula(i)) {
      x <- filter_time(x, i)
    }
  }

  # Remove time class/attribs to let tibble::`[` do the rest
  x_tbl <- as_tibble(x)

  # i filter
  if(!missing(i)) {
    if(!rlang::is_formula(i)) {
      if(.nargs <= 2) {
        # Column subset
        # Preferred if tibble issue is addressed
        # x <- x[i, drop = drop]
        x_tbl <- x_tbl[i]
      } else {
        # Row subset
        x_tbl <- x_tbl[i, , drop = drop]
      }

    }
  }

  # j filter
  if(!missing(j)) {
    x_tbl <- x_tbl[, j, drop = drop]
  }

  # If the index still exists, convert to tbl_time again
  if(get_index_char(x) %in% colnames(x_tbl)) {
    x_tbl <- as_tbl_time(x_tbl, !! get_index_quo(x))
  }

  x_tbl
}
