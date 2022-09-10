library(visage)
library(tidyverse)
library(cli)


# We need
# a (3) = -1, 0, 1
# b (5) = 0.25, 1, 4, 16, 64
# x_dist (1) = uniform
# n (3) = 50, 100, 300
# rep (3)
#
# 3 * 5 * 1 * 3 * 3 = 135
#
# shape (4)
# e_sigma (4) = 0.5, 1, 2, 4
# x_dist (1) = uniform
# n (3) = 50, 100, 300
# rep (3)
#
# 4 * 4 * 1 * 3 * 3 = 144
#
# null lineups for heter and poly:
# x_dist (4)
# n (3)
# rep (3)
# 4 * 3 * 3 = 36
#
# ((135 + 144) * 6 + 36 * 15) / 18 = 123
#
# We need 123 subjects


library(visage)
library(tidyverse)

lineup <- polynomials %>%
  mutate(exp = "poly") %>%
  bind_rows(heter %>% mutate(exp = "heter")) %>%
  filter((x_dist == "uniform" | b == 0), is.na(b) | b <= 64, e_sigma > 0.25) %>%
  mutate(real_lineup_id = paste0(exp, "_", lineup_id)) %>%
  group_by(real_lineup_id) %>%
  summarise(across(c(a, b, n, x_dist, shape, e_sigma), first)) %>%
  mutate(lineup_id = 1:n()) %>%
  mutate(limit_num = ifelse(b != 0 | is.na(b), 6, 15)) %>%
  mutate(across(everything(), function(x) ifelse(is.na(x), "NA", x)))

sorted_lineup <- lineup %>%
  arrange(lineup_id) %>%
  select(-lineup_id, -real_lineup_id, -limit_num)


set.seed(10086)

check_comb <- function(set_dat, new_dat, n = 1) {

  apply(combn(dim(set_dat)[2], n),
        MARGIN = 2,
        function(this_comb) {
          # browser()
          tmp <- as.numeric(new_dat[1, this_comb])
          for (i in 1:nrow(set_dat)) {
            tmp_x <- all(as.numeric(set_dat[i, this_comb]) == tmp)
            if (is.na(tmp_x)) return(FALSE)
            if (tmp_x) return(TRUE)
          }
          return(FALSE)
        })
}

# Caculate distance between a set of allocated lineups and a new lineup
calc_dist <- function(lineup, allocated_lineup_ids, new_lineup_id) {

  new_lineup <- sorted_lineup[new_lineup_id, ]
  allocated_lineups <- sorted_lineup[allocated_lineup_ids, ]

  # We want these three options to be as different as possible
  63 -
    sum(check_comb(allocated_lineups, new_lineup, 1)) -
    sum(check_comb(allocated_lineups, new_lineup, 2)) -
    sum(check_comb(allocated_lineups, new_lineup, 3)) -
    sum(check_comb(allocated_lineups, new_lineup, 4)) -
    sum(check_comb(allocated_lineups, new_lineup, 5)) -
    sum(check_comb(allocated_lineups, new_lineup, 6))
}

find_available_subject <- function(allocate_list) {
  map_dbl(allocate_list, length) %>%
    rank(ties.method = "random") %>%
    which.min()
}


find_available_lineups <- function(allocate_list, this_subject, num_lineup) {
  unlist(allocate_list) %>%
    factor(levels = 1:num_lineup) %>%
    table() %>%
    as_tibble() %>%
    rename(lineup_id = ".") %>%
    mutate(lineup_id = as.integer(lineup_id)) %>%
    left_join(select(lineup, lineup_id, limit_num), by = c("lineup_id")) %>%
    filter(n < limit_num) %>%
    {setdiff(.$lineup_id, allocate_list[[this_subject]])} %>%
    sample()
}

log_allocate <- function(this_subject, best_lineup_id,
                         lineup_rep,
                         subject_pool,
                         verbose) {
  if (verbose == 0) return(invisible(NULL))

  cli_alert_success("Allocate lineup {.val {best_lineup_id}} ({lineup_rep}/?) {symbol$arrow_right} {.val {this_subject}}.")
  if (verbose >= 1) {
    cli_alert_info("Subject {.val {this_subject}} pool ({length(subject_pool)}/18): {paste(subject_pool, collapse = ' ')}")
  }
}

log_find_subject <- function(this_subject, verbose) {
  if (verbose > 1) {
    cli_alert_success("Found a random empty slot in subject {.val {this_subject}}.")
  }
}

log_find_lineup <- function(available_lineup_ids, verbose) {
  if (verbose > 1) {
    cli_alert_success("Found {.val {length(available_lineup_ids)}} available lineups in random order.")
  }
}

log_best_dist <- function(best_dist, lineup_id, verbose) {
  if (verbose > 1) {
    cli_alert_success("Found new best distance {.val {round(best_dist, 4)}} for lineup {.val {lineup_id}}!")
  }
}

log_progress_bar <- function(total = NULL,
                             start = NULL,
                             end = NULL) {
  if (!is.null(start)) {
    cli_progress_bar("Allocating lineups", total = total,
                     .envir = parent.frame())
    return(invisible(NULL))
  }

  if (!is.null(end)) {
    cli_progress_done(.envir = parent.frame())
    return(invisible(NULL))
  }

  cli_progress_update(.envir = parent.frame())
}


