  /* hurdle poisson log-PDF of a single response 
   * Args: 
   *   y: the response value 
   *   eta: linear predictor for poisson part 
   *   hu: hurdle probability
   * Returns:  
   *   a scalar to be added to the log posterior 
   */ 
   real hurdle_poisson_lpmf(int y, real eta, real hu) { 
     if (y == 0) { 
       return bernoulli_lpmf(1 | hu); 
     } else { 
       return bernoulli_lpmf(0 | hu) +  
              poisson_log_lpmf(y | eta) - 
              log1m_exp(-exp(eta)); 
     } 
   }
  /* hurdle poisson log-PDF of a single response 
   * logit parameterization of the hurdle part
   * Args: 
   *   y: the response value 
   *   eta: linear predictor for poisson part 
   *   eta_hu: linear predictor for hurdle part 
   * Returns:  
   *   a scalar to be added to the log posterior 
   */ 
   real hurdle_poisson_logit_lpmf(int y, real eta, real eta_hu) { 
     if (y == 0) { 
       return bernoulli_logit_lpmf(1 | eta_hu); 
     } else { 
       return bernoulli_logit_lpmf(0 | eta_hu) +  
              poisson_log_lpmf(y | eta) - 
              log1m_exp(-exp(eta)); 
     } 
   }
