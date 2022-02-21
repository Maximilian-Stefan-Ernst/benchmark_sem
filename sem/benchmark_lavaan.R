library(lavaan)
library(dplyr)
library(purrr)
library(readr)

set.seed(73647820)
source("sem/functions.R")
args <- commandArgs(trailingOnly = TRUE)
date <- args[1]

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

#results <-
#  mutate(results,
#         start =
#           pmap(
#             results,
#             ~with(
#               list(...),
#               sem(model_lavaan,
#                 data,
#                 missing = "fiml",
#                 std.lv = TRUE,
#                 do.fit = FALSE))))

#results <-
#  mutate(results,
#         start =
#           map(
#             start,
#             parTable))

results <- mutate(
  results,
  n_par = map2_dbl(
    n_factors,
    n_items,
    ~ 3*(.x*.y) + .x-1
    )
  )

const <- 3*(results$n_par[length(results$n_par)]^2)

results <- mutate(
  results,
  n_repetitions = round(const/(n_par^2)))

benchmarks <- pmap(
  results, 
  ~with(list(...),
        benchmark_lavaan(
          model_lavaan, 
          data, 
          n_repetitions)
        )
  )

benchmark_summary <- map_dfr(benchmarks, extract_results)

results <- bind_cols(results, benchmark_summary)

write_csv2(
    select(
    results,
    Estimator,
    n_factors,
    n_items,
    missingness,
    n_repetitions,
    mean_time,
    median_time,
    sd_time,
    error,
    warnings,
    messages),
    paste("sem/results/benchmarks_lavaan_", date, ".csv", sep = ""))
