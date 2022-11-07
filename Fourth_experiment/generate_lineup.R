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
                                              effect_size = mod$sample_effect_size(filter(lineup_dat, null == FALSE), type = "kl"),
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

# check poly rand_uniform_d problem

file_path <- "plots"

for (j in 1:nrow(allocated)) {
  ggsave(glue::glue("{file_path}/{plot_string[allocated$subject[j]]}_{allocated$subject[j]}_{allocated$order[j]}.png"),
         plot = VI_MODEL$plot_lineup(dat[[allocated$lineup_id[j]]]$data,
                                     remove_axis = TRUE,
                                     remove_legend = TRUE,
                                     remove_grid_line = TRUE,
                                     theme = theme_light()) +
           ggtitle(glue::glue("lineup:{allocated$lineup_id[j]}, a:{dat[[allocated$lineup_id[j]]]$metadata$a}, x_dist:{dat[[allocated$lineup_id[j]]]$metadata$x_dist}, b:{dat[[allocated$lineup_id[j]]]$metadata$b}, log effect size:{round(log(dat[[allocated$lineup_id[j]]]$metadata$effect_size), 2)}, ans: {dat[[allocated$lineup_id[j]]]$metadata$ans}")),
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
           ggtitle(glue::glue("lineup:{lineup$lineup_id[j]}, a:{dat[[lineup$lineup_id[j]]]$metadata$a}, x_dist:{dat[[lineup$lineup_id[j]]]$metadata$x_dist}, b:{dat[[lineup$lineup_id[j]]]$metadata$b}, log effect size:{round(log(dat[[lineup$lineup_id[j]]]$metadata$effect_size), 2)}, ans: {dat[[lineup$lineup_id[j]]]$metadata$ans}")),
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


# check metadata equal
all(map_lgl(1:588, ~dat[[.x]]$metadata$a == lineup$a[lineup$lineup_id == .x]))
all(map_lgl(1:588, ~dat[[.x]]$metadata$n == lineup$n[lineup$lineup_id == .x]))
all(map_lgl(1:588, ~dat[[.x]]$metadata$b == lineup$b[lineup$lineup_id == .x]))
all(map_lgl(1:588, ~dat[[.x]]$metadata$x_dist == lineup$x_dist[lineup$lineup_id == .x]))

saveRDS(dat, "data/fourth_experiment_dat.rds")

allocated %>%
  arrange(subject, order) %>%
  pivot_wider(names_from = order, values_from = lineup_id) %>%
  select(-subject) %>%
  write_csv(file = "data/fourth_experiment_order.txt", col_names = FALSE)
