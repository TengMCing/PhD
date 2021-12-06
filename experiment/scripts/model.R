library(tidyverse)

MODEL_SPEC <- function(...) {

  # The MODEL_SPEC CLASS constructor

  # Crate a new environment and store parameters
  model <- new.env()
  model$parameters <- list(...)

  model$gen_x <- function(n) {

    # The default method of generating x.
    #
    # Available arguments:
    #
    # x_dist: the distribution of x, one of "uniform", "normal", "lognormal", "neglognormal",
    #   "uniform": (-1, 1),
    #   "normal": normal(x_mu, x_sigma),
    #   "lognormal": lognormal(x_mu, x_sigma^2)/3 - 1,
    #   "neglognormal": -lognormal(x_mu, x_sigma^2)/3 + 1,
    #   "discrete_uniform": n possible values from [-1, 1],
    #   "binomial": binomial(n, 0.5)/n*2 - 1.
    #
    # x_mu: mean of lognormal or normal.
    # x_sigma: sigma of lognormal or normal.
    # x_n: n of binomial or discrete_uniform.
    # z_discrete: TRUE or FALSE. Whether or not to introduce an additional discrete z. Otherwise, z ~ U(-1,1).
    #
    # z_discrete_dist: the distribution of discrete z, one of "discrete_uniform" and "binomial",
    #   "discrete_uniform": n possible values from [-1, 1],
    #   "binomial": binomial(n, 0.5)/n*2 - 1.
    #
    # z_n: n of binomial or discrete_uniform.

    x_dist <- model$parameters$x_dist
    z_discrete <- model$parameters$z_discrete
    z_discrete_dist <- model$parameters$z_discrete_dist
    z_n <- model$parameters$z_n
    x_mu <- model$parameters$x_mu
    x_sigma <- model$parameters$x_sigma
    x_n <- model$parameters$x_n

    stand_dist <- function(n, func, ...) {
      result <- func(n, ...)
      result / max(result)
    }

    mylognormal <- function(n, meanlog, sdlog) {
      rlnorm(n, meanlog, sdlog)/3 - 1
    }

    myneglognormal <- function(n, meanlog, sdlog) {
      -mylognormal(n, meanlog, sdlog)
    }

    mybinom <- function(n, size, prob) {
      rbinom(n, size, prob)/size*2-1
    }

    x <- switch(as.character(x_dist),
                "uniform" = runif(n, -1, 1),
                "normal" = stand_dist(n, rnorm, mean = x_mu, sd = x_sigma),
                "lognormal" = stand_dist(n,
                                         mylognormal,
                                         meanlog = x_mu, sdlog = x_sigma),
                "neglognormal" = stand_dist(n,
                                            myneglognormal,
                                            meanlog = x_mu, sdlog = x_sigma),
                "discrete_uniform" = sample(runif(x_n, -1, 1), n, replace = TRUE),
                "binomial" = stand_dist(n, rbinom, size = x_n, prob = 0.5)
                )

    if (identical(z_discrete, TRUE)) {
      z <- switch(as.character(z_discrete_dist),
                  "discrete_uniform" = sample(runif(z_n, -1, 1), n, replace = TRUE),
                  "binomial" = stand_dist(n, rbinom, size = z_n, prob = 0.5)
      )

      x <- as.matrix(data.frame(x, z))
      colnames(x) <- NULL
    } else {
      z <- runif(n, -1, 1)

      x <- as.matrix(data.frame(x, z))
      colnames(x) <- NULL
    }

    return(x)
  }

  model$gen_e <- function(n) {

    # The default method of generating e.
    #
    # Available arguments:
    #
    # e_dist: the distribution of e, one of "normal", "t", "bimodal", "centered_diff_geom", "centered_lognormal", "centered_neglognormal",
    #   "normal": N(0, e_sigma^2),
    #   "t": t(df = df) * e_sigma,
    #   "bimodal": 50% N(-e_mu, e_sigma^2), 50% N(e_mu, e_sigma^2),
    #   "centered_diff_geom": geometric(e_p1) - geometric(e_p2) - 1/e_p1 + 1/e_p2,
    #   "lognormal": lognormal(0, e_sigma^2) - e^(e_sigma^2/2),
    #   "neglognormal": -lognormal(0, e_sigma^2) + e^(e_sigma^2/2).
    #
    # e_sigma: sigma of normal or lognormal.
    # e_df: degree of freedom of t distribution.
    # e_p1: probability of success of geometric.
    # e_p2: probability of success of geometric.

    e_dist <- model$parameters$e_dist
    e_sigma <- model$parameters$e_sigma
    e_mu <- model$parameters$e_mu
    e_df <- model$parameters$e_df
    e_p1 <- model$parameters$e_p1
    e_p2 <- model$parameters$e_p2

    e <- switch(as.character(e_dist),
                "normal" = rnorm(n, sd = e_sigma),
                "t" = rt(n, df = e_df) * e_sigma,
                "bimodal" = sample(c(rnorm(n, -e_mu, e_sigma), rnorm(n, e_mu, e_sigma)), n),
                "centered_diff_geom" = rgeom(n, e_p1) - rgeom(n, e_p2) - 1/e_p1 + 1/e_p2,
                "centered_lognormal" = rlnorm(n, sdlog = e_sigma) - exp(e_sigma^2/2),
                "centered_neglognormal" = -rlnorm(n, sdlog = e_sigma) + exp(e_sigma^2/2)
                )

    return(e)
  }

  model$gen_y <- function() {
    # The method of generating y needs to be provided by model subclass.
  }

  model$evaluate <- function(dat) {
    # The method of evaluating the model needs to be provided by model subclass.
  }

  model$plot <- function(dat, type = "resid", equal_ratio = FALSE) {

    # The default method of making the residual vs fitted plot, residual vs x or qq-plot.
    #
    # Available arguments:
    #
    # dat: data.
    # type: type of the plot.

    if (type == "resid") {
      ggplot(dat) +
      geom_hline(yintercept = 0, col = "red", alpha = 0.4) +
      geom_point(aes(.pred, .resid), alpha = 0.5) +
      facet_wrap(~k) +
      theme_light() +
      theme(axis.line=element_blank(),
            axis.ticks=element_blank(),
            axis.text.x=element_blank(),
            axis.text.y=element_blank(),
            axis.title.x=element_blank(),
            axis.title.y=element_blank(),
            legend.position="none",
            panel.grid.major=element_blank(),
            panel.grid.minor=element_blank()) -> p
      if (equal_ratio) p <- p + coord_equal()
      return(p)
    }

    if (type == "resid_x") {
      ggplot(dat) +
        geom_hline(yintercept = 0, col = "red", alpha = 0.4) +
        geom_point(aes(x, .resid), alpha = 0.5) +
        facet_wrap(~k) +
        theme_light() +
        theme(axis.line=element_blank(),
              axis.ticks=element_blank(),
              axis.text.x=element_blank(),
              axis.text.y=element_blank(),
              axis.title.x=element_blank(),
              axis.title.y=element_blank(),
              legend.position="none",
              panel.grid.major=element_blank(),
              panel.grid.minor=element_blank()) -> p
      if (equal_ratio) p <- p + coord_equal()
      return(p)
    }

    if (type == "qq") {
      ggplot(dat) +
      geom_qq_line(aes(sample = .resid), col = "red") +
      geom_qq(aes(sample = .resid), size = 1) +
      facet_wrap(~k) +
      theme_light() +
      theme(axis.line=element_blank(),
            axis.ticks=element_blank(),
            axis.text.x=element_blank(),
            axis.text.y=element_blank(),
            axis.title.x=element_blank(),
            axis.title.y=element_blank(),
            legend.position="none",
            panel.grid.major=element_blank(),
            panel.grid.minor=element_blank()) -> p
      if (equal_ratio) p <- p + coord_equal()
      return(p)
    }

    if (type == "y_x") {
      ggplot(dat) +
        geom_point(aes(x, y), alpha = 0.5) +
        facet_wrap(~k, scales = "free_y") +
        theme_light() +
        ggtitle(glue::glue("true: {dat$k[dat$null == FALSE][1]}")) -> p
      if (equal_ratio) p <- p + coord_equal()
      return(p)
    }

    if (type == "y_pred") {
      ggplot(dat) +
        geom_smooth(aes(.pred, y), method = "lm", se = FALSE) +
        geom_point(aes(.pred, y), alpha = 0.5) +
        facet_wrap(~k, scales = "free_y") +
        theme_light() +
        ggtitle(glue::glue("true: {dat$k[dat$null == FALSE][1]}")) -> p
      if (equal_ratio) p <- p + coord_equal()
      return(p)
    }

    return(invisible(NULL))

  }

  model$update_spec <- function(...) {

    # The default method of updating model specs.

    model$parameters <- modifyList(model$parameters, list(...))
  }

  class(model) <- "MODEL_SPEC"

  return(model)
}



print.MODEL_SPEC <- function(model, ...) {
  cli::cli_h1("MODEL SPEC")
  for (i in which(!grepl("^x_", names(model$parameters)) & !grepl("^e_", names(model$parameters)) & !grepl("^z_", names(model$parameters)))) {
    cli::cli_li("{names(model$parameters)[i]} = {model$parameters[i]}")
  }
  cli::cli_h2("X")
  for (i in which(grepl("^x_", names(model$parameters)) | grepl("^z_", names(model$parameters)))) {
    cli::cli_li("{names(model$parameters)[i]} = {model$parameters[i]}")
  }
  cli::cli_h2("Error")

  for (i in grep("^e_", names(model$parameters))) {
    cli::cli_li("{names(model$parameters)[i]} = {model$parameters[i]}")
  }

  return(invisible(NULL))
}
