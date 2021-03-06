# All functions in this file have the same arguments structure
# Args:
#  i: the column of draws to use i.e. the ith obervation 
#     in the initial data.frame 
#  draws: A named list returned by extract_draws containing 
#         all required data and samples
#  ntrys: number of trys in rejection sampling for truncated discrete models
#  ...: ignored arguments
# Returns:
#   A vector of length draws$nsamples containing samples
#   from the posterior predictive distribution
predict_gaussian <- function(i, draws, ...) {
  args <- list(mean = ilink(get_eta(draws, i), draws$f$link), 
               sd = get_sigma(draws$sigma, data = draws$data, i = i))
  rng_continuous(nrng = draws$nsamples, dist = "norm", args = args, 
                 lb = draws$data$lb[i], ub = draws$data$ub[i])
}

predict_student <- function(i, draws, ...) {
  args <- list(df = get_auxpar(draws$nu, i = i), 
               mu = ilink(get_eta(draws, i), draws$f$link), 
               sigma = get_sigma(draws$sigma, data = draws$data, i = i))
  rng_continuous(nrng = draws$nsamples, dist = "student", args = args, 
                 lb = draws$data$lb[i], ub = draws$data$ub[i])
}

predict_cauchy <- function(i, draws, ...) {
  args <- list(df = 1, mu = ilink(get_eta(draws, i), draws$f$link), 
               sigma = get_sigma(draws$sigma, data = draws$data, i = i))
  rng_continuous(nrng = draws$nsamples, dist = "student", args = args,
                 lb = draws$data$lb[i], ub = draws$data$ub[i])
}

predict_lognormal <- function(i, draws, ...) {
  args <- list(meanlog = ilink(get_eta(draws, i), draws$f$link), 
               sdlog = get_sigma(draws$sigma, data = draws$data, i = i))
  rng_continuous(nrng = draws$nsamples, dist = "lnorm", args = args, 
                 lb = draws$data$lb[i], ub = draws$data$ub[i])
}

predict_gaussian_mv <- function(i, draws, ...) {
  # currently no truncation available
  if (!is.null(draws$data$N_trait)) {
    obs <- seq(i, draws$data$N, draws$data$N_trait)
    mu <- ilink(get_eta(draws, obs), draws$f$link)
  } else {
    mu <- ilink(get_eta(draws, i), draws$f$link)[, 1, ]
  }
  .fun <- function(s) {
    rmulti_normal(1, mu = mu[s, ], Sigma = draws$Sigma[s, , ])
  }
  do.call(rbind, lapply(1:draws$nsamples, .fun))
}

predict_student_mv <- function(i, draws, ...) {
  # currently no truncation available
  if (!is.null(draws$data$N_trait)) {
    obs <- seq(i, draws$data$N, draws$data$N_trait)
    mu <- ilink(get_eta(draws, obs), draws$f$link)
  } else {
    mu <- ilink(get_eta(draws, i), draws$f$link)[, 1, ]
  }
  nu <- get_auxpar(draws$nu, i = i)
  .fun <- function(s) {
    rmulti_student(1, df = nu[s, ], mu = mu[s, ], 
                   Sigma = draws$Sigma[s, , ])
  }
  do.call(rbind, lapply(1:draws$nsamples, .fun))
}

predict_cauchy_mv <- function(i, draws, ...) {
  # currently no truncation available
  if (!is.null(draws$data$N_trait)) {
    obs <- seq(i, draws$data$N, draws$data$N_trait)
    mu <- ilink(get_eta(draws, obs), draws$f$link)
  } else {
    mu <- ilink(get_eta(draws, i), draws$f$link)[, 1, ]
  }
  .fun <- function(s) {
    rmulti_student(1, df = 1, mu = mu[s, ],
                   Sigma = draws$Sigma[s, , ])
  }
  do.call(rbind, lapply(1:draws$nsamples, .fun))
}

