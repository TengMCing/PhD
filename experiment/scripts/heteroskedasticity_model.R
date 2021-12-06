HETEROSKEDASTICITY_MODEL <- function(a, b,
                                     x_dist = "uniform", z_discrete = FALSE,
                                     ...) {

  # Init a new model
  model <- MODEL_SPEC(type = "heteroskedasticity",
                      formula = "y ~ 1 + x + e, e ~ N(0, 1 + (2-|a|) * (x_i - a)^2 * b)",
                      a = a, b = b,
                      x_dist = x_dist, z_discrete = z_discrete,
                      ...)

  # Method of generating e
  model$gen_e <- function(x, n) {

    sigma2_i <- 1 +
      (2 - abs(model$parameters$a)) * (x[,1] - model$parameters$a)^2 * model$parameters$b

    sigma_i <- sqrt(sigma2_i)

    result <- data.frame(single_sigma = sigma_i) %>%
      rowwise() %>%
      mutate(e = rnorm(1, sd = single_sigma))

    return(result$e)
  }

  # Method of generating y
  model$gen_y <- function(n) {
    x <- model$gen_x(n)
    e <- model$gen_e(x, n)

    y <- 1 + x[,1] + e
    return(data.frame(x = x[,1], z = x[,2], y = y))
  }

  model$fit <- function(dat) {
    lm(y ~ x, data = dat)
  }

  # Method of evaluating the data using numerical test
  model$evaluate <- function(dat) {

    mod <- lm(y ~ x, data = dat)

    tmp_data <- data.frame(x = dat$x)
    tmp_data$xs <- tmp_data$x^2

    this_bp_test <- lmtest::bptest(mod, varformula = ~ x + xs, data = tmp_data)

    return(list("bptest", unname(this_bp_test$statistic), unname(this_bp_test$p.value)))
  }

  model$effect_size <- function(dat) {

    return(model$parameters$b * sqrt(nrow(dat)))
  }

  return(model)
}
