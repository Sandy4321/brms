dstudent <- function(x, df, mu = 0, sigma = 1, log = FALSE) {
  # density of student's distribution 
  # Args:
  #  x: the value(s) at which the density should be evaluated
  #  df: degrees of freedom
  #  mu: the mean
  #  sigma: the scale parameter
  #  log: logical; return on log scale?
  if (log) {
    dt((x - mu) / sigma, df = df, log = TRUE) - log(sigma)
  } else {
    dt((x - mu) / sigma, df = df) / sigma
  }
}

pstudent <- function(q, df, mu = 0, sigma = 1, 
                     lower.tail = TRUE, log.p = FALSE) {
  # distribution function of student's distribution
  # Args:
  #  q: the value(s) at which the distribution should be evaluated
  #  df: degrees of freedom
  #  mu: the mean
  #  sigma: the scale parameter
  #  lower.tail: same as for every pdist function
  #  log.p: logical; return on log scale?
  pt((q - mu)/sigma, df = df, lower.tail = lower.tail, log.p = log.p)
}

qstudent <-  function(p, df, mu = 0, sigma = 1) {
  # quantiles of student's distribution
  # Args:
  #  p: the probabilities to find quantiles for
  #  df: degrees of freedom
  #  mu: the mean
  #  sigma: the scale parameter
  mu + sigma * qt(p, df = df)
}

rstudent <-  function(n, df, mu = 0, sigma = 1) {
  # random values of student's distribution 
  #
  # Args:
  #  n: number of random values
  #  df: degrees of freedom
  #  mu: the mean
  #  sigma: the scale parameter
  mu + sigma * rt(n, df = df)
}

dmulti_normal <- function(x, mu, Sigma, log = TRUE,
                          check = FALSE) {
  # density of the multivariate normal distribution 
  # not vectorized to increase speed when x is only a vector not a matrix
  # Args:
  #   x: the value(s) at which the density should be evaluated
  #   mu: mean vector
  #   sigma: covariance matrix
  #   log: return on log scale?
  #   check: check arguments for validity?
  # Returns:
  #   density of the multi_normal distribution a values x
  p <- length(x)
  if (check) {
    if (length(mu) != p) {
      stop2("Dimension of mu is incorrect.")
    }
    if (!all(dim(Sigma) == c(p, p))) {
      stop2("Dimension of Sigma is incorrect.")
    }
    if (!is_symmetric(Sigma)) {
      stop2("Sigma must be a symmetric matrix.")
    }
  }
  rooti <- backsolve(chol(Sigma), diag(p))
  quads <- colSums((crossprod(rooti, (x - mu)))^2)
  out <- -(p / 2) * log(2 * pi) + sum(log(diag(rooti))) - .5 * quads
  if (!log) {
    out <- exp(out)
  }
  out
}

rmulti_normal <- function(n, mu, Sigma, check = FALSE) {
  # random values of the multivariate normal distribution 
  # Args:
  #   n: number of random values
  #   mu: mean vector
  #   sigma: covariance matrix
  #   check: check arguments for validity?
  # Returns:
  #   n samples of multi_normal distribution of dimension length(mu) 
  p <- length(mu)
  if (check) {
    if (!(is_wholenumber(n) && n > 0)) {
      stop2("n must be a positive integer.")
    }
    if (!all(dim(Sigma) == c(p, p))) {
      stop2("Dimension of Sigma is incorrect.")
    }
    if (!is_symmetric(Sigma)) {
      stop2("Sigma must be a symmetric matrix.")
    }
  }
  samples <- matrix(rnorm(n * p), nrow = n, ncol = p)
  mu + samples %*% chol(Sigma)
}

dmulti_student <- function(x, df, mu, Sigma, log = TRUE,
                           check = FALSE) {
  # density of the multivariate student-t distribution 
  # Args:
  #   x: the value(s) at which the density should be evaluated
  #   df: degrees of freedom
  #   mu: mean vector
  #   sigma: covariance matrix
  #   log: return on log scale?
  #   check: check arguments for validity?
  # Returns:
  #   density of the multi_student distribution a values x
  if (is.vector(x)) {
    x <- matrix(x, ncol = length(x))
  }
  p <- ncol(x)
  if (check) {
    if (any(df <= 0)) {
      stop2("df must be greater than 0.")
    }
    if (length(mu) != p) {
      stop2("Dimension of mu is incorrect.")
    }
    if (!all(dim(Sigma) == c(p, p))) {
      stop2("Dimension of Sigma is incorrect.")
    }
    if (!is_symmetric(Sigma)) {
      stop2("Sigma must be a symmetric matrix.")
    }
  }
  chol_Sigma <- chol(Sigma)
  rooti <- backsolve(chol_Sigma, t(x) - mu, transpose = TRUE)
  quads <- colSums(rooti^2)
  out <- lgamma((p + df)/2) - (lgamma(df / 2) + sum(log(diag(chol_Sigma))) + 
         p / 2 * log(pi * df)) - 0.5 * (df + p) * log1p(quads / df)
  if (!log) {
    out <- exp(out)
  }
  out
}