predict_gaussian_cov <- function(i, draws, ...) {
  # currently, only ARMA1 processes are implemented
  obs <- with(draws$data, begin_tg[i]:(begin_tg[i] + nobs_tg[i] - 1))
  mu <- ilink(get_eta(draws, obs), draws$f$link)
  args <- list(sigma = get_sigma(draws$sigma, data = draws$data, i = i), 
               se2 = draws$data$se2[obs], nrows = length(obs))
  if (!is.null(draws$ar) && is.null(draws$ma)) {
    # AR1 process
    args$ar <- draws$ar
    Sigma <- do.call(get_cov_matrix_ar1, args)
  } else if (is.null(draws$ar) && !is.null(draws$ma)) {
    # MA1 process
    args$ma <- draws$ma
    Sigma <- do.call(get_cov_matrix_ma1, args)
  } else if (!is.null(draws$ar) && !is.null(draws$ma)) {
    # ARMA1 process
    args[c("ar", "ma")] <- draws[c("ar", "ma")]
    Sigma <- do.call(get_cov_matrix_arma1, args)
  } else {
    # identity matrix
    Sigma <- do.call(get_cov_matrix_ident, args)
  }
  .fun <- function(s) {
    rmulti_normal(1, mu = mu[s, ], Sigma = Sigma[s, , ])
  }
  do.call(rbind, lapply(1:draws$nsamples, .fun))
}

predict_student_cov <- function(i, draws, ...) {
  # currently, only ARMA1 processes are implemented
  obs <- with(draws$data, begin_tg[i]:(begin_tg[i] + nobs_tg[i] - 1))
  mu <- ilink(get_eta(draws, obs), draws$f$link)
  args <- list(sigma = get_sigma(draws$sigma, data = draws$data, i = i), 
               se2 = draws$data$se2[obs], nrows = length(obs))
  if (!is.null(draws$ar) && is.null(draws$ma)) {
    # AR1 process
    args$ar <- draws$ar
    Sigma <- do.call(get_cov_matrix_ar1, args)
  } else if (is.null(draws$ar) && !is.null(draws$ma)) {
    # MA1 process
    args$ma <- draws$ma
    Sigma <- do.call(get_cov_matrix_ma1, args)
  } else if (!is.null(draws$ar) && !is.null(draws$ma)) {
    # ARMA1 process
    args[c("ar", "ma")] <- draws[c("ar", "ma")]
    Sigma <- do.call(get_cov_matrix_arma1, args)
  } else {
    # identity matrix
    Sigma <- do.call(get_cov_matrix_ident, args)
  }
  nu <- get_auxpar(draws$nu, i = i)
  .fun <- function(s) {
    rmulti_student(1, df = nu[s, ], mu = mu[s, ], 
                   Sigma = Sigma[s, , ])
  }
  do.call(rbind, lapply(1:draws$nsamples, .fun))
}

predict_cauchy_cov <- function(i, draws, ...) {
  draws$nu <- matrix(rep(1, draws$nsamples))
  predict_student_cov(i = i, draws = draws, ...) 
}

predict_gaussian_fixed <- function(i, draws, ...) {
  stopifnot(i == 1)
  mu <- ilink(get_eta(draws, 1:nrow(draws$data$V)), draws$f$link)
  .fun <- function(s) {
    rmulti_normal(1, mu = mu[s, ], Sigma = draws$data$V)
  }
  do.call(rbind, lapply(1:draws$nsamples, .fun))
}

predict_student_fixed <- function(i, draws, ...) {
  stopifnot(i == 1)
  mu <- ilink(get_eta(draws, 1:nrow(draws$data$V)), draws$f$link)
  nu <- get_auxpar(draws$nu, 1:nrow(draws$data$V))
  .fun <- function(s) {
    rmulti_student(1, df = nu[s, ], mu = mu[s, ], Sigma = draws$data$V)
  }
  do.call(rbind, lapply(1:draws$nsamples, .fun))
}

predict_cauchy_fixed <- function(i, draws, ...) {
  stopifnot(i == 1)
  draws$nu <- matrix(rep(1, draws$nsamples))
  predict_student_fixed(i, draws = draws, ...)
}