allocate_lineup_2_subject <- function(lineup, num_subject, verbose = 0) {

  # Init allocate list with length = number of subjects
  allocate_list <- vector(mode = "list", length = num_subject)
  num_lineup <- nrow(lineup)

  log_progress_bar(start = TRUE, total = num_subject * 18 + 2)

  # If there are still empty slots in the experiment
  while (length(unlist(allocate_list)) < num_subject * 18) {

    log_progress_bar()

    if (verbose > 0) {
      cli_h1("")
    }

    # Reset all local varialbes
    best_lineup_id <-
      available_subject <-
      allocated_lineup_ids <-
      available_lineup_ids <- NULL

    best_dist <- -.Machine$integer.max

    # Find an available subject
    available_subject <- find_available_subject(allocate_list)
    log_find_subject(available_subject, verbose)

    # Get the set of lineups being allocated to that subject
    allocated_lineup_ids <- allocate_list[[available_subject]]

    # Get the set of lineup that have less than 5 replicates
    available_lineup_ids <- find_available_lineups(allocate_list, available_subject, num_lineup)
    log_find_lineup(available_lineup_ids, verbose)

    # No available lineups (all lineups >= limit). Randomly pick one.
    if (length(available_lineup_ids) == 0) {
      best_lineup_id <- setdiff(1:num_lineup, allocated_lineup_ids) %>%
        sample(1)

      allocate_list[[available_subject]] <- c(allocate_list[[available_subject]],
                                              best_lineup_id)

      log_allocate(available_subject, best_lineup_id,
                   sum(unlist(allocate_list) == best_lineup_id),
                   allocate_list[[available_subject]],
                   verbose)

      next
    }

    # No allocated lineups. Use the one with least replicates.
    if (length(allocated_lineup_ids) == 0) {

      best_lineup_id <- unlist(allocate_list) %>%
        factor(levels = 1:num_lineup) %>%
        table() %>%
        unname() %>%
        {.[available_lineup_ids]} %>%
        which.min() %>%
        {available_lineup_ids[.]}

      allocate_list[[available_subject]] <- c(allocate_list[[available_subject]],
                                              best_lineup_id)

      log_allocate(available_subject, best_lineup_id,
                   sum(unlist(allocate_list) == best_lineup_id),
                   allocate_list[[available_subject]],
                   verbose)

      next
    }

    # Check available lineups one by one
    for (new_lineup_id in available_lineup_ids) {

      # Calculate how good the current lineup is
      current_dist <- calc_dist(lineup, allocated_lineup_ids, new_lineup_id)

      # Store the best one
      if (current_dist > best_dist) {
        best_dist <- current_dist
        best_lineup_id <- new_lineup_id
        log_best_dist(best_dist, new_lineup_id, verbose)

        if (best_dist == 63) break
      }
    }

    allocate_list[[available_subject]] <- c(allocate_list[[available_subject]],
                                            best_lineup_id)

    log_allocate(available_subject, best_lineup_id,
                 sum(unlist(allocate_list) == best_lineup_id),
                 allocate_list[[available_subject]],
                 verbose)
  }

  log_progress_bar(end = TRUE)

  allocate_list
}

# If you feel it is a bit laggy. Clear the console or turn off verbose.
allocate_result <- allocate_lineup_2_subject(lineup, 123, verbose = 2)

# All lineups have 5 replicates, except 33 and 83
unlist(allocate_result) %>%
  factor(levels = 1:nrow(lineup)) %>%
  table() %>%
  unname() %>%
  {. != 6 & . != 15} %>%
  which()

# 33 has 7 evaluations
unlist(allocate_result) %>%
  factor(levels = 1:nrow(lineup)) %>%
  table() %>%
  unname() %>%
  {. == 7} %>%
  which()

# 83 has 14 evaluations
unlist(allocate_result) %>%
  factor(levels = 1:nrow(lineup)) %>%
  table() %>%
  unname() %>%
  {. == 14} %>%
  which()

# Manual adjustment
# Find subject (20) that contains 33 but not 83
which(map_lgl(allocate_result, ~33 %in% .x && !(83 %in% .x) ))
allocate_result[[20]][allocate_result[[20]] == 33] <- 83

# All subjects have 18 different lineups
map_dbl(allocate_result, ~length(unique(.x))) %>%
  {. != 18} %>%
  which()

allocate_result <- allocate_result %>%
  `names<-`(paste("subject", 1:123, sep = "_")) %>%
  as_tibble() %>%
  pivot_longer(subject_1:subject_123) %>%
  mutate(subject = gsub(".+_", "", name)) %>%
  select(subject, lineup_id = value)

saveRDS(allocate_result, "tmp_alloc.rds")

set.seed(10086)

lineup <- lineup %>%
  bind_rows(expand.grid(a = c(0, 1),
                        n = 300,
                        x_dist = "uniform",
                        b = c(128, 256),
                        rep = 1:3) %>%
              mutate(lineup_id = nrow(lineup) + 1:n()))

allocate_result <- mutate(allocate_result, subject = as.numeric(subject))

for (i in 1:160) {
  allocate_result <- allocate_result %>%
    bind_rows(tibble(subject = i,
                     lineup_id = sample(1:12, 2) + 576))
}

allocate_result <- allocate_result %>%
  group_by(subject) %>%
  mutate(order = sample(1:20))

write_csv(allocate_result, "data/allocate_result.csv")
write_csv(lineup, "data/lineup_info.csv")


allocate_result %>%
  left_join(lineup, by = c("lineup_id")) %>%
  write_csv("data/allocate_result_full.csv")
