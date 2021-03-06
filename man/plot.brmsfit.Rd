% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/brmsfit-methods.R
\name{plot.brmsfit}
\alias{plot.brmsfit}
\title{Trace and Density Plots for MCMC Samples}
\usage{
\method{plot}{brmsfit}(x, pars = NA, parameters = NA, combo = c("dens",
  "trace"), N = 5, exact_match = FALSE, theme = NULL, plot = TRUE,
  ask = TRUE, newpage = TRUE, ...)
}
\arguments{
\item{x}{An object of class \code{brmsfit}.}

\item{pars}{Names of the parameters to plot, as given by a character vector 
or a regular expression. By default, all parameters except 
for group-level and smooth effects are plotted.}

\item{parameters}{A deprecated alias of \code{pars}}

\item{combo}{A character vector with at least two elements. 
Each element of \code{combo} corresponds to a column in the resulting 
graphic and should be the name of one of the available 
\code{link[bayesplot:MCMC-overview]{MCMC}} functions 
(omitting the \code{mcmc_} prefix).}

\item{N}{The number of parameters plotted per page.}

\item{exact_match}{Indicates whether parameter names 
should be matched exactly or treated as regular expression. 
Default is \code{FALSE}.}

\item{theme}{A \code{\link[ggplot2:theme]{theme}} object 
modifying the appearance of the plots. 
For some basic themes see \code{\link[ggplot2:ggtheme]{ggtheme}}
and \code{\link[bayesplot:theme_default]{theme_default}}.}

\item{plot}{logical; indicates if plots should be
plotted directly in the active graphic device.
Defaults to \code{TRUE}.}

\item{ask}{logical; indicates if the user is prompted 
before a new page is plotted. 
Only used if \code{plot} is \code{TRUE}.}

\item{newpage}{logical; indicates if the first set of plots
should be plotted to a new page. 
Only used if \code{plot} is \code{TRUE}.}

\item{...}{Further arguments passed to 
\code{\link[bayesplot:mcmc_combo]{mcmc_combo}}.}
}
\value{
An invisible list of 
  \code{\link[gtable:gtable]{gtable}} objects.
}
\description{
Trace and Density Plots for MCMC Samples
}
\examples{
\dontrun{ 
fit <- brm(count ~ log_Age_c + log_Base4_c * Trt_c 
           + (1|patient) + (1|visit), 
           data = epilepsy, family = "poisson")
## plot fixed effects as well as standard devations of the random effects
plot(fit)
## plot fixed effects only
plot(fit, pars = "^b_") 
}

}
\author{
Paul-Christian Buerkner \email{paul.buerkner@gmail.com}
}

