% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils-allocation.R
\name{allocating}
\alias{allocating}
\alias{allocate_prop}
\alias{allocate_optim}
\alias{allocate_manual}
\alias{allocate_equal}
\alias{allocate_existing}
\alias{allocate_force}
\title{Allocating}
\usage{
allocate_prop(sraster, nSamp)

allocate_optim(sraster, mraster, nSamp)

allocate_manual(sraster, nSamp, weights)

allocate_equal(sraster, nSamp)

allocate_existing(toSample, existing)

allocate_force(toSample, nSamp, diff)
}
\arguments{
\item{sraster}{spatRaster. Stratification raster to be used for sampling.}

\item{nSamp}{Numeric. Number of desired samples.}

\item{mraster}{spatRaster. ALS metric raster. Required when \code{allocation = optim}.}

\item{weights}{Numeric. Only applicable when \code{allocation = "manual"}. Vector of weights where \code{sum(weights) == 1}. Vector length
must be equal to the number of unique strata where the first numeric value corresponds to stratum 1, second stratum 2 etc.}

\item{existing}{sf 'POINT' or data.frame.  Existing plot network.}
}
\value{
Data frame of allocated samples by stratum. Used internally within \code{sample_strat()}.
}
\description{
Allocation algorithms
}
\concept{allocating}
\concept{allocation}
\keyword{internal}
