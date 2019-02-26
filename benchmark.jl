using DataFrames
using CSV
using CPLEX
include("instances_io.jl")
include("PL/PL.jl");
include("Heur/Heur.jl")

param_sets = Dict{String, Array{Int, 1}}()
param_sets["L"] = collect(3:10)
param_sets["C"] = collect(3:10)
param_sets["K"] = collect(1:2:40)
param_sets["S"] = collect(1:4)
param_sets["MAXC"] = []
param_sets["MAXD"] = vcat(vcat(collect(1:10), collect(20:10:100)), collect(200:100:1000))

print(param_sets)

# Default values
l = 5
c = 5
k = 20
s = 3
maxc = 10
maxd = 20

# Number of runs for each (method, params)
nb_iterations = 3

df = DataFrame(
    method=String[],
    param=String[],
    param_value=Int[],
    iteration=Int[],
    time=Float64[],
    cuts=Int[],
    objectif=Float64[]
)

for param in ["L", "C", "K", "S", "MAXD"]
    for param_value in param_sets[param]
        for iteration in 1:5

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
            push!(df, ("PL1", param, param_value, iteration, time, 0, obj))
            time = @elapsed obj, x_opt, cuts = solve_PL2(sv, CplexSolver(CPX_PARAM_SCRIND=0))
            push!(df, ("PL2", param, param_value, iteration, time, cuts, obj))
            time = @elapsed obj, x_opt, cuts = solve_PL3(sv, CplexSolver(CPX_PARAM_SCRIND=0))
            push!(df, ("PL3", param, param_value, iteration, time, cuts, obj))
            for p in [10,20,50,100,200,500]
                time = @elapsed obj, x_opt = tree_search(sv, p)
                push!(df, ("MCTS"*string(p), param, param_value, iteration, time, 0, obj))
            end

        end

        CSV.write("Results.csv", df)

    end
    print(param)
end
