library(lavaan)
library(dplyr)
library(purrr)
library(readr)

set.seed(73647820)
source("cfa/functions.R")
args <- commandArgs(trailingOnly = TRUE)
date <- args[1]

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

# results$model_lavaan[[24]] <- str_remove_all(results$model_lavaan[[24]], "NA")
# results$model_lavaan[[12]] <- str_remove_all(results$model_lavaan[[12]], "NA")

results <-
  mutate(results,
         start =
           pmap(
             results,
             ~with(
               list(...),
               cfa(model_lavaan,
                 data,
                 estimator = "ml",
                 std.lv = TRUE,
                 do.fit = FALSE))))

results <-
  mutate(results,
         start =
           map(
             start,
             parTable))

results <- mutate(
  results,
  n_par = map2_dbl(
    n_factors,
    n_items,
    ~ 2*(.x*.y) + .x*(.x-1)/2
    )
  )

const <- 3*(results$n_par[length(results$n_par)]^2)

results <- mutate(
  results,
  n_repetitions = round(const/(n_par^2)))

#!!!
# results$n_repetitions <- 10
##

benchmarks <- pmap(
  results, 
  ~with(list(...),
        benchmark_lavaan(
          model_lavaan, 
          data, 
          n_repetitions, 
          Estimator)
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
    meanstructure,
    n_repetitions,
    mean_time,
    median_time,
    sd_time,
    error,
    warnings,
    messages),
    paste("cfa/results/benchmarks_lavaan_", date, ".csv", sep = ""))

# write_rds(results, "results.rds")