library(tidyverse)
library(visage)

sample_dat <- readRDS("data/all_data_big.RDS")

lineup <- read_csv("lineup_info.csv")
plot_string <- read_csv("data/plot_string.txt", col_names = FALSE) %>%
  .$X1
allocated <- read_csv("allocate_result.csv") %>%
  group_by(subject) %>%
  mutate(current_lineup = 1:n())
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

  dat[[i]]$metadata <- list(type = "polynomial",
                            formula = deparse(mod$formula),
                            shape = lineup$shape[i],
                            x_dist = lineup$x_dist[i],
                            include_z = TRUE,
                            e_dist = "normal",
                            e_sigma = lineup$e_sigma[i],
                            name = glue::glue("poly_{i}"),
                            k = 20,
                            n = lineup$n[i],
                            effect_size = mod$effect_size(filter(lineup_dat, null == FALSE)),
                            ans = filter(lineup_dat, null == FALSE)$k[1]
                            )

  dat[[i]]$data <- lineup_dat
}

file_path <- "plots"

for (j in 1:nrow(allocated)) {

  ggsave(glue::glue("{file_path}/{plot_string[allocated$subject[j]]}_{allocated$subject[j]}_{allocated$current_lineup[j]}.png"),
         plot = VI_MODEL$plot_lineup(dat[[allocated$lineup_id[j]]]$data,
                                     remove_axis = TRUE,
                                     remove_legend = TRUE,
                                     remove_grid_line = TRUE,
                                     theme = theme_light()),
         height = 7,
         width = 7)
}

file_path <- "lineup_plots"

for (j in 1:nrow(lineup)) {
  ggsave(glue::glue("{file_path}/{j}.png"),
         plot = VI_MODEL$plot_lineup(dat[[j]]$data,
                                     remove_axis = TRUE,
                                     remove_legend = TRUE,
                                     remove_grid_line = TRUE,
                                     theme = theme_light()) +
           ggtitle(glue::glue("shape:{dat[[j]]$metadata$shape}, x_dist:{dat[[j]]$metadata$x_dist}, e_sigma:{dat[[j]]$metadata$e_sigma}, log effect size:{round(log(dat[[j]]$metadata$effect_size), 2)}")),
         height = 7,
         width = 7)
}

p_value <- map_dbl(1:nrow(lineup), ~POLY_MODEL$test(filter(dat[[.x]]$data, null == FALSE))$p_value)

sum(p_value > 0.05)

