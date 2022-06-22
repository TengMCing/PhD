library(tidyverse)
library(bandicoot)
library(visage)

lineup <- read_csv("data/lineup_info.csv")
allocated <- read_csv("data/allocate_result.csv")
dat <- vector(mode = "list", length = nrow(lineup))

set.seed(10086)

stand_dist <- function(x) {
  (x - min(x))/max(x - min(x)) * 2 - 1
}

for (i in 1:nrow(lineup)) {

  x <- switch(lineup$x_dist[i],
              uniform = rand_uniform(-1, 1),
              normal = {raw_x <- rand_normal(sigma = 0.3); closed_form(~stand_dist(raw_x))},
              lognormal = {raw_x <- rand_lognormal(sigma = 0.6); closed_form(~stand_dist(raw_x/3 - 1))},
              even_discrete = rand_uniform_d(k = 5, even = TRUE))
  mod <- poly_model(lineup$shape[i], x = x, sigma = lineup$e_sigma[i])
  lineup_dat <- mod$gen_lineup(lineup$n[i], 20)

  dat[[lineup$lineup_id[i]]]$metadata <- list(type = "polynomial",
                                              formula = deparse(mod$formula),
                                              shape = lineup$shape[i],
                                              x_dist = lineup$x_dist[i],
                                              include_z = TRUE,
                                              e_dist = "normal",
                                              e_sigma = lineup$e_sigma[i],
                                              name = glue::glue("poly_{lineup$lineup_id[i]}"),
                                              k = 20,
                                              n = lineup$n[i],
                                              effect_size = mod$effect_size(filter(lineup_dat, null == FALSE)),
                                              ans = filter(lineup_dat, null == FALSE)$k[1]

  )

  dat[[lineup$lineup_id[i]]]$data <- lineup_dat
}

p_value <- map_dbl(1:nrow(lineup), ~POLY_MODEL$test(filter(dat[[.x]]$data, null == FALSE))$p_value)

mean(p_value > 0.05)

# we want ~20% P_value > 0.05

# Draw power vs effect_size then highlight the current effect size for conventional test




# conventional test -------------------------------------------------------


conv_result <- map(1:100000,
                   function(x) {
                     shape <- sample(1:4, 1)
                     e_sigma <- sample(c(0.5, 1, 2, 4), 1)
                     x_dist <- sample(c("uniform", "normal", "lognormal", "even_discrete"), 1)
                     x <- switch(x_dist,
                                 uniform = rand_uniform(-1, 1),
                                 normal = {raw_x <- rand_normal(sigma = 0.3); closed_form(~stand_dist(raw_x))},
                                 lognormal = {raw_x <- rand_lognormal(sigma = 0.6); closed_form(~stand_dist(raw_x/3 - 1))},
                                 even_discrete = rand_uniform_d(k = 5, even = TRUE))
                     mod <- poly_model(shape, x = x, sigma = e_sigma)
                     n <- sample(c(50, 100, 300), 1)
                     tmp_dat <- mod$gen(n)

                     tibble(shape = shape,
                            e_sigma = e_sigma,
                            x_dist = x_dist,
                            n = n,
                            effect_size = mod$effect_size(tmp_dat),
                            reject = mod$test(tmp_dat)$p_value < 0.05)
                   }) %>%
  reduce(bind_rows)



ggplot() +
  geom_smooth(data = select(conv_result, -e_sigma, -n), aes(log(effect_size), as.numeric(reject))) +
  geom_rug(data = tibble(rug = map_dbl(dat[1:576], ~log(.x$metadata$effect_size)),
                         e_sigma = map_dbl(dat[1:576], ~.x$metadata$e_sigma) %>% factor()),
             aes(rug, col = e_sigma),
           alpha = 0.3) +
  facet_wrap(~e_sigma) +
  ggtitle("Blue curve: conventional test power, Rug: lineups used in the experiment") -> p
ggsave("img/conv_power_rug_sigma.png", plot = p, width = 7, height = 7)

ggplot() +
  geom_smooth(data = select(conv_result, -e_sigma, -n), aes(log(effect_size), as.numeric(reject))) +
  geom_rug(data = tibble(rug = map_dbl(dat[1:576], ~log(.x$metadata$effect_size)),
                         e_sigma = map_dbl(dat[1:576], ~.x$metadata$e_sigma) %>% factor(),
                         n = map_dbl(dat[1:576], ~.x$metadata$n) %>% factor()),
           aes(rug, col = e_sigma),
           alpha = 0.3) +
  facet_grid(n~e_sigma) +
  ggtitle("Blue curve: conventional test power, Bar: lineups used in the experiment") -> p
ggsave("img/conv_power_rug_sigma_n.png", plot = p, width = 7, height = 7)

ggplot() +
  geom_smooth(data = select(conv_result, -e_sigma, -n), aes(log(effect_size), as.numeric(reject))) +
  geom_histogram(data = tibble(rug = map_dbl(dat[1:576], ~log(.x$metadata$effect_size)),
                         e_sigma = map_dbl(dat[1:576], ~.x$metadata$e_sigma) %>% factor(),
                         n = map_dbl(dat[1:576], ~.x$metadata$n) %>% factor()),
           aes(rug, y = ..ncount..)) +
  facet_grid(~e_sigma) +
  ggtitle("Blue curve: conventional test power, Bar: lineups used in the experiment") -> p
ggsave("img/conv_power_hist_sigma.png", plot = p, width = 7, height = 7)

ggplot() +
  geom_smooth(data = select(conv_result, -e_sigma, -n), aes(log(effect_size), as.numeric(reject))) +
  geom_histogram(data = tibble(rug = map_dbl(dat[1:576], ~log(.x$metadata$effect_size)),
                               e_sigma = map_dbl(dat[1:576], ~.x$metadata$e_sigma) %>% factor(),
                               n = map_dbl(dat[1:576], ~.x$metadata$n) %>% factor()),
                 aes(rug, y = ..ncount..)) +
  facet_grid(n~e_sigma) +
  ggtitle("Blue curve: conventional test power, Bar: lineups used in the experiment") -> p
ggsave("img/conv_power_hist_sigma_n.png", plot = p, width = 7, height = 7)
