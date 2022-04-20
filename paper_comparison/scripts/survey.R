process_responses <- function(k, lineup_dat, lineup_ord, survey_folder) {

  dat <- tibble(id = 1:length(unlist(lineup_ord)),
                lineup_dat_id = unlist(lineup_ord)) %>%
    mutate(set = (id-1) %/% k + 1) %>%
    mutate(num = (id-1) %% k + 1)

  user_info_dict <- list(c("18-24", "25-39", "40-54", "55-64", "65 or above"),
                         c("High School or below", "Diploma and Bachelor Degree", "Honours Degree", "Masters Degree", "Doctoral Degree"),
                         c("He", "She", "They", "Other"),
                         c("Yes", "No"))

  get_responses <- function(user_info_dict, uuid) {
    tmp_survey <- jsonlite::fromJSON(here::here(glue::glue("{survey_folder}/{uuid}.txt")),
                                     simplifyVector = FALSE)
    response_time <- map_dbl(tmp_survey, ~.x$rt)
    user_information <- str_split(tmp_survey[[3]]$response[[1]], ",")[[1]]

    user_information[2:5] <- imap_chr(user_information[-1], ~user_info_dict[[.y]][as.integer(.x)])
    names(user_information) <- c("prolific_id", "age_group", "education", "pronoun", "previous_experience")


    lineup_respone <- str_split(map_chr(tmp_survey[-c(1,2,3,4)], ~.x$response$response), ",")
    # handle selections
    selections <- map_chr(lineup_respone, ~.x[1])
    # handle reasons
    reasons_dict <- c("Outlier(s)", "Cluster(s)", "Shape")

    reasons <- map_chr(lineup_respone, ~if(.x[2] %in% c("1", "2", "3")) {
      reasons_dict[as.integer(.x[2])]
    } else {
      .x[2]
    })

    # handle confidence
    confidence_dict <- c("Not at all", "Slightly", "Moderately", "Very", "Extremely")
    confidence <- map_chr(lineup_respone, ~if(.x[3] %in% c("1", "2", "3", "4", "5")) {
      confidence_dict[as.integer(.x[3])]
    } else {
      .x[3]
    })

    tibble(page = 1:length(response_time),
           response_time = response_time,
           set = uuid,
           num = c(rep(NA, 4), 1:k),
           selection = c(rep(NA, 4), selections),
           num_selection = c(rep(NA, 4), str_count(selections, "_") + 1),
           reason = c(rep(NA, 4), reasons),
           confidence = c(rep(NA, 4), confidence),
           prolific_id = unname(user_information['prolific_id']),
           age_group = unname(user_information['age_group']),
           education = unname(user_information['education']),
           pronoun = unname(user_information['pronoun']),
           previous_experience = unname(user_information['previous_experience'])
    ) %>%
      mutate(reason = ifelse(selection == "NA", NA, reason)) %>%
      mutate(confidence = ifelse(selection == "NA", NA, confidence)) %>%
      mutate(selection = ifelse(selection == "NA", "0", selection)) %>%
      mutate(num_selection = ifelse(selection == "0", 0, num_selection))
  }

  response_dat <- NULL
  file_names <- list.files(here::here(survey_folder))

  for (i in sort(as.integer(str_replace(file_names[grep("*.txt", file_names)], ".txt", "")))) {
    if (is.null(response_dat)) {
      response_dat <- get_responses(user_info_dict, i)
    } else {
      response_dat <- bind_rows(response_dat, get_responses(user_info_dict, i))
    }
  }

  correct_or_not <- function(selection, ans) {
    tmp <- imap_lgl(selection, ~ans[.y] %in% str_split(.x, "_")[[1]])
    tmp[is.na(ans)] <- NA
    tmp
  }

  extract_p_value <- function(lineup_id, lineup_dat, type) {
    if (is.na(lineup_id)) {
      return(NA)
    }

    if (type == "higher order") {
      CUBIC_MODEL$test(filter(lineup_dat[[lineup_id]]$data, null == FALSE))$p_value
    } else {
      HETER_MODEL$test(filter(lineup_dat[[lineup_id]]$data, null == FALSE))$p_value
    }
  }

  response_dat %>%
    rowwise() %>%
    mutate(lineup_id = dat$lineup_dat_id[dat$set == set & dat$num == num][1]) %>%
    mutate(metadata = list(lineup_dat[[lineup_id]]$metadata)) %>%
    ungroup() %>%
    unnest_wider(metadata) %>%
    mutate(age_group = factor(age_group,
                              levels = user_info_dict[[1]])) %>%
    mutate(education = factor(education,
                              levels = user_info_dict[[2]])) %>%
    mutate(confidence = factor(confidence,
                               levels = c("Not at all", "Slightly", "Moderately", "Very", "Extremely"))) %>%
    mutate(detected = correct_or_not(selection, ans)) %>%
    rowwise() %>%
    mutate(data_p_value = extract_p_value(lineup_id, lineup_dat, type)) %>%
    ungroup()
}




