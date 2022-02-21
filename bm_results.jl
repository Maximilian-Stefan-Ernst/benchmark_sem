bm_nonsymbolic_small = @benchmark sem_fit(model_ml_small)

BenchmarkTools.Trial: 7037 samples with 1 evaluation.
 Range (min … max):  536.094 μs …  13.142 ms  ┊ GC (min … max): 0.00% … 84.11%
 Time  (median):     623.008 μs               ┊ GC (median):    0.00%
 Time  (mean ± σ):   703.678 μs ± 577.872 μs  ┊ GC (mean ± σ):  4.18% ±  4.91%

     ▃█▇▅▃▁
  ▃▄███████▇▆▆▄▄▄▃▃▃▃▃▃▂▂▂▂▂▂▂▂▂▂▁▂▂▁▁▂▁▁▂▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁ ▂
  536 μs           Histogram: frequency by time         1.24 ms <

 Memory estimate: 439.34 KiB, allocs estimate: 696.

bm_nonsymbolic_big = @benchmark sem_fit(model_ml_big)

BenchmarkTools.Trial: 10 samples with 1 evaluation.
 Range (min … max):  377.030 ms … 742.732 ms  ┊ GC (min … max): 0.00% … 0.62%
 Time  (median):     516.519 ms               ┊ GC (median):    0.00%
 Time  (mean ± σ):   538.650 ms ± 122.110 ms  ┊ GC (mean ± σ):  0.36% ± 0.49%

  ▁ ▁           █ ▁            ▁         ▁   ▁  ▁             ▁
  █▁█▁▁▁▁▁▁▁▁▁▁▁█▁█▁▁▁▁▁▁▁▁▁▁▁▁█▁▁▁▁▁▁▁▁▁█▁▁▁█▁▁█▁▁▁▁▁▁▁▁▁▁▁▁▁█ ▁
  377 ms           Histogram: frequency by time          743 ms <

 Memory estimate: 56.59 MiB, allocs estimate: 956.

# MKL

using MKL

bm_nonsymbolic_small_mkl = @benchmark sem_fit(model_ml_small)

BenchmarkTools.Trial: 4948 samples with 1 evaluation.
 Range (min … max):  712.489 μs …  12.225 ms  ┊ GC (min … max): 0.00% … 82.20%
 Time  (median):     899.797 μs               ┊ GC (median):    0.00%
 Time  (mean ± σ):     1.003 ms ± 549.112 μs  ┊ GC (mean ± σ):  2.60% ±  4.65%

        ▂▁█▄▁
  ▁▂▂▃▃▄██████▆▅▅▅▄▃▃▃▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▁▂▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁ ▂
  712 μs           Histogram: frequency by time         1.78 ms <

 Memory estimate: 439.34 KiB, allocs estimate: 696.

bm_nonsymbolic_big_mkl = @benchmark sem_fit(model_ml_big)

BenchmarkTools.Trial: 21 samples with 1 evaluation.
 Range (min … max):  149.162 ms … 401.825 ms  ┊ GC (min … max): 0.00% … 0.00%
 Time  (median):     243.611 ms               ┊ GC (median):    0.00%
 Time  (mean ± σ):   249.148 ms ±  53.616 ms  ┊ GC (mean ± σ):  0.54% ± 0.63%

  ▁   ▁      ▁    ▁█▁█▁ ▁ ▁ ▁▁█▁    ▁▁     ▁                  ▁
  █▁▁▁█▁▁▁▁▁▁█▁▁▁▁█████▁█▁█▁████▁▁▁▁██▁▁▁▁▁█▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁█ ▁
  149 ms           Histogram: frequency by time          402 ms <

 Memory estimate: 56.59 MiB, allocs estimate: 956.

# BFGS

algo = BFGS(;linesearch = BackTracking(order=3), alphaguess = InitialHagerZhang())

bm_algo_small = @benchmark sem_fit(model_ml_small)

BenchmarkTools.Trial: 3270 samples with 1 evaluation.
 Range (min … max):  937.452 μs … 21.758 ms  ┊ GC (min … max): 0.00% … 0.00%
 Time  (median):       1.255 ms              ┊ GC (median):    0.00%
 Time  (mean ± σ):     1.510 ms ±  1.043 ms  ┊ GC (mean ± σ):  2.31% ± 4.83%

   ▆█▄▂
  ▆█████▇▆▆▅▄▄▅▄▄▄▄▄▄▄▄▄▄▄▃▃▃▃▂▂▂▂▂▂▂▂▂▁▂▂▂▂▁▁▂▁▁▁▂▂▁▁▁▁▂▂▁▁▁▂ ▃
  937 μs          Histogram: frequency by time          4.1 ms <

 Memory estimate: 439.34 KiB, allocs estimate: 696.

bm_algo_big = @benchmark sem_fit(model_ml_big)

BenchmarkTools.Trial: 14 samples with 1 evaluation.
 Range (min … max):  274.281 ms … 578.298 ms  ┊ GC (min … max): 0.00% … 0.58%
 Time  (median):     340.173 ms               ┊ GC (median):    0.47%
 Time  (mean ± σ):   358.096 ms ±  82.599 ms  ┊ GC (mean ± σ):  0.54% ± 0.57%

  ▁ ▁█▁    ▁ ▁  ▁  ▁▁  ▁         ▁   ▁                        ▁
  █▁███▁▁▁▁█▁█▁▁█▁▁██▁▁█▁▁▁▁▁▁▁▁▁█▁▁▁█▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁█ ▁
  274 ms           Histogram: frequency by time          578 ms <

 Memory estimate: 56.59 MiB, allocs estimate: 956.


# profiling

ProfileView.@profview profile_test(model_ml_big, 10)

- small model: matrix inversion takes more time

big model takes more time
- SemML: 153

ML.jl, 221, uniformscaling bad performance for small model

- factorize upper triangular
