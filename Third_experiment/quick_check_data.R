library(tidyverse)
library(visage)

preprocessing <- new.env()

# Process survey data -----------------------------------------------------

preprocessing$survey <- new.env(parent = preprocessing)


# Extract individual survey result ----------------------------------------

preprocessing$survey$get_responses <- function(survey_folder, uuid, user_info_dict, k = 20) {

  survey_result <- jsonlite::fromJSON(here::here(glue::glue("{survey_folder}/{uuid}.txt")),
                                      simplifyVector = FALSE)

  response_time <- map_dbl(survey_result, ~.x$rt)

  # The thrid page is the user information page
  user_information <- str_split(survey_result[[3]]$response$user_information, ",")[[1]]


  # The first response is the Prolific ID, we replace the 2 to 5 elements by the correspoding choices
  user_information[2:5] <- imap_chr(user_information[-1], ~user_info_dict[[.y]][as.integer(.x)])

  names(user_information) <- c("prolific_id", "age_group", "education", "pronoun", "previous_experience")


  # Get the lineup responses (list of 20)
  # The first four pages are not lineups
  lineup_respone <- str_split(map_chr(survey_result[-(1:4)], ~.x$response$response), ",")

  # handle selections
  # The first response is the selection
  selections <- map_chr(lineup_respone, ~.x[1])

  # handle reasons
  # The second response is the reason
  reasons_dict <- c("Outlier(s)", "Cluster(s)", "Shape")

  # If the reason is "1", "2" or "3", then map using the dictionary,
  # otherwise, keep the user provided reason or "NA"
  reasons <- map_chr(lineup_respone, ~if(.x[2] %in% c("1", "2", "3")) {
    reasons_dict[as.integer(.x[2])]
  } else {
    .x[2]
  })

  # handle confidence
  # The thrid response is the confidence
  confidence_dict <- c("Not at all", "Slightly", "Moderately", "Very", "Extremely")

  # If the confidence is "1", "2", "3", "4" or "5", then map using the dictionary,
  # otherwise, keep the user provided confidence ("NA")
  confidence <- map_chr(lineup_respone, ~if(.x[3] %in% c("1", "2", "3", "4", "5")) {
    confidence_dict[as.integer(.x[3])]
  } else {
    .x[3]
  })


  # Output a tibble
  # 24 rows, 20 lineup responses
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
         previous_experience = unname(user_information['previous_experience'])) %>%
    mutate(reason = ifelse(selection == "NA", NA, reason)) %>%
    mutate(confidence = ifelse(selection == "NA", NA, confidence)) %>%
    mutate(selection = ifelse(selection == "NA", "0", selection)) %>%
    mutate(num_selection = ifelse(selection == "0", 0, num_selection))
}



# Decide whether the selection detect the answer --------------------------

preprocessing$survey$detect_or_not <- function(selection, answer) {
  detect <- imap_lgl(selection, ~answer[.y] %in% as.integer(str_split(.x, "_")[[1]]))
  detect[is.na(selection)] <- NA
  detect
}



# process responses in a survey -------------------------------------------

# `survey_folder` is the one contatins all the .txt files
# `k` is the number of lineups shown to a participant
# `lineup_dat` is a list. Each item contains a list of metadata, and a dataframe of the observations
# `lineup_ord` is the order of lineups presented to participants
preprocessing$survey$process_responses <- function(survey_folder, k = 20, lineup_dat, lineup_ord) {

  get_responses <- preprocessing$survey$get_responses
  detect_or_not <- preprocessing$survey$detect_or_not

  # Produce a tibble of id, lineup_dat_id, set, num
  dat <- tibble(id = 1:length(unlist(lineup_ord)),
                lineup_id = unlist(lineup_ord)) %>%
    mutate(set = (id-1) %/% k + 1) %>%
    mutate(num = (id-1) %% k + 1)

  user_info_dict <- list(age = c("18-24", "25-39", "40-54", "55-64", "65 or above"),
                         edcuation = c("High School or below", "Diploma and Bachelor Degree", "Honours Degree", "Masters Degree", "Doctoral Degree"),
                         pronoun = c("He", "She", "They", "Other"),
                         experience = c("Yes", "No"))

  response_dat <- NULL

  # Files in the folder
  file_names <- list.files(here::here(survey_folder))

  # Get all filenames aligned with the format "\digits.txt", and extract "\digits"
  uuids <- sort(as.integer(gsub("^(\\d+).txt$", "\\1", file_names[grep("^\\d+.txt", file_names)])))

  for (uuid in uuids) {
    if (is.null(response_dat)) {
      response_dat <- get_responses(survey_folder, uuid, user_info_dict, k = 20)
    } else {
      response_dat <- bind_rows(response_dat, get_responses(survey_folder, uuid, user_info_dict, k = 20))
    }
  }


  # Output a tibble
  response_dat <- response_dat %>%

    # Left join to add lineup_id
    left_join(select(dat, -id), by = c("set", "num")) %>%

    # Add metadata list to column metadata
    mutate(metadata = map(lineup_id, ~lineup_dat[[.x]]$metadata)) %>%

    # Unnest the metatdat column and clean up some metadata
    unnest_wider(metadata)  %>%
    rename(answer = ans) %>%
    mutate(type = ifelse(type == "higher order", "cubic", type)) %>%

    # Check if the answer being detected
    mutate(detect = detect_or_not(selection, answer)) %>%

    # Perform the conventional tests and get the p-values
    mutate(conventional_p_value = map_dbl(lineup_id,
                                          function(lineup_id) {
                                            if (is.na(lineup_id)) return(NA)

                                            POLY_MODEL$test(filter(lineup_dat[[lineup_id]]$data, null == FALSE))$p_value
                                          })) %>%

    # Discard non-lineup pages
    filter(page > 4)

}


lineup_dat <- readRDS("data/third_experiment_dat.rds")
lineup_order <- read_csv("data/third_experiment_order.txt", col_names = FALSE) %>%
  t() %>%
  as.data.frame() %>%
  as.list() %>%
  unname()

lineup_info <- read_csv("data/lineup_info.csv")
allocated <- read_csv("data/allocate_result.csv")

poly_result <- preprocessing$survey$process_responses("survey", lineup_dat = lineup_dat, lineup_ord = lineup_order)


poly_result %>%
  filter(lineup_id > 576) %>%
  group_by(set) %>%
  summarise(attention = sum(detect)) %>%
  left_join(poly_result %>%
              group_by(set) %>%
              summarise(button = sum(num_selection < 1))) %>%
  left_join(poly_result %>%
              group_by(set) %>%
              summarise(many = sum(num_selection > 5))) -> check_dat






cenv <- new.env()

p_value <- poly_result %>%
  calc_p_value_multi(detected = "detect", n_sel = "num_selection", cache_env = cenv) %>%
  left_join(poly_result %>%
              count(lineup_id) %>%
              rename(num_eval = n)) %>%
  left_join(lineup_info)

poly_result %>%
  mutate(detect = as.numeric(detect)) %>%
  ggplot() +
  # geom_point(aes(log(effect_size), detect)) +
  geom_smooth(aes(log(effect_size), detect, col = factor(shape)), se = FALSE)

poly_result %>%
  mutate(detect = as.numeric(detect)) %>%
  ggplot() +
  geom_point(aes(e_sigma, detect)) +
  geom_smooth(aes(e_sigma, detect, col = factor(shape)), se = FALSE)
