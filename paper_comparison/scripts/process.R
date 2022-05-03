library(tidyverse)
library(visage)

preprocessing <- new.env()

# Process raw pilot data --------------------------------------------------

preprocessing$pilot <- new.env(parent = preprocessing)

# Read and write to csv ---------------------------------------------------

# The effect size for the heter model could be incorrect
preprocessing$pilot$process_pilot <- function(write = TRUE) {
  file_names <- list.files(here::here("data/pilot_study"))

  result_high <- NULL

  for (file_name in file_names[grep("oct" , file_names)]) {
    dat <- read_csv(here::here("data/pilot_study", file_name), col_types = cols())
    if (is.null(result_high)) {
      result_high <- dat
    } else {
      result_high <- bind_rows(result_high, dat)
    }
  }

  result_heter <- NULL

  for (file_name in file_names[grep("nov" , file_names)]) {
    dat <- read_csv(here::here("data/pilot_study", file_name), col_types = cols())
    if (is.null(result_heter)) {
      result_heter <- dat
    } else {
      result_heter <- bind_rows(result_heter, dat)
    }
  }

  tmp <- bind_rows(result_high, result_heter)
  tmp <- mutate(tmp, model = ifelse(model == "higher order", "cubic", model)) %>%
    rename(detect = answer, type = model)

  if (write) write_csv(tmp, file = here::here("data/processed/processed_pilot.csv"))

  return(tmp)
}


# Fit GLM for cubic and heter models --------------------------------------

preprocessing$pilot$fit_pilot_models <- function(pilot_dat) {

  pilot_dat <- pilot_dat %>%
    mutate(detect = as.numeric(detect),
           log_effect_size = log(effect_size))

  mod1 <- glm(detect ~ log(effect_size),
              data = filter(pilot_dat, type == "cubic"),
              family = binomial)

  mod2 <- glm(detect ~ log(effect_size),
              data = filter(pilot_dat, type != "cubic"),
              family = binomial)

  return(list(mod1, mod2))
}

# with(preprocessing$pilot, fit_pilot_models(process_pilot()))



# Process survey data -----------------------------------------------------

preprocessing$survey <- new.env(parent = preprocessing)


# Extract individual survey result ----------------------------------------

preprocessing$survey$get_responses <- function(survey_folder, uuid, user_info_dict) {

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
      response_dat <- get_responses(survey_folder, uuid, user_info_dict)
    } else {
      response_dat <- bind_rows(response_dat, get_responses(survey_folder, uuid, user_info_dict))
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
    mutate(conventional_p_value = map2_dbl(tmp$lineup_id, tmp$type,
                                           function(lineup_id, type) {
                                             if (is.na(lineup_id)) return(NA)

                                             if (type == "cubic") {
                                               CUBIC_MODEL$test(filter(lineup_dat[[lineup_id]]$data, null == FALSE))$p_value
                                             } else {
                                               HETER_MODEL$test(filter(lineup_dat[[lineup_id]]$data, null == FALSE))$p_value
                                             }
                                           }))

  #

}

