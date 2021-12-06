EXPERIMENT <- function(name) {

  experiment <- new.env()
  experiment$name <- name
  experiment$num_lineup <- 0
  experiment$model_list <- list()
  experiment$dat <- list()

  experiment$model <- function(name) {

    # Method of getting a model.
    #
    # Available arguments:
    #
    # name: the name of the model

    experiment$model_list[[name]]
  }

  experiment$summary_lineup <- function(lineup_id = 1, model_spec = FALSE) {

    # Method of printing summary of a lineup
    #
    # Available arguments:
    #
    # lineup_id: id of lineup
    # model_spec: whether or not to print the model spec

    if (length(experiment$dat) < lineup_id) {
      cli::cli_alert_warning("lineup {lineup_id} does not exist!")
      return(invisible(NULL))
    }
    cli::cli_h1("Lineup {lineup_id}")
    cli::cli_li("k = {experiment$dat[[lineup_id]]$metadata$k}")
    cli::cli_li("n = {experiment$dat[[lineup_id]]$metadata$n}")
    cli::cli_li("effect size = {experiment$dat[[lineup_id]]$metadata$effect_size}")
    cli::cli_li("answer = {experiment$dat[[lineup_id]]$metadata$ans}")
    if (model_spec) {
      print(experiment$model(experiment$dat[[lineup_id]]$metadata$name))
    }

    return(invisible(NULL))
  }

  experiment$summary_model <- function(name, lineup = FALSE) {

    # Method of printing summary of a model
    #
    # Available arguments:
    #
    # name: name of the model
    # lineup: whether or not to print the lineups

    print(experiment$model(name))
    if (lineup) {
      lineup_ids <- map(experiment$dat, ~.$metadata$name == name) %>%
        unlist() %>%
        which()
      for (lineup_id in lineup_ids) {
        experiment$summary_lineup(lineup_id)
      }
    }

    return(invisible(NULL))
  }

  experiment$summary <- function(input = NULL) {


    if (!is.null(input) & is.numeric(input)) {
      experiment$summary_lineup(input, model_spec = TRUE)
      return(invisible(NULL))
    }

    if (!is.null(name) & is.character(input)) {
      experiment$summary_model(input, lineup = TRUE)
      return(invisible(NULL))
    }

    print(experiment)
    return(invisible(NULL))
  }

  experiment$add_model <- function(name, model) {

    # Method of adding new model.
    #
    # Available arguments:
    #
    # name: name of the model.
    # model: a model object.

    experiment$model_list[[name]] <- model

    return(invisible(NULL))
  }

  experiment$rm_model <- function(name, force = FALSE) {

    # Method of removing a model.
    #
    # Available arguments:
    #
    # name: the name of the model.
    # force: also delete the lineups.

    if (force) {
      experiment$rm_lineup(name = name)
    }
    experiment$model_list[[name]] <- NULL

    return(invisible(NULL))
  }

  experiment$update_model <- function(name, ...) {

    # Method of updating existing model spec.
    #
    # Available arguments:
    #
    # name: name of the model.
    # ...: new spec.

    if (!name %in% names(experiment$model_list)) {
      cli::cli_alert_warning("Model {name} does not exist!")
    } else {
      experiment$model_list[[name]]$update_spec(...)
    }
    return(invisible(NULL))
  }

  experiment$plot_lineup <- function(lineup_id = 1, type = "resid", equal_ratio = FALSE) {

    # Method of making a lineup plot.
    #
    # Available arguments:
    #
    # lineup_id: the id of a lineup.
    # type: type of the plot. One of "resid" (resid vs fitted), "resid_x" (resid vs x) and "qq".
    # equal_ratio: equal ratio.

    if (length(experiment$dat) < lineup_id) {
      cli::cli_alert_warning("lineup {lineup_id} does not exist!")
      return(invisible(NULL))
    }

    plot_dat <- experiment$dat[[lineup_id]]$data
    name <- experiment$dat[[lineup_id]]$metadata$name

    experiment$model_list[[name]]$plot(plot_dat,
                                       type = type,
                                       equal_ratio = equal_ratio)

  }

  experiment$lineup <- function(lineup_id = 1, name = "") {

    # Method of getting a lineup or lineups of a model.
    #
    # Available arguments:
    #
    # lineup_id: the id of the lineup.
    # name: the name of the model.

    if (name != "") {
      return(keep(experiment$dat, ~.$metadata$name == name))
    } else {
      if (length(experiment$dat) < lineup_id) {
        cli::cli_alert_warning("lineup {lineup_id} does not exist!")
        return(invisible(NULL))
      }
      return(experiment$dat[[lineup_id]])
    }
  }

  experiment$rm_lineup <- function(lineup_id = 1, name = NULL) {

    # Method of removing a lineup or lineups of a model.
    #
    # Available arguments:
    #
    # lineup_id: the id of the lineup.
    # name: the name of the model.

    if (!is.null(name)) {
      experiment$dat <- discard(experiment$dat, ~.$metadata$name == name)
      experiment$recount_lineup()
      return(invisible(NULL))
    } else {
      if (length(experiment$dat) < lineup_id) {
        cli::cli_alert_warning("lineup {lineup_id} does not exist!")
        return(invisible(NULL))
      }
      experiment$dat[[lineup_id]] <- NULL
      experiment$recount_lineup()
      return(invisible(NULL))
    }
  }

  experiment$recount_lineup <- function() {

    # Method of recounting the number of lineups.

    experiment$num_lineup <- length(experiment$dat)
    return(invisible(NULL))
  }

  experiment$save_lineup <- function(filepath) {

    # Method of saving lineups as a rds file.
    #
    # Available arguments:
    #
    # filepath: the path to save the data.

    saveRDS(experiment$dat, file = filepath)
    return(invisible(NULL))
  }

  experiment$save_experiment <- function(filepath) {

    # Method of saving experiment as a rds file.
    #
    # Available arguments:
    #
    # filepath: the path to save the data.

    saveRDS(experiment, file = filepath)
    return(invisible(NULL))
  }

  experiment$lineup_ans <- function(lineup_id = 1) {

    # Method of getting the lineup answer.
    #
    # Available arguments:
    #
    # lineup_id: the id of the lineup.

    if (length(experiment$dat) < lineup_id) {
      cli::cli_alert_warning("lineup {lineup_id} does not exist!")
      return(invisible(NULL))
    }
    experiment$dat[[lineup_id]]$metadata$ans
  }

  experiment$get_effect_size <- function(lineup_id = 1) {

    # Method of getting the effect size of a lineup.
    #
    # Available arguments:
    #
    # lineup_id: the id of the lineup.

    if (length(experiment$dat) < lineup_id) {
      cli::cli_alert_warning("lineup {lineup_id} does not exist!")
      return(invisible(NULL))
    }

    return(experiment$dat[[lineup_id]]$metadata$effect_size)

  }

  experiment$get_pvalue <- function(lineup_id = 1, k = NULL) {

    # Method of getting the p-value of a lineup.
    #
    # Available arguments:
    #
    # lineup_id: the id of the lineup.
    # k: if NULL, return the p-value of the true plot, otherwise, return the p-value of the kth plot.

    if (length(experiment$dat) < lineup_id) {
      cli::cli_alert_warning("lineup {lineup_id} does not exist!")
      return(invisible(NULL))
    }

    if (is.null(k)) {
      tmp <- experiment$dat[[lineup_id]]$data %>%
        filter(null == FALSE)
      return(tmp$pvalue[1])
    }

    if (k > 20 | k < 1) {
      cli::cli_alert_warning("plot {k} does not exist!")
      return(invisible(NULL))
    }

    tmp <- experiment$dat[[lineup_id]]$data %>%
      filter(k == k)
    return(tmp$pvalue[1])
  }

  experiment$get_statistic <- function(lineup_id = 1, k = NULL) {

    # Method of getting the statistic of a lineup.
    #
    # Available arguments:
    #
    # lineup_id: the id of the lineup.
    # k: if NULL, return the statistic of the true plot, otherwise, return the statistic of the kth plot.

    if (length(experiment$dat) < lineup_id) {
      cli::cli_alert_warning("lineup {lineup_id} does not exist!")
      return(invisible(NULL))
    }

    if (is.null(k)) {
      tmp <- experiment$dat[[lineup_id]]$data %>%
        filter(null == FALSE)
      return(tmp$statistic[1])
    }

    if (k > 20 | k < 1) {
      cli::cli_alert_warning("plot {k} does not exist!")
      return(invisible(NULL))
    }

    tmp <- experiment$dat[[lineup_id]]$data %>%
      filter(k == k)
    return(tmp$statistic[1])
  }

  experiment$gen_lineup_data <- function(name, k = 20, n = 100) {

    # Method of generating a lineup.
    #
    # Available arguments:
    #
    # name: the name of the model.
    # k: number of plots in a lineup.
    # n: number of observations.

    if (!name %in% names(experiment$model_list)) {
      cli::cli_alert_warning("Model {name} does not exist!")
      return(invisible(NULL))
    }

    # obtain data
    dat <- experiment$model_list[[name]]$gen_y(n)

    # obtain test statistic for true plot
    tmp <- experiment$model_list[[name]]$evaluate(dat)
    dat$testname <- tmp[[1]]
    dat$statistic <- tmp[[2]]
    dat$pvalue <- tmp[[3]]

    # obtain effect size for true plot
    effect_size <- experiment$model_list[[name]]$effect_size(dat)
    dat$effect_size <- effect_size


    # obtain assumed model
    mod <- experiment$model_list[[name]]$fit(dat)

    k_order <- sample(1:k)

    dat$.resid <- resid(mod)
    dat$.pred <- predict(mod)
    dat$null <- FALSE
    dat$name <- name
    dat$k <- k_order[1]
    experiment$num_lineup <- experiment$num_lineup + 1
    dat$lineup_id <- experiment$num_lineup

    se <- sigma(mod)
    rss <- function(mod) sum(resid(mod)^2)

    result <- dat

    for (i in 2:k) {
      newdat <- dat

      # rotation of residuals
      newdat$y <- rnorm(n)
      newmod <- update(mod, data = newdat)
      newdat$.resid <- resid(newmod) * sqrt(rss(mod)/rss(newmod))
      newdat$y <- newdat$.resid + newdat$.pred

      # obtain test statistic for null plot
      tmp <- experiment$model_list[[name]]$evaluate(newdat)
      newdat$testname <- tmp[[1]]
      newdat$statistic <- tmp[[2]]
      newdat$pvalue <- tmp[[3]]

      newdat$null <- TRUE
      newdat$k <- k_order[i]

      result <- bind_rows(result, newdat)
    }

    experiment$dat[[experiment$num_lineup]] <- list(metadata = append(experiment$model_list[[name]]$parameters,
                                                                      list(name = name,
                                                                           k = k,
                                                                           n = n,
                                                                           effect_size = effect_size,
                                                                           ans = k_order[1])),
                                                    data = result)

    return(invisible(NULL))

  }

  experiment$save_plots <- function(filepath, plot_string = "NA", k = 20, rep = 3, type = "resid") {

    # Method of saving lineups as PNGs.
    #
    # Available arguments:
    #
    # filepath: the filepath.
    # plot_string: string prefix.
    # k: number of lineups in a set.
    # rep: number of rep.
    # type: type of plot.

    # number of lineups that will be used
    num_lineup <- trunc(experiment$num_lineup / k) * k

    total_lineup <- 0
    current_set <- 0

    final_ord <- c()

    for (j in 1:rep) {
      ord_id <- sample(1:num_lineup)
      final_ord <- c(final_ord, ord_id)
      for (i in 1:num_lineup) {

        total_lineup <- total_lineup + 1
        current_set <- ((total_lineup - 1) %/% k) + 1
        current_lineup <- ((total_lineup - 1) %% k) + 1

        ggsave(paste0(filepath,
                      "/",
                      plot_string[current_set],
                      "_set",
                      current_set,
                      "_",
                      current_lineup,
                      ".png"),
               experiment$plot_lineup(ord_id[i], type="resid"),
               height = 7,
               width = 7)
      }
    }

    return(final_ord)
  }

  class(experiment) <- "EXPERIMENT"

  return(experiment)
}


print.EXPERIMENT <- function(experiment, ...) {
  cli::cli_h1("EXPERIMENT DETAILS")
  cli::cli_alert_info("Name : {experiment$name}")
  cli::cli_alert_info("Number of lineups: {experiment$num_lineup}")
  cli::cli_h2("Number of models: {length(experiment$model_list)}")
  for (name in names(experiment$model_list)) {
    cli::cli_li("{name} : {length(keep(experiment$dat, ~.$metadata$name == name))} lineup{?s}")
  }

  return(invisible(NULL))
}