rmulti_student <- function(n, df, mu, Sigma, log = TRUE, 
                           check = FALSE) {
  # random values of the multivariate student-t distribution 
  # Args:
  #   n: number of random values
  #   df: degrees of freedom
  #   mu: mean vector
  #   sigma: covariance matrix
  #   check: check arguments for validity?
  # Returns:
  #   n samples of multi_student distribution of dimension length(mu) 
  p <- length(mu)
  if (any(df <= 0)) {
    stop2("df must be greater than 0.")
  }
  samples <- rmulti_normal(n, mu = rep(0, p), Sigma = Sigma, check = check)
  samples <- samples / sqrt(rchisq(n, df = df) / df)
  sweep(samples, 2, mu, "+")
}

dvon_mises <- function(x, mu, kappa, log = FALSE) {
  # density function of the von Mises distribution
  # CircStats::dvm has support within [0, 2*pi], 
  # but in brms we use [-pi, pi]
  # Args:
  #    mu: location parameter
  #    kappa: precision parameter
  out <- CircStats::dvm(x + base::pi, mu + base::pi, kappa)
  if (log) {
    out <- log(out)
  }
  out
}

pvon_mises <- function(q, mu, kappa, lower.tail = TRUE, 
                       log.p = FALSE, ...) {
  # distribution function of the von Mises distribution
  q <- q + base::pi
  mu <- mu + base::pi
  # vectorized version of CircStats::pvm
  .pvon_mises <- Vectorize(
    CircStats::pvm, 
    c("theta", "mu", "kappa")
  )
  out <- .pvon_mises(q, mu, kappa, ...)
  if (!lower.tail) {
    out <- 1 - out
  }
  if (log.p) {
    out <- log(out)
  }
  out
}

rvon_mises <- function(n, mu, kappa) {
  # sample random numbers from the von Mises distribution
  stopifnot(n %in% c(1, max(length(mu), length(kappa))))
  mu <- mu + base::pi
  # vectorized version of CircStats::rvm
  .rvon_mises <- Vectorize(
    CircStats::rvm, 
    c("mean", "k")
  )
  .rvon_mises(1, mu, kappa) - base::pi
}

dexgaussian <- function(x, mu, sigma, beta, log = FALSE) {
  # PDF of the exponentially modified gaussian distribution
  # Args:
  #   mu: mean of the gaussian comoponent
  #   sigma: SD of the gaussian comoponent
  #   beta: scale / inverse rate of the exponential component
  if (any(sigma <= 0)) {
    stop2("sigma must be greater than 0.")
  }
  if (any(beta <= 0)) {
    stop2("beta must be greater than 0.")
  }
  z <- x - mu - sigma^2 / beta
  out <- ifelse(beta > 0.05 * sigma, 
    -log(beta) - (z + sigma^2 / (2 * beta)) / beta + log(pnorm(z / sigma)),
    dnorm(x, mean = mu, sd = sigma, log = TRUE))
  if (!log) {
    out <- exp(out)
  }
  out
}

pexgaussian <- function(q, mu, sigma, beta, 
                        lower.tail = TRUE, log.p = FALSE) {
  # CDF of the exponentially modified gaussian distribution
  # Args:
  #   see dexgauss
  if (any(sigma <= 0)) {
    stop2("sigma must be greater than 0.")
  }
  if (any(beta <= 0)) {
    stop2("beta must be greater than 0.")
  }
  z <- q - mu - sigma^2 / beta
  out <- ifelse(beta > 0.05 * sigma, 
    pnorm((q - mu) / sigma) - pnorm(z / sigma) * 
      exp(((mu + sigma^2 / beta)^2 - mu^2 - 2 * q * sigma^2 / beta) / 
            (2 * sigma^2)), 
    pnorm(q, mean = mu, sd = sigma))
  if (!lower.tail) {
    out <- 1 - out
  } 
  if (log.p) {
    out <- log(out) 
  } 
  out
}

