library(lavaan)
library(dplyr)
library(purrr)
library(readr)

set.seed(73647820)
source("functions.R")

results <- read_csv("cfa/config.csv")
results <- filter(results, meanstructure == 0)

results <-
  mutate(results,
         model_lavaan =
           pmap_chr(
             results,
             ~with(
               list(...),
               lavaan_model(n_factors, n_items, meanstructure))))

results <-
  mutate(results,
    data = pmap(
      results,
        ~with(
          list(...),
          read_csv(paste(
            "cfa/data/",
            "n_factors_",
            n_factors,
            "_n_items_",
            n_items,
            "_meanstructure_",
            meanstructure,
            ".csv", sep = ""))
            )
          )
        )

results <-
  mutate(results,
         estimate =
           pmap(
             results,
             ~with(
               list(...),
               cfa(
                model_lavaan,
                data,
                estimator = tolower(Estimator),
                std.lv = TRUE,
                se = "none", test = "none",
                baseline = F, loglik = F, h1 = F))))

results <-
  mutate(results,
         estimate =
           map(
             estimate,
             parTable))

pwalk(results,
      ~with(
        list(...),
        write_csv(
          estimate,
          str_c(
            "cfa/parest/",
            "n_factors_",
            n_factors,
            "_n_items_",
            n_items,
            "_meanstructure_",
            meanstructure,
            ".csv")
        )
      )
    )
