library(tidyverse)
library(visage)

source(here::here("scripts/survey.R"))
source(here::here("scripts/conventional.R"))

survey_dat <- read_survey()
conv_result <- get_sim_conv()

env <- new.env()

comb_pvalue <- survey_dat %>%
  mutate(lineup_id = paste0(exp, "_", lineup_id)) %>%
  visage::calc_p_value_multi(lineup_id = "lineup_id",
                             detected = "detect",
                             n_sel = "num_selection",
                             comb = TRUE,
                             n_eval = 1:5,
                             n_sim = 100000,
                             cache_env = env)

comb_power <- comb_pvalue %>%
  rowwise() %>%
  mutate(hat_power_001 = mean(eval_p_value(p_value, tol = 1e-2, significance_level = 0.01))) %>%
  mutate(hat_power_005 = mean(eval_p_value(p_value, tol = 1e-2, significance_level = 0.05))) %>%
  mutate(hat_power_010 = mean(eval_p_value(p_value, tol = 1e-2, significance_level = 0.1))) %>%
  mutate(hat_power_015 = mean(eval_p_value(p_value, tol = 1e-2, significance_level = 0.15))) %>%
  mutate(hat_power_020 = mean(eval_p_value(p_value, tol = 1e-2, significance_level = 0.2))) %>%
  mutate(hat_power_025 = mean(eval_p_value(p_value, tol = 1e-2, significance_level = 0.25))) %>%
  mutate(hat_power_030 = mean(eval_p_value(p_value, tol = 1e-2, significance_level = 0.3))) %>%
  ungroup() %>%
  select(-p_value) %>%
  gather(hat_power_001:hat_power_030, key = "alpha", value = "hat_power")

survey_dat %>%
  mutate(lineup_id = paste0(exp, "_", lineup_id)) %>%
  select(lineup_id, type, effect_size) %>%
  group_by(lineup_id) %>%
  summarise(type = first(type), effect_size = first(effect_size)) %>%
  right_join(comb_power) %>%
  ggplot() +
  geom_smooth(aes(log(effect_size), hat_power, col = factor(n_eval), group = factor(n_eval)),
              method = "glm",
              method.args = list(family = quasibinomial()),
              se = FALSE) +
  geom_smooth(data = conv_result,
              aes(log(effect_size), as.numeric(p_value < 0.05)),
              method = "glm",
              method.args = list(family = binomial()),
              se = FALSE, linetype = 2, size = 1, col = "grey80") +
  facet_grid(alpha ~ type, scales = "free_x") +
  scale_colour_viridis_d(option = "B", begin = 0.5, end = 0.9) +
  theme_light() +
  ggtitle("alpha for conventional: 0.05")




conv_result_ex <- conv_result %>%
  mutate(hat_power_0000001 = eval_p_value(p_value, tol = 1e-2, significance_level = 0.000001)) %>%
  mutate(hat_power_000001 = eval_p_value(p_value, tol = 1e-2, significance_level = 0.00001)) %>%
  mutate(hat_power_00001 = eval_p_value(p_value, tol = 1e-2, significance_level = 0.0001)) %>%
  mutate(hat_power_0001 = eval_p_value(p_value, tol = 1e-2, significance_level = 0.001)) %>%
  mutate(hat_power_001 = eval_p_value(p_value, tol = 1e-2, significance_level = 0.01)) %>%
  mutate(hat_power_005 = eval_p_value(p_value, tol = 1e-2, significance_level = 0.05)) %>%
  ungroup() %>%
  select(-p_value) %>%
  gather(hat_power_0000001:hat_power_005, key = "alpha", value = "hat_power")

survey_dat %>%
  mutate(lineup_id = paste0(exp, "_", lineup_id)) %>%
  select(lineup_id, type, effect_size) %>%
  group_by(lineup_id) %>%
  summarise(type = first(type), effect_size = first(effect_size)) %>%
  right_join(comb_power) %>%
  ggplot() +
  geom_smooth(aes(log(effect_size), hat_power, col = factor(n_eval), group = factor(n_eval)),
              method = "glm",
              method.args = list(family = quasibinomial()),
              se = FALSE) +
  geom_smooth(data = conv_result_ex,
              aes(log(effect_size), as.numeric(hat_power)),
              method = "glm",
              method.args = list(family = binomial()),
              se = FALSE, linetype = 2, size = 1, col = "grey80") +
  facet_grid(alpha ~ type, scales = "free_x") +
  scale_colour_viridis_d(option = "B", begin = 0.5, end = 0.9) +
  theme_light()

survey_dat %>%
  mutate(lineup_id = paste0(exp, "_", lineup_id)) %>%
  select(lineup_id, type, effect_size) %>%
  group_by(lineup_id) %>%
  summarise(type = first(type), effect_size = first(effect_size)) %>%
  right_join(select(filter(comb_power, alpha == "hat_power_005"), -alpha)) %>%
  ggplot() +
  geom_smooth(aes(log(effect_size), hat_power, col = factor(n_eval), group = factor(n_eval)),
              method = "glm",
              method.args = list(family = quasibinomial()),
              se = FALSE) +
  geom_smooth(data = conv_result_ex,
              aes(log(effect_size), as.numeric(hat_power)),
              method = "glm",
              method.args = list(family = binomial()),
              se = FALSE, linetype = 2, size = 1, col = "grey80") +
  facet_grid(alpha ~ type, scales = "free_x") +
  scale_colour_viridis_d(option = "B", begin = 0.5, end = 0.9) +
  theme_light()


lineup_dat_big <- readRDS(here::here("data/big_study/all_data_big.RDS"))

survey_dat %>%
  mutate(lineup_id = paste0(exp, "_", lineup_id)) %>%
  filter(type == "cubic") %>%
  filter(exp == 2) %>%
  filter(between(log(effect_size), -0.5, 0.5)) %>%
  group_by(lineup_id) %>%
  summarise(log_effect_size = first(log(effect_size)), data_p_value = first(data_p_value), difficulty = first(difficulty)) %>%
  mutate(lineup_id = as.numeric(stringr::str_replace(lineup_id, ".*_", ""))) -> tmp


vis_lineup <- function(lineup_id) {
  lineup_dat_big[[lineup_id]]$data %>%
    mutate(.fitted = .pred) %>%
    CUBIC_MODEL$plot_lineup(remove_grid_line = TRUE, remove_axis = TRUE, theme = theme_light()) +
    ggtitle(glue::glue("ans: {lineup_dat_big[[lineup_id]]$metadata$ans}, ln_effect_size: {round(tmp$log_effect_size[tmp$lineup_id == lineup_id], 2)}, conventional: {round(tmp$data_p_value[tmp$lineup_id == lineup_id], 2)}"))
}

# not obvious, reject
vis_lineup(24)
# obvious, reject
vis_lineup(25)
# not obvious, reject
vis_lineup(28)
# not obvious, reject
vis_lineup(29)
# not obvious, reject
vis_lineup(33)
# obvious, reject
vis_lineup(36)
# not obvious, not reject
vis_lineup(40)
# obvious?, reject
vis_lineup(41)
# obvious, reject
vis_lineup(52)
# not obvious, not reject
vis_lineup(53)
# not obvious, not reject
vis_lineup(54)
# obvious, reject
vis_lineup(55)
# obvious? reject
vis_lineup(59)
# not obvious, reject
vis_lineup(60)
# not obvious, reject
vis_lineup(61)
# not obvious, reject
vis_lineup(62)
# not obvious, reject
vis_lineup(63)
# obvious, reject
vis_lineup(65)
# not obvious, reject
vis_lineup(71)
