NON_NORMAL_MODEL <- function(c = 5,
                             x_dist = "uniform", z_discrete = FALSE,
                             e_dist = "t", ...) {

  # Init a model
  model <- MODEL_SPEC(type = "non-normal error",
                      formula = "y ~ 1 + x + c * z + e, e ~ non-normal",
                      c = c,
                      x_dist = x_dist, z_discrete = z_discrete,
                      e_dist = e_dist, ...)

  # Method of generating y
  model$gen_y <- function(n) {
    x <- model$gen_x(n)
    e <- model$gen_e(n)
    y <- x[,1] + x[,2] * model$parameters$c + e + 1

    return(data.frame(x = x[,1], z = x[,2], y = y))

  }

  # Method of evaluating the data using numerical test
  model$evaluate <- function(dat) {

    mod <- lm(y ~ x + z, data = dat)

    this_sw_test <- shapiro.test(resid(mod))

    return(list("swtest", unname(this_sw_test$statistic), unname(this_sw_test$p.value)))
  }

  return(model)
}
