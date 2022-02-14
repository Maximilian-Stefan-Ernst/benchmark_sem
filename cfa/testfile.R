library(readr)

args <- commandArgs(trailingOnly = TRUE)

date <- args[1]

dat <- iris

write_csv2(dat, paste("cfa/results/benchmarks_lavaan_", date, ".csv", sep = ""))