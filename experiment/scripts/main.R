source(here::here("scripts/model_collections.R"))
source(here::here("scripts/experiment.R"))

set.seed(10086)

myexp <- EXPERIMENT(name = "visual inference")
higher_order <- HIGHER_ORDER_MODEL(a = 0.5, b = 1, c = 0,
                                   x_dist = "uniform",
                                   x_discrete = FALSE,
                                   e_dist = "normal", e_sigma = 1)
myexp$add_model("higher order", higher_order)
