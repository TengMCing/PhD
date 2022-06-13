library(tidyverse)
library(visage)
library(UpSetR)

result <- read_csv("allocate_result_full.csv")
lineup <- read_csv("lineup_info.csv")

result %>%
  # filter(subject %in% 1:120) %>%
  ggplot() +
  geom_jitter(aes(factor(shape),
                 factor(e_sigma),
                 shape = x_dist,
                 col = factor(n)),
             width = 0,
             height = 0,
             alpha = 0.5,
             size = 3) +
  facet_wrap(~subject, ncol = 15) +
  scale_color_brewer(palette = "Dark2") +
  theme_bw() -> p

ggsave("check_allocation_for_subject.png", plot = p,
       width = 20, height = 13)


# x_dist & shape, upset
cb_names <- result %>%
  mutate(x_dist_shape = interaction(x_dist, shape, sep = "_")) %>%
  {unique(.$x_dist_shape)}

result %>%
  mutate(x_dist_shape = interaction(x_dist, shape, sep = "_")) %>%
  group_by(subject) %>%
  count(x_dist_shape) %>%
  group_by(x_dist_shape) %>%
  group_map(~unique(.x$subject)) %>%
  `names<-`(glue::glue("{cb_names}")) %>%
  {upset(fromList(.), order.by = "freq", nsets = 16)}


# x_dist & e_sigma, upset
cb_names <- result %>%
  mutate(x_dist_e_sigma = interaction(x_dist, e_sigma, sep = "_")) %>%
  {unique(.$x_dist_e_sigma)}

result %>%
  mutate(x_dist_e_sigma = interaction(x_dist, e_sigma, sep = "_")) %>%
  group_by(subject) %>%
  count(x_dist_e_sigma) %>%
  group_by(x_dist_e_sigma) %>%
  group_map(~unique(.x$subject)) %>%
  `names<-`(glue::glue("{cb_names}")) %>%
  {upset(fromList(.), order.by = "freq", nsets = 16)}

# x_dist & n, upset
cb_names <- result %>%
  mutate(x_dist_n = interaction(x_dist, n, sep = "_")) %>%
  {unique(.$x_dist_n)}

result %>%
  mutate(x_dist_n = interaction(x_dist, n, sep = "_")) %>%
  group_by(subject) %>%
  count(x_dist_n) %>%
  group_by(x_dist_n) %>%
  group_map(~unique(.x$subject)) %>%
  `names<-`(glue::glue("{cb_names}")) %>%
  {upset(fromList(.), order.by = "freq", nsets = 12)}

# shape & e_sigma, upset
cb_names <- result %>%
  mutate(shape_e_sigma = interaction(shape, e_sigma, sep = "_")) %>%
  {unique(.$shape_e_sigma)}

result %>%
  mutate(shape_e_sigma = interaction(shape, e_sigma, sep = "_")) %>%
  group_by(subject) %>%
  count(shape_e_sigma) %>%
  group_by(shape_e_sigma) %>%
  group_map(~unique(.x$subject)) %>%
  `names<-`(glue::glue("{cb_names}")) %>%
  {upset(fromList(.), order.by = "freq", nsets = 16)}

# shape & n, upset
# full
cb_names <- result %>%
  mutate(shape_n = interaction(shape, n, sep = "_")) %>%
  {unique(.$shape_n)}

result %>%
  mutate(shape_n = interaction(shape, n, sep = "_")) %>%
  group_by(subject) %>%
  count(shape_n) %>%
  group_by(shape_n) %>%
  group_map(~unique(.x$subject)) %>%
  `names<-`(glue::glue("{cb_names}")) %>%
  {upset(fromList(.), order.by = "freq", nsets = 12)}

# e_sigma & n, upset
# full
cb_names <- result %>%
  mutate(e_sigma_n = interaction(e_sigma, n, sep = "_")) %>%
  {unique(.$e_sigma_n)}

result %>%
  mutate(e_sigma_n = interaction(e_sigma, n, sep = "_")) %>%
  group_by(subject) %>%
  count(e_sigma_n) %>%
  group_by(e_sigma_n) %>%
  group_map(~unique(.x$subject)) %>%
  `names<-`(glue::glue("{cb_names}")) %>%
  {upset(fromList(.), order.by = "freq", nsets = 16)}

# x_dist & shape & e_sigma, upset
# full
cb_names <- result %>%
  mutate(x_dist_shape_e_sigma = interaction(x_dist, shape, e_sigma, sep = "_")) %>%
  {unique(.$x_dist_shape_e_sigma)}

result %>%
  mutate(x_dist_shape_e_sigma = interaction(x_dist, shape, e_sigma, sep = "_")) %>%
  group_by(subject) %>%
  count(x_dist_shape_e_sigma) %>%
  group_by(x_dist_shape_e_sigma) %>%
  group_map(~unique(.x$subject)) %>%
  `names<-`(glue::glue("{cb_names}")) %>%
  {upset(fromList(.), order.by = "freq", nsets = 64)} -> p

png("x_dist_shape_e_sigma.png",
    res = 300,
    units = "in",
    width = ggplot2:::plot_dim(dim = c(20, 20))[1],
    height = ggplot2:::plot_dim(dim = c(20, 20))[2])
print(p)
dev.off()


# 4 x_dist, 4 e_sigma, 3 n, 4 a (shapes), 5 evaluations, 3 rep


set.seed(10086)
lineup$effect_size <- 0

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
   lineup$effect_size[i] <- mod$effect_size(filter(mod$gen_lineup(lineup$n[i], 20), null == FALSE))
}

lineup %>%
  ggplot() +
  geom_jitter(aes(log(effect_size), factor(n), col = factor(shape)),
              width = 0, alpha = 0.6) +
  facet_grid(e_sigma~x_dist) -> p

ggsave("check_allocation_for_group.png", plot = p, width = 8, height = 6)
