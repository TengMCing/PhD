library(tidyverse)
library(visage)

lineup <- read_csv("data/lineup_info.csv")
plot_string <- read_csv("data/plot_string.txt", col_names = FALSE) %>%
  .$X1
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

file_path <- "plots"

for (j in 1:nrow(allocated)) {

  ggsave(glue::glue("{file_path}/{plot_string[allocated$subject[j]]}_{allocated$subject[j]}_{allocated$order[j]}.png"),
         plot = VI_MODEL$plot_lineup(dat[[allocated$lineup_id[j]]]$data,
                                     remove_axis = TRUE,
                                     remove_legend = TRUE,
                                     remove_grid_line = TRUE,
                                     theme = theme_light()) +
           ggtitle(glue::glue("lineup:{allocated$lineup_id[j]}, shape:{dat[[allocated$lineup_id[j]]]$metadata$shape}, x_dist:{dat[[allocated$lineup_id[j]]]$metadata$x_dist}, e_sigma:{dat[[allocated$lineup_id[j]]]$metadata$e_sigma}, log effect size:{round(log(dat[[allocated$lineup_id[j]]]$metadata$effect_size), 2)}, ans: {dat[[allocated$lineup_id[j]]]$metadata$ans}")),
         height = 7,
         width = 7)
}

file_path <- "lineup_plots_"

for (j in 1:nrow(lineup)) {
  ggsave(glue::glue("{file_path}/{lineup$lineup_id[j]}.png"),
         plot = VI_MODEL$plot_lineup(dat[[lineup$lineup_id[j]]]$data,
                                     remove_axis = TRUE,
                                     remove_legend = TRUE,
                                     remove_grid_line = TRUE,
                                     theme = theme_light()) +
           ggtitle(glue::glue("lineup:{lineup$lineup_id[j]}, shape:{dat[[lineup$lineup_id[j]]]$metadata$shape}, x_dist:{dat[[lineup$lineup_id[j]]]$metadata$x_dist}, e_sigma:{dat[[lineup$lineup_id[j]]]$metadata$e_sigma}, log effect size:{round(log(dat[[lineup$lineup_id[j]]]$metadata$effect_size), 2)}, ans: {dat[[lineup$lineup_id[j]]]$metadata$ans}")),
         height = 7,
         width = 7)
}

file_path <- "lineup_plots"

for (j in 1:nrow(lineup)) {
  ggsave(glue::glue("{file_path}/{lineup$lineup_id[j]}.png"),
         plot = VI_MODEL$plot_lineup(dat[[lineup$lineup_id[j]]]$data,
                                     remove_axis = TRUE,
                                     remove_legend = TRUE,
                                     remove_grid_line = TRUE,
                                     theme = theme_light()),
         height = 7,
         width = 7)
}

p_value <- map_dbl(1:576, ~POLY_MODEL$test(filter(dat[[.x]]$data, null == FALSE))$p_value)

mean(p_value > 0.05)

# check metadata equal
all(map_lgl(1:588, ~dat[[.x]]$metadata$shape == lineup$shape[lineup$lineup_id == .x]))
all(map_lgl(1:588, ~dat[[.x]]$metadata$n == lineup$n[lineup$lineup_id == .x]))
all(map_lgl(1:588, ~dat[[.x]]$metadata$e_sigma == lineup$e_sigma[lineup$lineup_id == .x]))
all(map_lgl(1:588, ~dat[[.x]]$metadata$x_dist == lineup$x_dist[lineup$lineup_id == .x]))

saveRDS(dat, "data/third_experiment_dat.rds")

allocated %>%
  arrange(subject, order) %>%
  pivot_wider(names_from = order, values_from = lineup_id) %>%
  select(-subject) %>%
  write_csv(file = "data/third_experiment_order.txt", col_names = FALSE)