predict_binomial <- function(i, draws, ntrys = 5, ...) {
  trials <- draws$data$trials[i]
  args <- list(size = trials, prob = ilink(get_eta(draws, i), draws$f$link))
  rng_discrete(nrng = draws$nsamples, dist = "binom", args = args, 
               lb = draws$data$lb[i], ub = draws$data$ub[i], 
               ntrys = ntrys)
}

predict_bernoulli <- function(i, draws, ...) {
  # truncation not useful
  eta <- get_eta(draws, i)
  rbinom(length(eta), size = 1, prob = ilink(eta, draws$f$link))
}

predict_poisson <- function(i, draws, ntrys = 5, ...) {
  args <- list(lambda = ilink(get_eta(draws, i), draws$f$link))
  rng_discrete(nrng = draws$nsamples, dist = "pois", args = args, 
               lb = draws$data$lb[i], ub = draws$data$ub[i],
               ntrys = ntrys)
}

predict_negbinomial <- function(i, draws, ntrys = 5, ...) {
  args <- list(mu = ilink(get_eta(draws, i), draws$f$link), 
               size = get_shape(draws$shape, data = draws$data, i = i))
  rng_discrete(nrng = draws$nsamples, dist = "nbinom", args = args, 
               lb = draws$data$lb[i], ub = draws$data$ub[i],
               ntrys = ntrys)
}

predict_geometric <- function(i, draws, ntrys = 5, ...) {
  args <- list(mu = ilink(get_eta(draws, i), draws$f$link), size = 1)
  rng_discrete(nrng = draws$nsamples, dist = "nbinom", args = args, 
               lb = draws$data$lb[i], ub = draws$data$ub[i], 
               ntrys = ntrys)
}

predict_exponential <- function(i, draws, ...) {
  args <- list(rate = 1 / ilink(get_eta(draws, i), draws$f$link))
  rng_continuous(nrng = draws$nsamples, dist = "exp", args = args, 
                 lb = draws$data$lb[i], ub = draws$data$ub[i])
}

predict_gamma <- function(i, draws, ...) {
  shape <- get_shape(draws$shape, data = draws$data, i = i)
  args <- list(shape = shape, 
               scale = ilink(get_eta(draws, i), draws$f$link) / shape)
  rng_continuous(nrng = draws$nsamples, dist = "gamma", args = args, 
                 lb = draws$data$lb[i], ub = draws$data$ub[i])
}

predict_weibull <- function(i, draws, ...) {
  shape <- get_shape(draws$shape, data = draws$data, i = i)
  scale <- ilink(get_eta(draws, i) / shape, draws$f$link)
  args <- list(shape = shape, scale = scale)
  rng_continuous(nrng = draws$nsamples, dist = "weibull", args = args, 
                 lb = draws$data$lb[i], ub = draws$data$ub[i])
}

predict_frechet <- function(i, draws, ...) {
  nu <- get_auxpar(draws$nu, i = i)
  scale <- ilink(get_eta(draws, i), draws$f$link) / gamma(1 - 1 / nu)
  args <- list(scale = scale, shape = nu)
  rng_continuous(nrng = draws$nsamples, dist = "frechet", args = args, 
                 lb = draws$data$lb[i], ub = draws$data$ub[i])
}

predict_gen_extreme_value <- function(i, draws, ...) {
  sigma <- get_sigma(draws$sigma, data = draws$data, i = i)
  xi <- get_auxpar(draws$xi, i = i)
  mu <- ilink(get_eta(draws, i), draws$f$link)
  args <- nlist(mu, sigma, xi)
  rng_continuous(nrng = draws$nsamples, dist = "gen_extreme_value", 
                 args = args, lb = draws$data$lb[i], ub = draws$data$ub[i])
}

