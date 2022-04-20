# pilot study data

# effect size might be unreliable

read_pilot <- function() {
  file_names <- list.files(here::here("data/pilot_study"))

  library(tidyverse)

  result_high <- NULL

  for (file_name in file_names[grep("oct" , file_names)]) {
    dat <- read_csv(here::here("data/pilot_study", file_name))
    if (is.null(result_high)) {
      result_high <- dat
    } else {
      result_high <- bind_rows(result_high, dat)
    }
  }

  result_heter <- NULL

  for (file_name in file_names[grep("nov" , file_names)]) {
    dat <- read_csv(here::here("data/pilot_study", file_name))
    if (is.null(result_heter)) {
      result_heter <- dat
    } else {
      result_heter <- bind_rows(result_heter, dat)
    }
  }

  bind_rows(result_high, result_heter)
}

pilot_model <- function(pilot_dat) {

  pilot_dat <- pilot_dat %>%
    mutate(detect = as.numeric(answer),
           log_effect_size = log(effect_size))

  mod1 <- glm(detect ~ log(effect_size),
              data = filter(pilot_dat, model == "higher order"),
              family = binomial)

  mod2 <- glm(detect ~ log(effect_size),
              data = filter(pilot_dat, model != "higher order"),
              family = binomial)

  return(list(mod1, mod2))
}
