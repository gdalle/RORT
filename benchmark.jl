using DataFrames
using CSV
using CPLEX
include("instances_io.jl")
include("PL/PL.jl");
include("Heur/Heur.jl")

param_sets = Dict{String, Array{Int, 1}}()
param_sets["L"] = collect(3:8)
param_sets["C"] = collect(3:8)
param_sets["K"] = vcat(collect(1:10), collect(12:2:20))
param_sets["S"] = collect(1:4)
param_sets["MAXC"] = vcat(collect(1:10), collect(20:10:100))
param_sets["MAXD"] = vcat(collect(1:10), collect(20:10:100))

print(param_sets)

# Default values
l = 5
c = 5
k = 10
s = 3
maxc = 5
maxd = 50

# Number of runs for each (method, params)
nb_iterations = 3

df = DataFrame(
    method=String[],
    param=String[],
    param_value=Int[],
    iteration=Int[],
    time=Float64[],
    cuts=Int[]
)

for param in ["L", "C", "K", "S", "MAXC", "MAXD"]
    for param_value in param_sets[param]
        for iteration in 1:3

            if param == "L"
                sv = generate(param_value, c, k, s, maxc, maxd)
            elseif param == "C"
                sv = generate(l, param_value, k, s, maxc, maxd)
            elseif param == "K"
                sv = generate(l, c, param_value, s, maxc, maxd)
            elseif param == "S"
                sv = generate(l, c, k, param_value, maxc, maxd)
            elseif param == "MAXC"
                sv = generate(l, c, k, s, param_value, maxd)
            elseif param == "MAXD"
                sv = generate(l, c, k, s, maxc, param_value)
            end

            time = @elapsed obj, x_opt = solve_PL1(sv, CplexSolver(CPX_PARAM_SCRIND=0))
            push!(df, ("PL1", param, param_value, iteration, time, 0))
            time = @elapsed obj, x_opt, cuts = solve_PL2(sv, CplexSolver(CPX_PARAM_SCRIND=0))
            push!(df, ("PL2", param, param_value, iteration, time, cuts))
            time = @elapsed obj, x_opt, cuts = solve_PL3(sv, CplexSolver(CPX_PARAM_SCRIND=0))
            push!(df, ("PL3", param, param_value, iteration, time, cuts))
            time = @elapsed obj, x_opt = tree_search(sv, 100)
            push!(df, ("MCTS", param, param_value, iteration, time, 0))

        end

        CSV.write("Results.csv", df)

    end
end