predict_inverse.gaussian <- function(i, draws, ...) {
  args <- list(mean = ilink(get_eta(draws, i), draws$f$link), 
               shape = get_shape(draws$shape, data = draws$data, i = i))
  rng_continuous(nrng = draws$nsamples, dist = "invgauss", args = args, 
                 lb = draws$data$lb[i], ub = draws$data$ub[i])
}

predict_exgaussian <- function(i, draws, ...) {
  args <- list(mu = ilink(get_eta(draws, i), draws$f$link), 
               sigma = get_sigma(draws$sigma, data = draws$data, i = i),
               beta = get_auxpar(draws$beta, i = i))
  rng_continuous(nrng = draws$nsamples, dist = "exgaussian", args = args, 
                 lb = draws$data$lb[i], ub = draws$data$ub[i])
}

predict_wiener <- function(i, draws, col = c("q", "resp"), ...) {
  args <- list(delta = ilink(get_eta(draws, i), draws$f$link), 
               alpha = get_auxpar(draws$bs, i = i),
               tau = get_auxpar(draws$ndt, i = i),
               beta = get_auxpar(draws$bias, i = i),
               col = match.arg(col))
  rng_continuous(nrng = 1, dist = "Wiener", args = args, 
                 lb = draws$data$lb[i], ub = draws$data$ub[i])
}

predict_beta <- function(i, draws, ...) {
  mu <- ilink(get_eta(draws, i), draws$f$link)
  phi <- get_auxpar(draws$phi, i = i)
  args <- list(shape1 = mu * phi, shape2 = (1 - mu) * phi)
  rng_continuous(nrng = draws$nsamples, dist = "beta", args = args, 
                 lb = draws$data$lb[i], ub = draws$data$ub[i])
}

predict_von_mises <- function(i, draws, ...) {
  args <- list(mu = ilink(get_eta(draws, i), draws$f$link), 
               kappa = get_auxpar(draws$kappa, i = i))
  rng_continuous(nrng = draws$nsamples, dist = "von_mises", args = args,
                 lb = draws$data$lb[i], ub = draws$data$ub[i])
}

predict_asym_laplace <- function(i, draws, ...) {
  args <- list(mu = ilink(get_eta(draws, i), draws$f$link), 
               sigma = get_sigma(draws$sigma, data = draws$data, i = i),
               quantile = get_auxpar(draws$quantile, i = i))
  rng_continuous(nrng = draws$nsamples, dist = "asym_laplace", args = args, 
                 lb = draws$data$lb[i], ub = draws$data$ub[i])
}

predict_hurdle_poisson <- function(i, draws, ...) {
  # theta is the bernoulli hurdle parameter
  theta <- get_theta(draws, i, par = "hu")
  lambda <- ilink(get_eta(draws, i), draws$f$link)
  ndraws <- draws$nsamples
  # compare with theta to incorporate the hurdle process
  hu <- runif(ndraws, 0, 1)
  # sample from a truncated poisson distribution
  # by adjusting lambda and adding 1
  t = -log(1 - runif(ndraws) * (1 - exp(-lambda)))
  ifelse(hu < theta, 0, rpois(ndraws, lambda = lambda - t) + 1)
}

predict_hurdle_negbinomial <- function(i, draws, ...) {
  # theta is the bernoulli hurdle parameter
  theta <- get_theta(draws, i, par = "hu")
  mu <- ilink(get_eta(draws, i), draws$f$link)
  ndraws <- draws$nsamples
  # compare with theta to incorporate the hurdle process
  hu <- runif(ndraws, 0, 1)
  # sample from an approximative(!) truncated negbinomial distribution
  # by adjusting mu and adding 1
  t = -log(1 - runif(ndraws) * (1 - exp(-mu)))
  shape <- get_shape(draws$shape, data = draws$data, i = i)
  ifelse(hu < theta, 0, rnbinom(ndraws, mu = mu - t, size = shape) + 1)
}

