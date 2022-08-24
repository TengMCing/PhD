library(tidyverse)
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
              even_discrete = rand_uniform_d(-1, 1, k = 5, even = TRUE))
  mod <- heter_model(a = lineup$a[i], b = lineup$b[i], x = x)
  lineup_dat <- mod$gen_lineup(lineup$n[i], 20)

  dat[[lineup$lineup_id[i]]]$metadata <- list(type = "heteroskedasticity",
                                              formula = deparse(mod$formula),
                                              a = lineup$a[i],
                                              b = lineup$b[i],
                                              x_dist = lineup$x_dist[i],
                                              e_dist = "normal",
                                              e_sigma = 1,
                                              name = glue::glue("heter_{lineup$lineup_id[i]}"),
                                              k = 20,
                                              n = lineup$n[i],
                                              effect_size = mod$effect_size(filter(lineup_dat, null == FALSE), type = "kl"),
                                              ans = filter(lineup_dat, null == FALSE)$k[1]

  )

  dat[[lineup$lineup_id[i]]]$data <- lineup_dat
}


map_dbl(lineup$lineup_id[lineup$b == 0], ~dat[[.x]]$metadata$effect_size)

p_value <- map_dbl(1:nrow(lineup), ~HETER_MODEL$test(filter(dat[[.x]]$data, null == FALSE))$p_value)

# false positive rate, approx 3% reject
mean(p_value[lineup$lineup_id[lineup$b == 0]] < 0.05)

# around 72% reject, 28% accept
mean(p_value[lineup$lineup_id[lineup$b <= 64 & lineup$b > 0]] < 0.05)

heter_result <- map(1:100000,
                    function(x) {
                      a <- sample(c(-1, 0, 1), 1)
                      b <- sample(c(0.25, 1, 4, 16, 64), 1)
                      x_dist <- sample(c("uniform", "normal", "lognormal", "even_discrete"), 1)
                      x <- switch(x_dist,
                                  uniform = rand_uniform(-1, 1),
                                  normal = {raw_x <- rand_normal(sigma = 0.3); closed_form(~stand_dist(raw_x))},
                                  lognormal = {raw_x <- rand_lognormal(sigma = 0.6); closed_form(~stand_dist(raw_x/3 - 1))},
                                  even_discrete = rand_uniform_d(-1, 1, k = 5, even = TRUE))
                      mod <- heter_model(a = a, b = b, x = x)
                      n <- sample(c(50, 100, 300), 1)
                      tmp_dat <- mod$gen(n)

                      tibble(a = a,
                             b = b,
                             x_dist = x_dist,
                             n = n,
                             effect_size = mod$effect_size(tmp_dat, type = "kl"),
                             reject = mod$test(tmp_dat)$p_value < 0.05)
                    }) %>%
  reduce(bind_rows)



ggplot() +
  geom_smooth(data = select(heter_result, -b, -n), aes(log(effect_size), as.numeric(reject)), method = "glm", method.args = list(family = binomial())) +
  geom_rug(data = tibble(rug = map_dbl(dat[1:576], ~.x$metadata$effect_size),
                         b = map_dbl(dat[1:576], ~.x$metadata$b) %>% factor()) %>%
             filter(rug > 0) %>%
             mutate(rug = log(rug)),
           aes(rug, col = b),
           alpha = 0.3) +
  facet_wrap(~b) +
  ggtitle("Blue curve: conventional test power, Rug: lineups used in the experiment") -> p
ggsave("img/conv_power_rug_b.png", plot = p, width = 7, height = 7)


ggplot() +
  geom_smooth(data = select(heter_result, -b, -n), aes(log(effect_size), as.numeric(reject)), method = "glm", method.args = list(family = binomial())) +
  geom_rug(data = tibble(rug = map_dbl(dat[1:576], ~.x$metadata$effect_size),
                         b = map_dbl(dat[1:576], ~.x$metadata$b) %>% factor(),
                         n = map_dbl(dat[1:576], ~.x$metadata$n)) %>%
             filter(rug > 0) %>%
             mutate(rug = log(rug)),
           aes(rug, col = b),
           alpha = 0.3) +
  facet_grid(n~b) +
  ggtitle("Blue curve: conventional test power, Rug: lineups used in the experiment") -> p
ggsave("img/conv_power_rug_b_n.png", plot = p, width = 7, height = 7)

ggplot() +
  geom_smooth(data = select(heter_result, -b, -n), aes(log(effect_size), as.numeric(reject)), method = "glm", method.args = list(family = binomial())) +
  geom_histogram(data = tibble(rug = map_dbl(dat[1:576], ~.x$metadata$effect_size),
                               b = map_dbl(dat[1:576], ~.x$metadata$b) %>% factor(),
                               n = map_dbl(dat[1:576], ~.x$metadata$n)) %>%
                   filter(rug > 0) %>%
                   mutate(rug = log(rug)),
                 aes(rug, y = ..ncount..)) +
  facet_grid(~b) +
  ggtitle("Blue curve: conventional test power, Bar: lineups used in the experiment") -> p
ggsave("img/conv_power_hist_b.png", plot = p, width = 7, height = 7)


ggplot() +
  geom_smooth(data = select(heter_result, -b, -n), aes(log(effect_size), as.numeric(reject)), method = "glm", method.args = list(family = binomial())) +
  geom_histogram(data = tibble(rug = map_dbl(dat[1:576], ~.x$metadata$effect_size),
                               b = map_dbl(dat[1:576], ~.x$metadata$b) %>% factor(),
                               n = map_dbl(dat[1:576], ~.x$metadata$n)) %>%
                   filter(rug > 0) %>%
                   mutate(rug = log(rug)),
                 aes(rug, y = ..ncount..)) +
  facet_grid(n~b) +
  ggtitle("Blue curve: conventional test power, Bar: lineups used in the experiment") -> p
ggsave("img/conv_power_hist_b_n.png", plot = p, width = 7, height = 7)