rexgaussian <- function(n, mu, sigma, beta) {
  # create random numbers of the exgaussian distribution
  # Args:
  #   see dexgauss
  if (any(sigma <= 0)) {
    stop2("sigma must be greater than 0.")
  }
  if (any(beta <= 0)) {
    stop2("beta must be greater than 0.")
  }
  rnorm(n, mean = mu, sd = sigma) + rexp(n, rate = 1 / beta)
}

#' @import evd
pfrechet <- function(q, loc = 0, scale = 1, shape = 1, 
                     lower.tail = TRUE, log.p = FALSE) {
  # just evd::pfrechet but with argument log.p
  out <- evd::pfrechet(q, loc = loc, scale = scale, shape = shape,
                       lower.tail = lower.tail)
  if (log.p) {
    out <- log(out)
  }
  out
}

dgen_extreme_value <- function(x, mu = 0, sigma = 1, 
                               xi = 0, log = FALSE) {
  # pdf of the generalized extreme value distribution
  # Args:
  #   mu: location parameter
  #   sigma: scale parameter
  #   xi: shape parameter
  if (any(sigma <= 0)) {
    stop2("sigma bust be greater than 0.")
  }
  x <- (x - mu) / sigma
  if (length(xi) == 1L) {
    xi <- rep(xi, length(x))
  }
  t <- 1 + xi * x
  out <- ifelse(
    xi == 0, 
    - log(sigma) - x - exp(-x),
    - log(sigma) - (1 + 1 / xi) * log(t) - t^(-1 / xi)
  )
  if (!log) {
    out <- exp(out)
  } 
  out
}

pgen_extreme_value <- function(q, mu = 0, sigma = 1, xi = 0,
                               lower.tail = TRUE, log.p = FALSE) {
  # cdf of the generalized extreme value distribution
  if (any(sigma <= 0)) {
    stop2("sigma bust be greater than 0.")
  }
  q <- (q - mu) / sigma
  if (length(xi) == 1L) {
    xi <- rep(xi, length(q))
  }
  out <- ifelse(
    xi == 0, 
    exp(-exp(-q)),
    exp(-(1 + xi * q)^(-1 / xi))
  )
  if (!lower.tail) {
    out <- 1 - out
  }
  if (log.p) {
    out <- log(out)
  }
  out
}

rgen_extreme_value <- function(n, mu = 0, sigma = 1, xi = 0) {
  # random numbers of the generalized extreme value distribution
  if (any(sigma <= 0)) {
    stop2("sigma bust be greater than 0.")
  }
  if (length(xi) == 1L) {
    xi <- rep(xi, max(n, length(mu), length(sigma)))
  }
  ifelse(
    xi == 0,
    mu - sigma * log(rexp(n)),
    mu + sigma * (rexp(n)^(-xi) - 1) / xi
  )
}

dasym_laplace <- function(y, mu = 0, sigma = 1, quantile = 0.5, 
                          log = FALSE) {
  # pdf of the asymmetric laplace distribution
  # Args:
  #   mu: location parameter
  #   sigma: scale parameter
  #   quantile: quantile parameter
  out <- ifelse(y < mu, 
    yes = (quantile * (1 - quantile) / sigma) * 
           exp((1 - quantile) * (y - mu) / sigma),
    no = (quantile * (1 - quantile) / sigma) * 
          exp(-quantile * (y - mu) / sigma)
  )
  if (log) {
    out <- log(out)
  }
  out
}

pasym_laplace <- function(q, mu = 0, sigma = 1, quantile = 0.5,
                          lower.tail = TRUE, log.p = FALSE) {
  # cdf of the asymmetric laplace distribution
  out <- ifelse(q < mu, 
    yes = quantile * exp((1 - quantile) * (q - mu) / sigma), 
    no = 1 - (1 - quantile) * exp(-quantile * (q - mu) / sigma)
  )
  if (!lower.tail) {
    out <- 1 - out
  }
  if (log.p) {
    out <- log(out) 
  }
  out
}

qasym_laplace <- function(p, mu = 0, sigma = 1, quantile = 0.5,
                          lower.tail = TRUE, log.p = FALSE) {
  # quantile function of the asymmetric laplace distribution
  if (log.p) {
    p <- exp(p)
  }
  if (!lower.tail) {
    p <- 1 - p
  }
  if (length(quantile) == 1L) {
    quantile <- rep(quantile, length(mu))
  }
  ifelse(p < quantile, 
    yes = mu + ((sigma * log(p / quantile)) / (1 - quantile)), 
    no = mu - ((sigma * log((1 - p) / (1 - quantile))) / quantile)
  )
}

