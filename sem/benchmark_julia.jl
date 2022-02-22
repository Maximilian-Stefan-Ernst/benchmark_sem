using DataFrames, StructuralEquationModels, Symbolics, 
    LinearAlgebra, SparseArrays, Optim, LineSearches,
    BenchmarkTools, CSV, Statistics

date = string(ARGS...)

cd("sem")

include("functions.jl")

config = DataFrame(CSV.File("config.csv"))
config2 = copy(config)
config.backend .= "Optim.jl"
config2.backend .= "NLopt.jl"

config = [config; config2]

config = filter(row -> (row.backend == "Optim.jl"), config)

data_vec = read_files("data", get_data_paths(config))
par_vec = read_files("parest", get_data_paths(config))
# start_vec = read_files("start", get_data_paths(config))

##############################################

models = gen_models(config, data_vec)

fits = get_fits(models)

correct = compare_estimates(fits, par_vec, config)

nfact = 3
nitem = 3

nobs = nfact*nitem

par_ind = [1:(2nobs+nfact-1)..., (2nobs+2nfact):(3nobs+2nfact-1)...]


config.correct = correct

##############################################
# using MKL

benchmarks = benchmark_models(models)

results = select(config, :Estimator, :n_factors, :n_items, :missingness, :backend, :correct)

results.median_time = median.(getfield.(benchmarks, :times))
results.mean_time = median.(getfield.(benchmarks, :times))
results.sd_time = std.(getfield.(benchmarks, :times))
results.n_repetitions = vec(getfield.(getfield.(benchmarks, :params), :samples))

results.n_par = 3*(results.n_factors.*results.n_items) + results.n_factors.-1

CSV.write("results/benchmarks_julia_"*date*".csv", results, delim = ";")