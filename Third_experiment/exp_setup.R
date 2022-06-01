library(ggExtra)
library(tidyverse)
library(visage)
library(lhs)
library(cli)

get_trunc_norm_cdf <- function(sd = 1, ndraws = 10^7) {
  result <- rnorm(ndraws, mean = 0, sd = sd)
  result <- result[result >= -1.5 & result <= 1.5]
  function(p) {
    quantile(result, probs = p) %>%
      unname()
  }
}

trans_unif_2_norm <- function(x, sd = 1, ndraws = 10^7) {
  p_trunc_norm <- get_trunc_norm_cdf(sd, ndraws)
  p_trunc_norm(x)
}

trans_unif_2_discrete <- function(x, level = NULL) {
  level[trunc(x * length(level)) + 1]
}



# Shape of the trunc density
ggplot() +
  geom_density(aes(trans_unif_2_norm(seq(0, 1, 0.00001))), col = "red")


# V1: a in -1.5 ~ 1.5
# V2: b in -1.5 ~ 1.5
# V3: N: 50, 100, 300
# V4: x_dist: uniform, normal, lognormal, neglognormal, even_dis, uneven_dis
# V5: e_sigma: 0.125, 0.25, 0.5, 1

# 9 (a and b combinations) * 3 * 6 * 4 = 720

# rep: 5

set.seed(10086)

num_ab_comb <- 9

# Generate unique lineups
lineup <- randomLHS(num_ab_comb * 3 * 6 * 4, 2) %>%
  as.data.frame() %>%
  mutate(a = trans_unif_2_norm(V1, sd = 0.5),
         b = trans_unif_2_norm(V2, sd = 0.5)) %>%
  bind_cols(map(1:num_ab_comb, function(x) {
    expand.grid(n = c(50, 100, 300),
                x_dist = c("uniform", "normal", "lognormal", "neglognormal",
                           "even_discrete", "uneven_discrete"),
                e_sigma = c(0.125, 0.25, 0.5, 1),
                ab = x)
    }) %>%
    reduce(bind_rows)) %>%
  select(-V1, -V2, -ab) %>%
  mutate(lineup_id = 1:n())

# Check a and b distribution
lineup %>%
  ggplot() +
  geom_point(aes(a, b)) +
  facet_grid(x_dist~e_sigma+n)

# Caculate distance between a set of allocated lineups and a new lineup
calc_dist <- function(lineup, allocated_lineup_ids, new_lineup_id) {

  new_lineup <- lineup %>%
    filter(lineup_id == new_lineup_id)

  allocated_lineups <- lineup %>%
    filter(lineup_id %in% allocated_lineup_ids)

  # We want these three options to be as differnet as possible
  3 -
    new_lineup$x_dist %in% allocated_lineups$x_dist -
    new_lineup$e_sigma %in% allocated_lineups$e_sigma -
    new_lineup$n %in% allocated_lineups$n +

  # We want the new lineup has `a` and `b` that are far away from allocated lineups
  min((allocated_lineups$a - new_lineup$a)^2 + (allocated_lineups$b - new_lineup$b)^2)/18

}

find_available_subject <- function(allocate_list) {
  map_dbl(allocate_list, length) %>%
    which.min()
}

find_available_lineups <- function(allocate_list, this_subject, num_rep, num_lineup) {
  unlist(allocate_list) %>%
    factor(levels = 1:num_lineup) %>%
    table() %>%
    unname() %>%
    {. < num_rep} %>%
    which() %>%
    setdiff(allocate_list[[this_subject]])
}

log_allocate <- function(this_subject, best_lineup_id,
                         lineup_rep, num_rep,
                         subject_pool,
                         verbose) {
  if (verbose == 0) return(invisible(NULL))

  cli_alert_success("Allocate lineup {.val {best_lineup_id}} ({lineup_rep}/{num_rep}) {symbol$arrow_right} {.val {this_subject}}.")
  if (verbose >= 1) {
    cli_alert_info("Subject {.val {this_subject}} pool ({length(subject_pool)}/18): {paste(subject_pool, collapse = ' ')}")
  }
}

log_find_subject <- function(this_subject, verbose) {
  if (verbose > 1) {
    cli_alert_success("Found empty slots for subject {.val {this_subject}}.")
  }
}

log_find_lineup <- function(available_lineup_ids, verbose) {
  if (verbose > 1) {
    cli_alert_success("Found {.val {length(available_lineup_ids)}} available lineups.")
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

allocate_lineup_2_subject <- function(lineup, num_subject, num_rep, verbose = 0) {

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
    available_lineup_ids <- find_available_lineups(allocate_list, available_subject, num_rep, num_lineup)
    log_find_lineup(available_lineup_ids, verbose)

    # No available lineups (all lineups >= 5). Randomly pick one.
    if (length(available_lineup_ids) == 0) {
      best_lineup_id <- setdiff(1:num_lineup, allocated_lineup_ids) %>%
        sample(1)

      allocate_list[[available_subject]] <- c(allocate_list[[available_subject]],
                                              best_lineup_id)

      log_allocate(available_subject, best_lineup_id,
                   sum(unlist(allocate_list) == best_lineup_id), num_rep,
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
                   sum(unlist(allocate_list) == best_lineup_id), num_rep,
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
      }
    }

    allocate_list[[available_subject]] <- c(allocate_list[[available_subject]],
                                            best_lineup_id)

    log_allocate(available_subject, best_lineup_id,
                 sum(unlist(allocate_list) == best_lineup_id), num_rep,
                 allocate_list[[available_subject]],
                 verbose)
  }

  log_progress_bar(end = TRUE)

  allocate_list
}


# If you feel it is a bit laggy. Clear the console or turn off verbose.
allocate_result <- allocate_lineup_2_subject(lineup, 180, 5, verbose = 2)


# All lineups have 5 replicates
unlist(allocate_result) %>%
  factor(levels = 1:nrow(lineup)) %>%
  table() %>%
  unname() %>%
  {. != 5} %>%
  which()

# All subjects have 18 different lineups
map_dbl(allocate_result, ~length(unique(.x))) %>%
  {. != 18} %>%
  which()

allocate_result <- allocate_result %>%
  `names<-`(paste("subject", 1:180, sep = "_")) %>%
  as_tibble() %>%
  pivot_longer(subject_1:subject_180) %>%
  mutate(subject = gsub(".+_", "", name)) %>%
  select(subject, lineup_id = value)

write_csv(allocate_result, "allocate_result.csv")
write_csv(lineup, "lineup_info.csv")
