source(here::here("scripts/model.R"))

survey_tools <- new.env()

survey_tools$process_responses <- function(k, lineup_dat, lineup_ord) {

  dat <- tibble(id = 1:length(unlist(lineup_ord)),
                lineup_dat_id = unlist(lineup_ord)) %>%
    mutate(set = (id-1) %/% k + 1) %>%
    mutate(num = (id-1) %% k + 1)

  user_info_dict <- list(c("18-24", "25-39", "40-54", "55-64", "65 or above"),
                         c("High School or below", "Diploma and Bachelor Degree", "Honours Degree", "Masters Degree", "Doctoral Degree"),
                         c("He", "She", "They", "Other"),
                         c("Yes", "No"))

  get_responses <- function(user_info_dict, uuid) {
    tmp_survey <- jsonlite::fromJSON(here::here(glue::glue("study_1/study_1_big_check/survey/{uuid}.txt")),
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
  file_names <- list.files(here::here("study_1/study_1_big_check/survey"))

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

  extract_p_value <- function(lineup_id, lineup_dat, null = FALSE) {
    if (is.na(lineup_id)) {
      return(NA)
    }

    tmp <- lineup_dat[[lineup_id]]$data %>%
      group_by(k) %>%
      summarise(null = first(null), pvalue = first(pvalue)) %>%
      ungroup()

    data_p <- tmp$pvalue[tmp$null == FALSE]
    null_min_p <- min(tmp$pvalue[tmp$null == TRUE])
    if (null) {
      return(null_min_p)
    } else {
      return(data_p)
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
    mutate(data_p_value = extract_p_value(lineup_id, lineup_dat, null = FALSE)) %>%
    mutate(null_min_p_value = extract_p_value(lineup_id, lineup_dat, null = TRUE)) %>%
    ungroup()
}

survey_tools$show_plot <- function(lineup_dat, id, selected = "") {
  selected <- as.numeric(unlist(str_split(selected, "_")))
  ggplot(lineup_dat[[id]]$data) +
    geom_hline(yintercept = 0, col = "red", alpha = 0.4) +
    geom_point(aes(.pred, .resid, col = k %in% selected), alpha = 0.5) +
    facet_wrap(~k) +
    theme_light() +
    scale_color_manual(values = c("TRUE" = "red", "FALSE" = "black")) +
    theme(axis.line=element_blank(),
          axis.ticks=element_blank(),
          axis.text.x=element_blank(),
          axis.text.y=element_blank(),
          axis.title.x=element_blank(),
          axis.title.y=element_blank(),
          legend.position="none",
          panel.grid.major=element_blank(),
          panel.grid.minor=element_blank())
}

survey_tools$calc_pvalue <- function(x, K, k, m = 20, N = 50000) {

  dvismulti3 <- function(K, k, m = 20, N = 5000) {
    stopifnot((K == length(k)) | (length(k) == 1))
    k <- rep(k, length = K)
    res <- replicate(N, {
      lp <- runif(m)
      success <- map_dbl(1:K, function(i) {
        sum(sample(1:m, size = k[i], replace = FALSE, prob = lp) == 1)
      })
      sum(success)
    })
    res <- factor(res, levels = 0:K)
    table(res) / N
  }

  my_density <- as.vector(dvismulti3(K, k, m, N))
  if (x == 0) {
    return(1)
  } else {
    if (x + 1 > length(my_density)) stop("number of detected plots greater than number of evaluations")
    return(1 - cumsum(my_density)[x])
  }
}