predict_hurdle_gamma <- function(i, draws, ...) {
  # theta is the bernoulli hurdle parameter
  theta <- get_theta(draws, i, par = "hu")
  shape <- get_shape(draws$shape, data = draws$data, i = i)
  scale <- ilink(get_eta(draws, i), draws$f$link) / shape
  ndraws <- draws$nsamples
  # compare with theta to incorporate the hurdle process
  hu <- runif(ndraws, 0, 1)
  ifelse(hu < theta, 0, rgamma(ndraws, shape = shape, scale = scale))
}

predict_hurdle_lognormal <- function(i, draws, ...) {
  # theta is the bernoulli hurdle parameter
  theta <- get_theta(draws, i, par = "hu")
  mu <- ilink(get_eta(draws, i), draws$f$link)
  sigma <- get_sigma(draws$sigma, data = draws$data, i = i)
  ndraws <- draws$nsamples
  # compare with theta to incorporate the hurdle process
  hu <- runif(ndraws, 0, 1)
  ifelse(hu < theta, 0, rlnorm(ndraws, meanlog = mu, sdlog = sigma))
}

predict_zero_inflated_beta <- function(i, draws, ...) {
  # theta is the bernoulli hurdle parameter
  theta <- get_theta(draws, i, par = "zi")
  mu <- ilink(get_eta(draws, i), draws$f$link)
  phi <- get_auxpar(draws$phi, i = i)
  # compare with theta to incorporate the hurdle process
  hu <- runif(draws$nsamples, 0, 1)
  ifelse(hu < theta, 0, rbeta(draws$nsamples, shape1 = mu * phi, 
                              shape2 = (1 - mu) * phi))
}

predict_zero_inflated_poisson <- function(i, draws, ...) {
  # theta is the bernoulli zero-inflation parameter
  theta <- get_theta(draws, i, par = "zi")
  lambda <- ilink(get_eta(draws, i), draws$f$link)
  ndraws <- draws$nsamples
  # compare with theta to incorporate the zero-inflation process
  zi <- runif(ndraws, 0, 1)
  ifelse(zi < theta, 0, rpois(ndraws, lambda = lambda))
}

predict_zero_inflated_negbinomial <- function(i, draws, ...) {
  # theta is the bernoulli zero-inflation parameter
  theta <- get_theta(draws, i, par = "zi")
  mu <- ilink(get_eta(draws, i), draws$f$link)
  shape <- get_shape(draws$shape, data = draws$data, i = i)
  ndraws <- draws$nsamples
  # compare with theta to incorporate the zero-inflation process
  zi <- runif(ndraws, 0, 1)
  ifelse(zi < theta, 0, rnbinom(ndraws, mu = mu, size = shape))
}

predict_zero_inflated_binomial <- function(i, draws, ...) {
  # theta is the bernoulii zero-inflation parameter
  theta <- get_theta(draws, i, par = "zi")
  trials <- draws$data$trials[i]
  prob <- ilink(get_eta(draws, i), draws$f$link)
  ndraws <- draws$nsamples
  # compare with theta to incorporate the zero-inflation process
  zi <- runif(ndraws, 0, 1)
  ifelse(zi < theta, 0, rbinom(ndraws, size = trials, prob = prob))
}

predict_categorical <- function(i, draws, ...) {
  ncat <- draws$data$ncat
  p <- pcategorical(1:ncat, eta = get_eta(draws, i)[, 1, ], 
                    ncat = ncat, link = draws$f$link)
  first_greater(p, target = runif(draws$nsamples, min = 0, max = 1))
}

predict_cumulative <- function(i, draws, ...) {
  predict_ordinal(i = i, draws = draws, family = "cumulative")
}

predict_sratio <- function(i, draws, ...) {
  predict_ordinal(i = i, draws = draws, family = "sratio")
}

predict_cratio <- function(i, draws, ...) {
  predict_ordinal(i = i, draws = draws, family = "cratio")
}

predict_acat <- function(i, draws, ...) {
  predict_ordinal(i = i, draws = draws, family = "acat")
}  