read_survey <- function() {

  lineup_dat <- readRDS(here::here("data/small_study/all_data.RDS"))
  lineup_ord <- readRDS(here::here("data/small_study/lineup_order.RDS"))

  # Correct the effect size
  for (i in 1:length(lineup_dat)) {
    if (lineup_dat[[i]]$metadata$type != "higher order") next

    tmp_eff <- visage::CUBIC_MODEL$effect_size(select(filter(lineup_dat[[i]]$data, null == FALSE), x, z),
                                       a = lineup_dat[[i]]$metadata$a,
                                       b = lineup_dat[[i]]$metadata$b,
                                       c = lineup_dat[[i]]$metadata$c,
                                       sigma = lineup_dat[[i]]$metadata$e_sigma)

    lineup_dat[[i]]$metadata$effect_size <- tmp_eff
  }

  small_survey_dat <- process_responses(20,
                                              lineup_dat = lineup_dat,
                                              lineup_ord = lineup_ord,
                                              survey_folder = "data/small_study/survey") %>%
    filter(page > 4) %>%
    mutate(difficulty = str_replace_all(name, "(high_|heter_|_\\d+)", "")) %>%
    mutate(difficulty = factor(difficulty, levels = c("extremely_easy", "easy", "medium", "hard")))

  # Delete set 18

  small_survey_dat <- filter(small_survey_dat, set != 18)
  small_survey_dat <- rename(small_survey_dat, detect = detected)

  lineup_dat_big <- readRDS(here::here("data/big_study/all_data_big.RDS"))
  lineup_ord_big <- readRDS(here::here("data/big_study/lineup_order_big.RDS"))

  # Correct the effect size
  for (i in 1:length(lineup_dat_big)) {
    if (lineup_dat_big[[i]]$metadata$type != "higher order") next

    tmp_eff <- visage::CUBIC_MODEL$effect_size(select(filter(lineup_dat_big[[i]]$data, null == FALSE), x, z),
                                       a = lineup_dat_big[[i]]$metadata$a,
                                       b = lineup_dat_big[[i]]$metadata$b,
                                       c = lineup_dat_big[[i]]$metadata$c,
                                       sigma = lineup_dat_big[[i]]$metadata$e_sigma)

    lineup_dat_big[[i]]$metadata$effect_size <- tmp_eff
  }

  big_survey_dat <- process_responses(20,
                                            lineup_dat = lineup_dat_big,
                                            lineup_ord = lineup_ord_big,
                                            survey_folder = "data/big_study/survey") %>%
    filter(page > 4) %>%
    mutate(difficulty = str_replace_all(name, "(high_|heter_|_\\d+)", "")) %>%
    mutate(difficulty = factor(difficulty, levels = c("extremely_easy", "easy", "medium", "hard")))

  big_survey_dat <- rename(big_survey_dat, detect = detected)

  merged_survey <- bind_rows(mutate(small_survey_dat, exp = 1), mutate(big_survey_dat, exp = 2))
  merged_survey <- merged_survey %>%
    mutate(type = ifelse(type == "higher order", "cubic", type))

  return(merged_survey)
}