rasym_laplace <- function(n, mu = 0, sigma = 1, quantile = 0.5) {
  # random numbers of the asymmetric laplace distribution
  u <- runif(n)
  qasym_laplace(u, mu = mu, sigma = sigma, quantile = quantile)
}

dWiener <- function(x, alpha, tau, beta, delta, resp = 1, log = FALSE) {
  # compute the density of the Wiener diffusion model
  # Args:
  #   see RWiener::dwiener
  alpha <- as.numeric(alpha)
  tau <- as.numeric(tau)
  beta <- as.numeric(beta)
  delta <- as.numeric(delta)
  if (!is.character(resp)) {
    resp <- ifelse(resp, "upper", "lower") 
  }
  # vectorized version of RWiener::dwiener
  .dWiener <- Vectorize(
    RWiener::dwiener, 
    c("alpha", "tau", "beta", "delta")
  )
  args <- nlist(q = x, alpha, tau, beta, delta, resp, give_log = log)
  do.call(.dWiener, args)
}

rWiener <- function(n, alpha, tau, beta, delta, col = NULL) {
  # create random numbers of the Wiener diffusion model
  # Args:
  #   see RWiener::rwiener
  #   col: which response to return (RTs or decision or both)?
  alpha <- as.numeric(alpha)
  tau <- as.numeric(tau)
  beta <- as.numeric(beta)
  delta <- as.numeric(delta)
  max_len <- max(lengths(list(alpha, tau, beta, delta)))
  n <- n[1]
  if (max_len > 1L) {
    if (!n %in% c(1, max_len)) {
      stop2("Can only sample exactly once for each condition.")
    }
    n <- 1
  }
  .rWiener <- function(...) {
    # vectorized version of RWiener::rwiener
    # returns a numeric vector
    fun <- Vectorize(
      rwiener_num, 
      c("alpha", "tau", "beta", "delta"),
      SIMPLIFY = FALSE
    )
    do.call(rbind, fun(...))
  }
  args <- nlist(n, alpha, tau, beta, delta, col)
  do.call(.rWiener, args)
}

rwiener_num <- function(n, alpha, tau, beta, delta, col = NULL) {
  # helper function to return a numeric vector instead
  # of a data.frame with two columns as for RWiener::rwiener
  out <- RWiener::rwiener(n, alpha, tau, beta, delta)
  if (length(col) == 1L && col %in% c("q", "resp")) {
    out <- out[[col]]
    if (col == "resp") {
      out <- ifelse(out == "upper", 1, 0)
    }
  }
  out
}

dcategorical <- function(x, eta, ncat, link = "logit") {
  # density of the categorical distribution
  # Args:
  #   x: positive integers not greater than ncat
  #   eta: the linear predictor (of length or ncol ncat-1)  
  #   ncat: the number of categories
  #   link: the link function
  # Returns:
  #   probabilities P(X = x)
  if (is.null(dim(eta))) {
    eta <- matrix(eta, nrow = 1)
  }
  if (length(dim(eta)) != 2) {
    stop2("eta must be a numeric vector or matrix.")
  }
  if (missing(ncat)) {
    ncat <- ncol(eta) + 1
  }
  if (link == "logit") {
    p <- exp(cbind(rep(0, nrow(eta)), eta[, 1:(ncat - 1)]))
  } else {
    stop2("Link ", link, " not supported.")
  }
  p <- p / rowSums(p)
  p[, x]
}

pcategorical <- function(q, eta, ncat, link = "logit") {
  # distribution functions for the categorical family
  # Args:
  #   q: positive integers not greater than ncat
  #   eta: the linear predictor (of length or ncol ncat-1)  
  #   ncat: the number of categories
  #   link: a character string naming the link
  # Retruns: 
  #   probabilities P(x <= q)
  p <- dcategorical(1:max(q), eta = eta, ncat = ncat, link = link)
  do.call(cbind, lapply(q, function(j) rowSums(as.matrix(p[, 1:j]))))
}

