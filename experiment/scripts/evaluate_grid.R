source(here::here("scripts/model.R"))
source(here::here("scripts/higher_order_model.R"))
source(here::here("scripts/heteroskedasticity_model.R"))
source(here::here("scripts/non_normal_model.R"))
source(here::here("scripts/experiment.R"))

num_rec <- 100000

build_and_record <- function(...) {
  paras <- list(...)
  myexp <- EXPERIMENT("tmp")
  mod <- do.call(paras$model, paras)
  myexp$add_model("tmp_mod", mod)
  myexp$gen_lineup_data("tmp_mod", k = 2, n = paras$n)
  return(list(c(statistic = myexp$get_statistic(), pvalue = myexp$get_pvalue())))
}

data.frame(a = runif(num_rec, -3, 3),
           b = runif(num_rec, -3, 3),
           c = runif(num_rec, 0, 5),
           x_dist = sample(c("uniform", "normal", "lognormal", "neglognormal"), num_rec, replace = TRUE),
           x_mu = 0,
           x_sigma = sample(c(0.3, 0.6), num_rec, replace = TRUE),
           z_discrete = sample(c(TRUE, FALSE), num_rec, replace = TRUE),
           z_discrete_dist = "discrete_uniform",
           z_n = sample(seq(3, 10, 1), num_rec, replace = TRUE),
           e_dist = "normal",
           e_df = NA,
           e_sigma = sample(c(0.25, 0.5, 1, 2), num_rec, replace = TRUE),
           n = sample(c(50, 100, 300), num_rec, replace = TRUE),
           model = "HIGHER_ORDER_MODEL") %>%
  tibble() -> mygrid

mygrid %>%
  mutate(i = 1:n()/n()) %>%
  rowwise() %>%
  mutate(result = build_and_record(i=i,
                                   a=a,
                                   b=b,
                                   c=c,
                                   x_dist=x_dist,
                                   x_mu=x_mu,
                                   x_sigma=x_sigma,
                                   z_discrete=z_discrete,
                                   z_discrete_dist=z_discrete_dist,
                                   z_n=z_n,
                                   e_dist=e_dist,
                                   e_df=e_df,
                                   e_sigma=e_sigma,
                                   n=n,
                                   model=model)) %>%
  ungroup() %>%
  cbind(., do.call('rbind', .$result)) %>%
  tibble() %>%
  select(-i, -e_df) %>%
  select(-result) -> result

write_csv(result, here::here("data/parameters/higher_order.csv"))

data.frame(a = sample(c(-1, 0, 1), num_rec, replace = TRUE),
           b = runif(num_rec, 0, 3),
           c = runif(num_rec, 0, 5),
           x_dist = sample(c("uniform", "normal", "lognormal", "neglognormal"), num_rec, replace = TRUE),
           x_mu = 0,
           x_sigma = sample(c(0.3, 0.6), num_rec, replace = TRUE),
           z_discrete = sample(c(TRUE, FALSE), num_rec, replace = TRUE),
           z_discrete_dist = "discrete_uniform",
           z_n = sample(seq(3, 10, 1), num_rec, replace = TRUE),
           e_dist = "normal",
           e_df = NA,
           e_sigma = sample(c(0.25, 0.5, 1, 2), num_rec, replace = TRUE),
           n = sample(c(50, 100, 300), num_rec, replace = TRUE),
           model = "HETEROSKEDASTICITY_MODEL") %>%
  tibble() -> mygrid

mygrid %>%
  mutate(i = 1:n()/n()) %>%
  rowwise() %>%
  mutate(result = build_and_record(i=i,
                                   a=a,
                                   b=b,
                                   c=c,
                                   x_dist=x_dist,
                                   x_mu=x_mu,
                                   x_sigma=x_sigma,
                                   z_discrete=z_discrete,
                                   z_discrete_dist=z_discrete_dist,
                                   z_n=z_n,
                                   e_dist=e_dist,
                                   e_df=e_df,
                                   e_sigma=e_sigma,
                                   n=n,
                                   model=model)) %>%
  ungroup() %>%
  cbind(., do.call('rbind', .$result)) %>%
  tibble() %>%
  select(-i, -e_df) %>%
  select(-result) -> result

write_csv(result, here::here("data/parameters/heteroskedasticity.csv"))



data.frame(c = runif(num_rec, 0, 5),
           x_dist = sample(c("uniform", "normal", "lognormal", "neglognormal"), num_rec, replace = TRUE),
           x_mu = 0,
           x_sigma = sample(c(0.3, 0.6), num_rec, replace = TRUE),
           z_discrete = sample(c(TRUE, FALSE), num_rec, replace = TRUE),
           z_discrete_dist = "discrete_uniform",
           z_n = sample(seq(3, 10, 1), num_rec, replace = TRUE),
           e_dist = sample(c("t", "bimodal", "centered_diff_geom", "centered_lognormal", "centered_neglognormal"), num_rec, replace = TRUE),
           e_df = sample(3:30, num_rec, replace = TRUE),
           e_mu = runif(num_rec, 0, 5),
           e_p1 = runif(num_rec, 0, 1),
           e_p2 = runif(num_rec, 0, 1),
           e_sigma = sample(c(0.25, 0.5, 1, 2), num_rec, replace = TRUE),
           n = sample(c(50, 100, 300), num_rec, replace = TRUE),
           model = "NON_NORMAL_MODEL") %>%
  tibble() -> mygrid

mygrid %>%
  mutate(i = 1:n()/n()) %>%
  rowwise() %>%
  mutate(result = build_and_record(i=i,
                                   c=c,
                                   x_dist=x_dist,
                                   x_mu=x_mu,
                                   x_sigma=x_sigma,
                                   z_discrete=z_discrete,
                                   z_discrete_dist=z_discrete_dist,
                                   z_n=z_n,
                                   e_dist=e_dist,
                                   e_df=e_df,
                                   e_mu=e_mu,
                                   e_p1=e_p1,
                                   e_p2=e_p2,
                                   e_sigma=e_sigma,
                                   n=n,
                                   model=model)) %>%
  ungroup() %>%
  cbind(., do.call('rbind', .$result)) %>%
  tibble() %>%
  select(-i, -e_df) %>%
  select(-result) -> result

write_csv(result, here::here("data/parameters/non_normal.csv"))




