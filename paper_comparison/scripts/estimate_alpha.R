library(visage)
library(tidyverse)


calc_alpha <- function(zero_sel = 0.05) {
  vi_survey %>%
    filter(b == 0) %>%
    select(unique_lineup_id, type:n, -shape, -include_z, -a, -b, -e_dist, -e_sigma, -formula, -k, -type, -name) %>%
    group_by(unique_lineup_id) %>%
    summarise(across(x_dist:n, first)) %>%
    arrange(across(c(x_dist:n))) %>%
    mutate(setting_id = rep(1:12, each = 3)) -> final_vi_survey

  final_vi_survey %>%
    select(unique_lineup_id, setting_id) %>%
    right_join(filter(vi_survey, b == 0)) %>%
    select(unique_lineup_id, setting_id, selection, num_selection) %>%
    (function(x) {
      for (i in 1:20)
        x[[paste0("plot_", i)]] <-
          grepl(paste0("_", i, "_"), x$selection) |
          grepl(paste0("^", i, "_"), x$selection) |
          grepl(paste0("_", i, "$"), x$selection) |
          grepl(paste0("^", i, "$"), x$selection)
      x}
    ) %>%
    mutate(across(plot_1:plot_20, function(x) ifelse(num_selection, x/num_selection, zero_sel))) %>%
    group_by(setting_id, unique_lineup_id) %>%
    summarise(across(plot_1:plot_20, sum)) %>%
    ungroup() %>%
    pivot_longer(plot_1:plot_20) %>%
    group_by(setting_id, unique_lineup_id) %>%
    summarise(c_interesting = sum(value > 1)) %>%
    group_by(setting_id) %>%
    summarise(c_interesting = mean(c_interesting)) %>%
    ungroup() %>%
    mutate(numeric_alpha = vinference::estimate_alpha_numeric(Zc = c_interesting, m0 = 20, K = 20)) %>%
    mutate(numeric_alpha_sum_sq_error = numeric_alpha$sum_sq_error, numeric_alpha = numeric_alpha$alpha) %>%
    right_join(final_vi_survey)
}


calc_alpha(0.05) -> select_all_plots
calc_alpha(0) -> select_zero_plots

vi_survey <- vi_survey %>%
  rename(p_value_uniform = p_value) %>%
  left_join(select_all_plots %>%
              group_by(setting_id) %>%
              summarise(across(everything(), first)) %>%
              select(x_dist, n, c_interesting, numeric_alpha, numeric_alpha_sum_sq_error))


p_value_cache_env <- new.env()

p_value_dat <- vi_survey %>%
  group_by(unique_lineup_id) %>%
  summarise(p_value_select_all_plots = calc_p_value(n_detect = sum(detect),
                                                    n_eval = n(),
                                                    n_sel = num_selection,
                                                    cache_env = p_value_cache_env,
                                                    dist = "dirichlet",
                                                    alpha = numeric_alpha[1]))


vi_survey <- vi_survey %>%
  left_join(p_value_dat)

saveRDS(vi_survey, here::here("data/vi_survey_processed.rds"))


vi_survey %>%
  ggplot() +
  geom_point(aes(p_value_uniform, p_value_select_all_plots)) +
  geom_abline() +
  scale_x_log10() +
  scale_y_log10()

vi_survey %>%
  filter(type == "polynomial") %>%
  filter(e_sigma != 0.125) %>%
  mutate(reject_dirichlet = as.numeric(p_value_select_all_plots <= 0.05)) %>%
  mutate(log_effect_size = log(effect_size)) %>%
  ggplot() +
  geom_smooth(aes(log_effect_size, reject_dirichlet), method = "glm", method.args = list(family = binomial), se = FALSE)


