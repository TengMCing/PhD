library(visage)

conv_test_cubic <- function() {
  para_list1 <- list(a = runif(1, -3, 3),
                     b = runif(1, -3, 3),
                     c = runif(1, 0, 2),
                     x_dist = sample(c("uniform", "normal", "lognormal", "neglognormal"), 1),
                     x_mu = 0,
                     x_n = NA,
                     x_sigma = sample(c(0.3, 0.6), 1),
                     z_discrete = sample(c(TRUE, FALSE), 1),
                     z_discrete_dist = "discrete_uniform",
                     z_n = sample(3:10, 1),
                     e_dist = "normal",
                     e_df = NA,
                     e_sigma = sample(c(0.25, 0.5, 1, 2), 1),
                     n = sample(c(50, 100, 300), 1))

  if (para_list1$x_dist == "normal") {para_list1$x_sigma <- 0.3} else {para_list1$x_sigma <- 0.6}

  # Init X and Z based on the parameter list
  x <- switch (para_list1$x_dist ,
               "uniform" = rand_uniform(-1, 1),
               "normal" = rand_normal(0, para_list1$x_sigma),
               "lognormal" = rand_lognormal(0, para_list1$x_sigma),
               "neglognormal" = {rl <- rand_lognormal(0, para_list1$x_sigma); closed_form(~-rl)}
  )

  if (para_list1$z_discrete) {z <- rand_uniform(-1, 1)} else {z <- rand_uniform_d(-1, 1, para_list1$z_n)}


  # Build the cubic model
  mod <- cubic_model(a = para_list1$a, b = para_list1$b, c = para_list1$c,
                     sigma = para_list1$e_sigma,
                     x = x, z = z)

  # Generate data from the model, let k = 2 (50% true data plot, 50% null plot)
  dat <- mod$gen(para_list1$n, fit_model = TRUE, test = TRUE)

  c(mod$effect_size(dat), dat$p_value[1])
}

conv_test_heter <- function() {
  para_list1 <- list(a = sample(c(-1, 0, 1), 1),
                     b = runif(1, 0, 32),
                     c = NA,
                     x_dist = sample(c("uniform", "normal", "lognormal", "neglognormal", "discrete_uniform"), 1),
                     x_mu = 0,
                     x_n = sample(10:20, 1),
                     x_sigma = sample(c(0.3, 0.6), 1),
                     z_discrete = FALSE,
                     z_discrete_dist = NA,
                     z_n = NA,
                     e_dist = NA,
                     e_df = NA,
                     e_sigma = NA,
                     n = sample(c(50, 100, 300), 1))

  if (para_list1$x_dist == "normal") {para_list1$x_sigma <- 0.3} else {para_list1$x_sigma <- 0.6}

  # Init X and Z based on the parameter list
  x <- switch (para_list1$x_dist ,
               "uniform" = rand_uniform(-1, 1),
               "discrete_uniform" = rand_uniform_d(-1, 1, para_list1$x_n),
               "normal" = rand_normal(0, para_list1$x_sigma),
               "lognormal" = rand_lognormal(0, para_list1$x_sigma),
               "neglognormal" = {rl <- rand_lognormal(0, para_list1$x_sigma); closed_form(~-rl)}
  )

  # Build the cubic model
  mod <- heter_model(a = para_list1$a, b = para_list1$b,
                     x = x)

  # Generate data from the model, let k = 2 (50% true data plot, 50% null plot)
  dat <- mod$gen(para_list1$n, fit_model = TRUE, test = TRUE)

  c(mod$effect_size(dat), dat$p_value[1])
}



get_sim_conv <- function() {
  conv_result_cubic <- map(1:5000, ~conv_test_cubic())

  conv_result_cubic <- data.frame(effect_size = map_dbl(conv_result_cubic, ~.x[1]),
                                  p_value = map_dbl(conv_result_cubic, ~.x[2])) %>%
    mutate(reject = p_value < 0.05) %>%
    mutate(reject = as.numeric(reject))

  conv_result_cubic <- conv_result_cubic %>%
    filter(log(effect_size) > -5) %>%
    mutate(type = "cubic")

  conv_result_heter <- map(1:50000, ~conv_test_heter())

  conv_result_heter <- data.frame(effect_size = map_dbl(conv_result_heter, ~.x[1]),
                                  p_value = map_dbl(conv_result_heter, ~.x[2])) %>%
    mutate(reject = p_value < 0.05) %>%
    mutate(reject = as.numeric(reject))

  conv_result_heter <- conv_result_heter %>%
    filter(log(effect_size) > -3) %>%
    mutate(type = "heteroskedasticity")

  conv_result <- bind_rows(conv_result_cubic, conv_result_heter)

  return(conv_result)
}