dcumulative <- function(x, eta, ncat, link = "logit") {
  # density of the cumulative distribution
  # Args: same as dcategorical
  if (is.null(dim(eta))) {
    eta <- matrix(eta, nrow = 1)
  }
  if (length(dim(eta)) != 2) {
    stop2("eta must be a numeric vector or matrix.")
  }
  if (missing(ncat)) {
    ncat <- ncol(eta) + 1
  }
  mu <- ilink(eta, link)
  rows <- list(mu[, 1])
  if (ncat > 2) {
    .fun <- function(k) {
      mu[, k] - mu[, k - 1]
    }
    rows <- c(rows, lapply(2:(ncat - 1), .fun))
  }
  rows <- c(rows, list(1 - mu[, ncat - 1]))
  p <- do.call(cbind, rows)
  p[, x]
}

dsratio <- function(x, eta, ncat, link = "logit") {
  # density of the sratio distribution
  # Args: same as dcategorical
  if (is.null(dim(eta))) {
    eta <- matrix(eta, nrow = 1)
  }
  if (length(dim(eta)) != 2) {
    stop2("eta must be a numeric vector or matrix.")
  }
  if (missing(ncat)) {
    ncat <- ncol(eta) + 1
  }
  mu <- ilink(eta, link)
  rows <- list(mu[, 1])
  if (ncat > 2) {
    .fun <- function(k) {
      (mu[, k]) * apply(as.matrix(1 - mu[, 1:(k - 1)]), 1, prod)
    }
    rows <- c(rows, lapply(2:(ncat - 1), .fun))
  }
  rows <- c(rows, list(apply(1 - mu, 1, prod)))
  p <- do.call(cbind, rows)
  p[, x]
}

dcratio <- function(x, eta, ncat, link = "logit") {
  # density of the cratio distribution
  # Args: same as dcategorical
  if (is.null(dim(eta))) {
    eta <- matrix(eta, nrow = 1)
  }
  if (length(dim(eta)) != 2) {
    stop2("eta must be a numeric vector or matrix.")
  }
  if (missing(ncat)) {
    ncat <- ncol(eta) + 1
  }
  mu <- ilink(eta, link)
  rows <- list(1 - mu[, 1])
  if (ncat > 2) {
    .fun <- function(k) {
      (1 - mu[, k]) * apply(as.matrix(mu[, 1:(k - 1)]), 1, prod)
    }
    rows <- c(rows, lapply(2:(ncat - 1), .fun))
  }
  rows <- c(rows, list(apply(mu, 1, prod)))
  p <- do.call(cbind, rows)
  p[, x]
}

dacat <- function(x, eta, ncat, link = "logit") {
  # density of the acat distribution
  # Args: same as dcategorical
  if (is.null(dim(eta))) {
    eta <- matrix(eta, nrow = 1)
  }
  if (length(dim(eta)) != 2) {
    stop2("eta must be a numeric vector or matrix.")
  }
  if (missing(ncat)) {
    ncat <- ncol(eta) + 1
  }
  if (link == "logit") { 
    # faster evaluation in this case
    p <- cbind(rep(1, nrow(eta)), exp(eta[,1]), 
               matrix(NA, nrow = nrow(eta), ncol = ncat - 2))
    if (ncat > 2) {
      .fun <- function(k) {
        rowSums(eta[, 1:(k-1)])
      }
      p[, 3:ncat] <- exp(sapply(3:ncat, .fun))
    }
  } else {
    mu <- ilink(eta, link)
    p <- cbind(apply(1 - mu[,1:(ncat - 1)], 1, prod), 
               matrix(0, nrow = nrow(eta), ncol = ncat - 1))
    if (ncat > 2) {
      .fun <- function(k) {
        apply(as.matrix(mu[, 1:(k - 1)]), 1, prod) * 
          apply(as.matrix(1 - mu[, k:(ncat - 1)]), 1, prod)
      }
      p[, 2:(ncat - 1)] <- sapply(2:(ncat - 1), .fun)
    }
    p[, ncat] <- apply(mu[, 1:(ncat - 1)], 1, prod)
  }
  p <- p / rowSums(p)
  p[, x]
}

pordinal <- function(q, eta, ncat, family, link = "logit") {
  # distribution functions for ordinal families
  # Args:
  #   q: positive integers not greater than ncat
  #   eta: the linear predictor (of length or ncol ncat-1)  
  #   ncat: the number of categories
  #   family: a character string naming the family
  #   link: a character string naming the link
  # Returns: 
  #   probabilites P(x <= q)
  args <- list(1:max(q), eta = eta, ncat = ncat, link = link)
  p <- do.call(paste0("d", family), args)
  .fun <- function(j) {
    rowSums(as.matrix(p[, 1:j]))
  }
  do.call(cbind, lapply(q, .fun))
}
