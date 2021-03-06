% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/parse_period.R
\name{parse_period}
\alias{parse_period}
\title{Parse a character period specification}
\usage{
parse_period(period)
}
\arguments{
\item{period}{A character specification used for time-based grouping. The
general format to use is \code{"frequency period"} where frequency is a number
like 1 or 2, and period is an interval like weekly or yearly. There must be
a space between the two.

Note that you can pass the specification in a flexible way:
\itemize{
\item 1 Year: \code{'1 year'} / \code{'1 Y'} / \code{'1 yearly'} / \code{'yearly'}
}

This shorthand is available for year, quarter, month, day, hour, minute,
and second periodicities. Note that "m" is the 1 letter specification used
for "month" and "M" is used for "minute". Otherwise case does not matter.}
}
\description{
The period is parsed into frequency and period and returned as a named list.
}
\examples{

parse_period('2 day')

}
