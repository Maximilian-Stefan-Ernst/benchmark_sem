library(ggplot2)
library(readr)
library(stringr)
library(lubridate)
library(dplyr)
library(purrr)

# command line arguments
args <- commandArgs(trailingOnly = TRUE)
compare_lavaan <- tolower(args[1]) == "true"

# list all result files

files <- list.files("cfa/results")

files_julia <- str_subset(files, "julia")
files_lavaan <- str_subset(files, "lavaan")

# extract dates
dates_julia <- str_remove_all(files_julia, "benchmarks_julia_|.csv")
dates_lavaan <- str_remove_all(files_lavaan, "benchmarks_lavaan_|.csv")

dates_julia <- lubridate::ymd_hm(dates_julia)
dates_lavaan <- lubridate::ymd_hm(dates_lavaan)

files_julia <- data.frame(filename = files_julia, date = dates_julia)
files_lavaan <- data.frame(filename = files_lavaan, date = dates_lavaan)

files_julia <- arrange(files_julia, desc(date))
files_lavaan <- arrange(files_lavaan, desc(date))

# extract only two recent files
dates_julia <- files_julia$date[1:2]
files_julia <- files_julia$filename[1:2]
data_julia <- map(files_julia, ~read_delim(paste("cfa/results/", .x, sep = ""), delim = ";",  locale = locale(decimal_mark = ".")))

data_julia[[1]] <-
    mutate(data_julia[[1]],
        datetime = dates_julia[1],
        package = "julia")
data_julia[[2]] <- 
    mutate(data_julia[[2]],
    datetime = dates_julia[2],
    package = "julia")

data_julia <- bind_rows(data_julia)

# print if all models are correct
print(paste("All models are correct:", all(data_julia$correct)))

data <- mutate(data_julia, across(c(median_time, mean_time, sd_time), function(x){x/1e9}))

if (compare_lavaan) {
    date_lavaan <- files_lavaan$date[1]
    file_lavaan <- files_lavaan$filename[1]
    data_lavaan <- read_csv2(paste("cfa/results/", file_lavaan, sep = ""))
    data_lavaan <- 
        mutate(data_lavaan,
        datetime = date_lavaan,
        package = "lavaan"
        )
    if (any(!is.na(data_lavaan$error))) {print(data_lavaan$error)}
    if (any(!is.na(data_lavaan$warnings))) {print(data_lavaan$warnings)}
    if (any(!is.na(data_lavaan$messages))) {print(data_lavaan$messages)}
    data <- bind_rows(data, data_lavaan)
}

data <- mutate(
    data,
    n_parameters = 2*(n_factors*n_items) + n_factors*(n_factors-1)/2,
    se = sd_time/sqrt(n_repetitions)
    )


# plots
# compare julia versions
p1 <- data %>%
    filter(package == "julia") %>%
    ggplot(aes(
        x = n_parameters, 
        y = median_time, 
        color = interaction(as.factor(datetime), package))) +
    geom_point() +
    geom_line() +
    geom_errorbar(aes(ymin = median_time - se, ymax = median_time + se)) +
    labs(color = "time:package") +
    theme_minimal() +
    theme(text = element_text(color = "white"))

p2 <- data %>%
    filter(package == "julia") %>%
    ggplot(aes(
        x = n_parameters, 
        y = median_time, 
        color = interaction(as.factor(datetime), package))) +
    geom_point() +
    geom_line() +
    geom_errorbar(aes(ymin = median_time - se, ymax = median_time + se)) +
    labs(color="time:package") +
    theme_minimal() +
    scale_y_log10() +
    theme(text = element_text(color = "white"))

# compare with lavaan
if (compare_lavaan) {
    p3 <- data %>%
        ggplot(aes(
            x = n_parameters, 
            y = median_time, 
            color = interaction(as.factor(datetime), package))) +
        geom_point() +
        geom_line() +
        geom_errorbar(aes(ymin = median_time - se, ymax = median_time + se)) +
        labs(color="time:package") +
        theme_minimal() +
        theme(text = element_text(color = "white"))

    p4 <- data %>%
        ggplot(aes(
            x = n_parameters, 
            y = median_time, 
            color = interaction(as.factor(datetime), package))) +
        geom_point() +
        geom_line() +
        geom_errorbar(aes(ymin = median_time - se, ymax = median_time + se)) +
        labs(color = "time:package") +
        theme_minimal() +
        scale_y_log10() +
        theme(text = element_text(color = "white"))
}

ggsave("cfa/results/plots/julia.png", p1)
ggsave("cfa/results/plots/julia_log.png", p2)
ggsave("cfa/results/plots/lavaan_julia.png", p3)
ggsave("cfa/results/plots/lavaan_julia_log.png", p4)