function get_data_paths(config)
    data_paths = []
    for i = 1:nrow(config)
        row = config[i, :]
        miss = replace(row.missingness, "," => ".")
        file = string(
            "n_factors_",
            row.n_factors,
            "_n_items_",
            row.n_items,
            "_missing_",
            miss, 
            ".csv"
            )
        push!(data_paths, file)
    end
    return data_paths
end

function read_files(dir, data_paths)
    data = Vector{Any}()
    for i in 1:length(data_paths)
        push!(data, DataFrame(CSV.read(dir*"/"*data_paths[i], DataFrame; missingstring = "NA")))
    end
    return data
end

function gen_SEM_RAM(nfact, nitem)
    nfact = Int64(nfact)
    nitem = Int64(nitem)

    ## Model definition
    nobs = nfact*nitem
    nnod = nfact+nobs
    npar = 3nobs + nfact-1
    Symbolics.@variables x[1:npar]

    #F
    Ind = collect(1:nobs)
    Jnd = collect(1:nobs)
    V = fill(1,nobs)
    F = sparse(Ind, Jnd, V, nobs, nnod)

    #A
    Ind = collect(1:nobs)
    Jnd = vcat([fill(nobs+i, nitem) for i in 1:nfact]...)
    V = [x...][1:nobs]
    A = sparse(Ind, Jnd, V, nnod, nnod)
    xind = nobs+1
    for i in nobs+1:nnod-1
        A[i+1,i] = x[xind]
        xind = xind+1
    end

    #S
    Ind = collect(1:nnod)
    Jnd = collect(1:nnod)
    V = [[x...][nobs+nfact:2nobs+nfact-1]; fill(1.0, nfact)]
    S = sparse(Ind, Jnd, V, nnod, nnod)

	M = [[x...][2nobs+nfact:3nobs+nfact-1]...; fill(0.0, nfact)]
    

    return RAMMatrices(;A = A, S = S, F = F, M = M, parameters = x)
end

function gen_model(nfact, nitem, data, backend)

    ram_matrices = gen_SEM_RAM(nfact, nitem)

    if backend == "Optim.jl"
        semdiff = SemDiffOptim(
            LBFGS(
                ;linesearch = BackTracking(order=3), 
                alphaguess = InitialHagerZhang()
                ),
            Optim.Options(
                ;f_tol = 1e-10,
                x_tol = 1.5e-8)
            )
    elseif backend =="NLopt.jl"
        semdiff = SemDiffNLopt(
            :LD_LBFGS,
            nothing
            )
    end

    model = Sem(
            ram_matrices = ram_matrices,
            data = data,
            imply = RAM,
            diff = semdiff,
            loss = (SemFIML,),
            start_val = start_simple,
            observed = SemObsMissing
        )
                
    return model
end

function gen_models(config, data_vec)
    models = []
    for i = 1:nrow(config)
        row = config[i, :]
        model = gen_model(row.n_factors, row.n_items, Matrix(data_vec[i]), row.backend)
        push!(models, model)
    end
    return models
end

function benchmark_models(models)
    benchmarks = []
    for model in models
        bm = @benchmark sem_fit($model)
        push!(benchmarks, bm)
    end
    return benchmarks
end

function get_fits(models)
    fits = []
    for model in models
        fit = sem_fit(model)
        push!(fits, fit)
    end
    return fits
end

function compare_estimates(fits, par_vec, config)
    correct = 
        [compare_estimate(fit, estimate, n_factors, n_items) for 
                (fit, estimate, n_factors, n_items) in zip(fits, par_vec, config.n_factors, config.n_items)]
    return correct
end

function compare_estimate(fit, estimate, n_factors, n_items)
    
    nfact = Int64(n_factors)
    nitem = Int64(n_items)

    nobs = nfact*nitem

    par_ind = [1:(2nobs+nfact-1)..., (2nobs+2nfact):(3nobs+2nfact-1)...]

    solution = fit.solution

    return StructuralEquationModels.compare_estimates(estimate.est[par_ind], solution, 0.01)

end