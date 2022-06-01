# a in -1.5 ~ 1.5
# b in -1.5 ~ 1.5
# x_dist = uniform, normal, lognormal, neglognormal, even_dis, uneven_dis
# N = 50, 100, 300
# rep = 2
# e_sigma = 0.125, 0.25, 0.5, 1

# N_ab * 6 * 3 * 2 * 4

library(tidyverse)
library(visage)
library(lhs)

get_trunc_norm_cdf <- function(sd = 1, ndraws = 10^7) {
  result <- rnorm(ndraws, mean = 0, sd = sd)
  result <- result[result >= -1.5 & result <= 1.5]
  function(p) {
    quantile(result, probs = p) %>%
      unname()
  }
}

trans_unif_2_norm <- function(x, sd = 1, ndraws = 10^7) {
  p_trunc_norm <- get_trunc_norm_cdf(sd, ndraws)
  p_trunc_norm(x)
}

sim_effect_size <- function(a, b) {
  x_dist <- sample(c("uniform", "normal", "lognormal", "neglognormal",
                     "even_discrete", "uneven_discrete"), 1)
  e_sigma <- sample(c(0.125, 0.25, 0.5, 1), 1)
  n <- sample(c(50, 100, 300), 1)

  x <- switch(x_dist,
              uniform = rand_uniform(-1, 1),
              normal = rand_normal(sigma = 0.3),
              lognormal = rand_lognormal(sigma = 0.6),
              neglognormal = {rl <- rand_lognormal(sigma = 0.6); closed_form(~-rl)},
              even_discrete = rand_uniform_d(k = 5, even = TRUE),
              uneven_discrete = rand_uniform_d(k = 5, even = FALSE))

  mod <- simple_cubic_model(a = a, b = b, x = x, sigma = e_sigma)
  dat <- mod$gen(n, fit_model = FALSE)
  tibble(a, b, x_dist, e_sigma, n, effect_size = mod$effect_size(dat))
}


result <- map(1:10000, ~sim_effect_size(1, 1)) %>%
  reduce(bind_rows)

result %>%
  group_by(x_dist, e_sigma, n) %>%
  summarise(mine = min(log(effect_size)), maxe = max(log(effect_size)), effect_size = effect_size) %>%
  ggplot() +
  geom_boxplot(aes(x = log(effect_size), y = e_sigma, group = e_sigma), orientation = "y") +
  facet_wrap(x_dist~n)



# Shape of the trunc density
ggplot() +
  geom_density(aes(trans_unif_2_norm(seq(0, 1, 0.00001))), col = "red")

# Generate 2-dim LHS values (30 combinations)
library(ggExtra)
randomLHS(500, 2) %>%
  as.data.frame() %>%
  mutate(V1 = trans_unif_2_norm(V1, sd = 0.5),
         V2 = trans_unif_2_norm(V2, sd = 0.5)) %>%
  ggplot() +
  geom_point(aes(V1, V2)) -> p

ggMarginal(p, type = "density")




kl_divergence <- function(dat, a, b, sigma) {
  n <- nrow(dat)
  Xa <- as.matrix(data.frame(1, dat$x))
  Ra <- diag(n) - Xa %*% solve(t(Xa) %*% Xa) %*% t(Xa)
  Xb <- as.matrix(data.frame(dat$x^2, dat$x^3))
  beta_b <- matrix(c(a, b))

  sigma_1 <- sigma^2 * diag(diag(Ra))
  sigma_2 <- sigma^2 * diag(diag(Ra))
  mu_1 <- matrix(0, nrow = n)
  mu_2 <- Ra %*% Xb %*% beta_b

  # sum(log(diag(sigma_2)/diag(sigma_1))) - n + sum(diag(solve(sigma_2) %*% sigma_1))
  # log(det A/ det A) = log(1) = 0
  # solve(sigma_2) %*% sigma_1 = I_n
  # sum(diag(I_n)) = n
  # -n + n = 0
  result <- (t(mu_2 - mu_1) %*% solve(sigma_2) %*% (mu_2 - mu_1))/2

  if (is.na(result)) browser()
}


sim_effect_size_kl <- function(a, b) {
  x_dist <- sample(c("uniform", "normal", "lognormal", "neglognormal",
                     "even_discrete", "uneven_discrete"), 1)
  e_sigma <- sample(c(0.125, 0.25, 0.5, 1), 1)
  n <- sample(c(50, 100, 300), 1)

  x <- switch(x_dist,
              uniform = rand_uniform(-1, 1),
              normal = rand_normal(sigma = 0.3),
              lognormal = rand_lognormal(sigma = 0.6),
              neglognormal = {rl <- rand_lognormal(sigma = 0.6); closed_form(~-rl)},
              even_discrete = rand_uniform_d(k = 5, even = TRUE),
              uneven_discrete = rand_uniform_d(k = 5, even = FALSE))

  mod <- simple_cubic_model(a = a, b = b, x = x, sigma = e_sigma)
  dat <- mod$gen(n, fit_model = FALSE)
  tibble(a, b, x_dist, e_sigma, n,
         effect_size = mod$effect_size(dat),
         effect_size_kl = kl_divergence(dat, a = a, b = b, sigma = e_sigma))
}


result <- tibble()

for (a in seq(-1.5, 1.5, 0.5)) {
  for (b in seq(-1.5, 1.5, 0.5)) {
    if (a == b) next
    result <- bind_rows(result,
                        map(1:1000, ~sim_effect_size_kl(a, b)) %>%
                          reduce(bind_rows))

  }
}


result %>%
  mutate(e_sigma = factor(e_sigma)) %>%
  ggplot() +
  geom_boxplot(aes(x = log(effect_size_kl), y = e_sigma, group = e_sigma), orientation = "y") +
  facet_wrap(x_dist~n)

result %>%
  mutate(e_sigma = factor(e_sigma)) %>%
  ggplot() +
  geom_boxplot(aes(x = log(effect_size), y = e_sigma, col = factor(n)), orientation = "y") +
  facet_grid(a~x_dist) -> p

ggsave("box.png", p, width = 32, height = 24)


result$effect_size_kl %>% summary()

result %>%
  ggplot() +
  geom_point(aes(log(effect_size), log(effect_size_kl)), alpha = 0.05) +
  geom_smooth(aes(log(effect_size), log(effect_size_kl)), se = FALSE)

