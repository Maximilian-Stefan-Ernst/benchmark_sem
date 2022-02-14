library(ggplot2)
library(readr)
library(stringr)
library(lubridate)
library(dplyr)
library(purrr)
library(tidyr)

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
julia_latest <- dates_julia[1]
julia_previous <- dates_julia[2]
files_julia <- files_julia$filename[1:2]
data_julia <- map(
    files_julia, 
    ~read_delim(
        paste("cfa/results/", .x, sep = ""), 
        delim = ";",  
        locale = locale(decimal_mark = "."),
        show_col_types = FALSE)
        )

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

data_julia <- mutate(
    data_julia,
    across(
        c(median_time, mean_time, sd_time), 
        function(x){x/1e9}))

if (compare_lavaan) {
    date_lavaan <- files_lavaan$date[1]
    file_lavaan <- files_lavaan$filename[1]
    data_lavaan <- read_delim(
        paste("cfa/results/", file_lavaan, sep = ""),
        delim = ";",
        locale = locale(decimal_mark = ","),
        show_col_types = FALSE)
    data_lavaan <-
        mutate(data_lavaan,
        datetime = date_lavaan,
        package = "lavaan"
        )
    if (any(!is.na(data_lavaan$error))) {print(data_lavaan$error)}
    if (any(!is.na(data_lavaan$warnings))) {print(data_lavaan$warnings)}
    if (any(!is.na(data_lavaan$messages))) {print(data_lavaan$messages)}
    data <- bind_rows(data_julia, data_lavaan)
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

p2.2 <- data %>%
    filter(package == "julia") %>%
    mutate(datetime = ifelse(datetime == julia_latest, "latest", "previous")) %>%
    select(n_parameters, datetime, median_time) %>%
    pivot_wider(
        names_from = datetime,
        values_from = median_time) %>%
    mutate(ratio_latest_previous = latest/previous) %>%
    ggplot(aes(
        x = n_parameters, 
        y = ratio_latest_previous)) +
    geom_point() +
    geom_line() +
    theme_minimal() +
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

    p5 <- data %>%
        filter((package == "lavaan"|datetime == julia_latest)) %>%
        select(n_parameters, package, median_time) %>%
        pivot_wider(
            names_from = package,
            values_from = median_time) %>%
        mutate(ratio_julia_lavaan = julia/lavaan) %>%
        ggplot(aes(
            x = n_parameters,
            y = ratio_julia_lavaan)) +
        geom_point() +
        geom_line() +
        theme_minimal() +
        theme(text = element_text(color = "white")) +
        scale_y_continuous(
            limits = c(0, NA),
            breaks = c(seq(0, 0.1, 0.02), seq(0.1, 1, 0.1))
        )
}

ggsave("cfa/results/plots/julia.png", p1)
ggsave("cfa/results/plots/julia_log.png", p2)
ggsave("cfa/results/plots/ratio_julia.png", p2.2)
ggsave("cfa/results/plots/lavaan_julia.png", p3)
ggsave("cfa/results/plots/lavaan_julia_log.png", p4)
ggsave("cfa/results/plots/ratio_julia_lavaan.png", p5)