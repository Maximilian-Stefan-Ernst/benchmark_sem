using DataFrames, StructuralEquationModels, Symbolics, 
    LinearAlgebra, SparseArrays, Optim, LineSearches,
    BenchmarkTools, CSV, Statistics

cd("cfa")

include("functions.jl")

config = DataFrame(CSV.File("config.csv"))
config2 = copy(config)
config.backend .= "Optim.jl"
config2.backend .= "NLopt.jl"

config = [config; config2]

config = filter(row -> (row.backend == "Optim.jl") & (row.meanstructure == 0), config)

data_vec = read_files("data", get_data_paths(config))
par_vec = read_files("parest", get_data_paths(config))
# start_vec = read_files("start", get_data_paths(config))

##############################################

models = gen_models(config, data_vec)

# fits = get_fits(models)

# correct = compare_estimates(fits, par_vec, config)

# config.correct = correct

############################################
# some benchmarks
############################################

using BenchmarkTools

semdiff = SemDiffOptim(
    LBFGS(
        ;linesearch = BackTracking(order=3), 
        alphaguess = InitialHagerZhang()
        ),
    Optim.Options(
        ;f_tol = 1e-10,
        x_tol = 1.5e-8)
    )

ram_matrices_small = gen_CFA_RAM(3, 5)

ram_matrices_big = gen_CFA_RAM(5, 40)

model_ml_small = Sem(
    ram_matrices = ram_matrices_small,
    data = Matrix(data_vec[2]),
    imply = RAM,
    diff = semdiff 
)

model_ml_big = Sem(
    ram_matrices = ram_matrices_big,
    data = Matrix(data_vec[6]),
    imply = RAM,
    diff = semdiff 
)

############################################
# some benchmarks
############################################

bm_nonsymbolic_small = @benchmark sem_fit(model_ml_small)

bm_nonsymbolic_big = @benchmark sem_fit(model_ml_big)

# MKL

using MKL

bm_nonsymbolic_small_mkl = @benchmark sem_fit(model_ml_small)

bm_nonsymbolic_big_mkl = @benchmark sem_fit(model_ml_big)

# BFGS

algo = BFGS(;linesearch = BackTracking(order=3), alphaguess = InitialHagerZhang())

model_ml_small = Sem(
    ram_matrices = ram_matrices_small,
    data = Matrix(data_vec[2]),
    imply = RAM,
    diff = semdiff,
    algorithm = algo
)

model_ml_big = Sem(
    ram_matrices = ram_matrices_big,
    data = Matrix(data_vec[6]),
    imply = RAM,
    diff = semdiff,
    algorithm = algo
)

bm_algo_small = @benchmark sem_fit(model_ml_small)

bm_algo_big = @benchmark sem_fit(model_ml_big)


using ProfileView

function profile_test(model, n)
    for _ = 1:n
        sem_fit(model)
    end
end

ProfileView.@profview profile_test(model_ml_big, 10)