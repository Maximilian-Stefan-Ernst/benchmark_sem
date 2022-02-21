library(lavaan)
library(dplyr)
library(purrr)
library(readr)

set.seed(73647820)
source("functions.R")

results <- read_csv2("sem/config.csv")

results <-
  mutate(results,
         model_lavaan =
           pmap_chr(
             results,
             ~with(
               list(...),
               lavaan_model(n_factors, n_items))))

results <-
  mutate(results,
    data = pmap(
      results,
        ~with(
          list(...),
          read_csv(str_c(
            "sem/data/",
            "n_factors_",
            n_factors,
            "_n_items_",
            n_items,
            "_missing_",
            missingness,
            ".csv"))
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
               sem(
                model_lavaan,
                data,
                missing = "fiml",
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
            "sem/parest/",
            "n_factors_",
            n_factors,
            "_n_items_",
            n_items,
            "_missing_",
            missingness,
            ".csv")
        )
      )
    )