predict_ordinal <- function(i, draws, family, ...) {
  ncat <- draws$data$ncat
  disc <- get_disc(draws, i, ncat)
  eta <- (disc * get_eta(draws, i))[, 1, ]
  p <- pordinal(1:ncat, eta = eta, ncat = ncat, 
                family = family, link = draws$f$link)
  first_greater(p, target = runif(draws$nsamples, min = 0, max = 1))
}

#---------------predict helper-functions----------------------------

rng_continuous <- function(nrng, dist, args, lb = NULL, ub = NULL) {
  # random numbers from (possibly truncated) continuous distributions
  # Args:
  #   nrng: number of random values to generate
  #   dist: name of a distribution for which the functions
  #         p<dist>, q<dist>, and r<dist> are available
  #   args: dditional arguments passed to the distribution functions
  # Returns:
  #   a vector of random values draws from the distribution
  if (is.null(lb) && is.null(ub)) {
    # sample as usual
    rdist <- paste0("r", dist)
    out <- do.call(rdist, c(nrng, args))
  } else {
    # sample from truncated distribution
    if (is.null(lb)) lb <- -Inf
    if (is.null(ub)) ub <- Inf
    pdist <- paste0("p", dist)
    qdist <- paste0("q", dist)
    plb <- do.call(pdist, c(list(lb), args))
    pub <- do.call(pdist, c(list(ub), args))
    rng <- list(runif(nrng, min = plb, max = pub))
    out <- do.call(qdist, c(rng, args))
    # remove infinte values caused by numerical imprecision
    out[out %in% c(-Inf, Inf)] <- NA
  }
  out
}

rng_discrete <- function(nrng, dist, args, lb = NULL, ub = NULL, ntrys = 5) {
  # random numbers from (possibly truncated) discrete distributions
  # currently rejection sampling is used for truncated distributions
  # Args:
  #   nrng: number of random values to generate
  #   dist: name of a distribution for which the functions
  #         p<dist>, q<dist>, and r<dist> are available
  #   args: dditional arguments passed to the distribution functions
  #   lb: optional lower truncation bound
  #   ub: optional upper truncation bound
  #   ntrys: number of trys in rejection sampling for truncated models
  # Returns:
  #   a vector of random values draws from the distribution
  rdist <- get(paste0("r", dist), mode = "function")
  if (is.null(lb) && is.null(ub)) {
    # sample as usual
    do.call(rdist, c(nrng, args))
  } else {
    # sample from truncated distribution via rejection sampling
    if (is.null(lb)) lb <- -Inf
    if (is.null(ub)) ub <- Inf
    rng <- matrix(do.call(rdist, c(nrng * ntrys, args)), ncol = ntrys)
    apply(rng, 1, extract_valid_sample, lb = lb, ub = ub)
  }
}

extract_valid_sample <- function(rng, lb, ub) {
  # extract the first valid predicted value 
  # per Stan sample per observation 
  # Args:
  #   rng: draws to be check against truncation boundaries
  #   lb: lower bound
  #   ub: upper bound
  # Returns:
  #   a valid truncated sample or else the closest boundary
  valid_rng <- match(TRUE, rng > lb & rng <= ub)
  if (is.na(valid_rng)) {
    # no valid truncated value found
    # set sample to lb or ub
    # 1e-10 is only to identify the invalid draws later on
    ifelse(max(rng) <= lb, lb + 1 - 1e-10, ub + 1e-10)
  } else {
    rng[valid_rng]
  }
}

get_pct_invalid <- function(x, lb = NULL, ub = NULL) {
  # percentage of invalid predictions of truncated discrete models
  # Args:
  #   x: matrix of predicted values
  #   lb: optional lower truncation bound
  #   ub: optional upper truncation bound
  if (!(is.null(lb) && is.null(ub))) {
    if (is.null(lb)) lb <- -Inf
    if (is.null(ub)) ub <- Inf
    # ensures correct comparison with vector bounds
    x <- c(t(x))
    sum(x <= lb | x > ub, na.rm = TRUE) / length(x[!is.na(x)]) 
  } else {
    0
  }
}