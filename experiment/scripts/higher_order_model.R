HIGHER_ORDER_MODEL <- function(a, b, c = 1,
                               x_dist = "uniform", z_discrete = FALSE,
                               e_dist = "normal", e_sigma = 1, ...) {

  # Init a new model
  model <- MODEL_SPEC(type = "higher order",
                      formula = "y ~ 1 + (2-c) * x + c * z + a * [(2-c) * x]^2 + a * (c * z)^2 + b * [(2-c) * x]^3 + b * (c * z)^3 + e, e ~ N(0, sigma^2)",
                      a = a, b = b, c = c,
                      x_dist = x_dist, z_discrete = z_discrete,
                      e_dist = e_dist, e_sigma = e_sigma, ...)

  # Method of generating y
  model$gen_y <- function(n) {
    x <- model$gen_x(n)

    y <- (2 - model$parameters$c) * x[,1] + model$parameters$c * x[,2] +
      model$parameters$a * ((2 - model$parameters$c) * x[,1])^2 + model$parameters$a * (model$parameters$c * x[,2])^2 +
      model$parameters$b * ((2 - model$parameters$c) * x[,1])^3 + model$parameters$b * (model$parameters$c * x[,2])^3 +
      model$gen_e(n) + 1

    return(data.frame(x = x[,1], z = x[,2], y))

  }

  model$fit <- function(dat) {
    lm(y ~ x + z, data = dat)
  }

  model$effect_size <- function(dat) {
    n <- nrow(dat)
    xa <- dat %>%
      mutate(c = 1) %>%
      select(c, x, z) %>%
      as.matrix()
    ra <- diag(n) - xa %*% solve(t(xa) %*% xa) %*% t(xa)
    diag_ra <- diag(sqrt(diag(ra)))
    xb <- dat %>%
      mutate(x2=x^2,z2=z^2,x3=x^3,z3=z^3) %>%
      select(x2, z2, x3, z3) %>%
      as.matrix()
    beta_b <- matrix(c(model$parameters$a,model$parameters$a,model$parameters$b,model$parameters$b))

    return((1/n) *
      (1/model$parameters$e_sigma^2) *
      sum((diag(sqrt(diag(ra))) %*% xb %*% beta_b)^2))
  }

  # Method of evaluating the data using numerical test
  model$evaluate <- function(dat) {

    correct_mod <- lm(y ~ x + I(x^2) + I(x^3) + z + I(z^2) + I(z^3), data = dat)
    wrong_mod <- lm(y ~ x + z, data = dat)

    this_F_test <- anova(wrong_mod, correct_mod, test = "F")

    return(list("F-test", this_F_test$F[2], this_F_test$`Pr(>F)`[2]))
  }

  return(model)
}
