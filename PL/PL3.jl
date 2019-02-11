using Pkg
# Pkg.update()
# Pkg.add("Random")
# Pkg.add("JuMP")
# Pkg.add("Cbc")
# Pkg.add("MathProgBase")
# Pkg.add("LightGraphs")
# Pkg.add("SimpleWeightedGraphs")

using Random
using MathProgBase
using JuMP
using Cbc

Random.seed!(63);

include("instances_io.jl");
include("shortest.jl");

l = 5 # number of lines in the grid-like graph
c = 5 # number of columns in the grid-like graph
k = 3 # number of edges the adversary can penalize
maxc = 5 # range of initial edge cost
maxd = 50 # range of penalized edge cost
sv = generate(l, c, k, maxc, maxd);

function solve_master(sv::Data, arcs::Array{Tuple{Int, Int}, 1}, slave_paths::Array{Array{Tuple{Int, Int}, 1}, 1}, solver::MathProgBase.SolverInterface.AbstractMathProgSolver)
    m::Model = Model(solver=CbcSolver())
    @objective(m, Max, 1)
    @variable(m, x[arcs], Bin)
    @constraint(m, sum(x) <= k);
    for path in slave_paths
        @constraint(m, sum(x[a] for a in path) >= 1)
    end
    status = solve(m)
    if status == :Infeasible
        return false, nothing
    else
        arc_suppressed::Array{Tuple{Int, Int}, 1} = []
        for (u, v) in arcs
            if getvalue(x[(u, v)]) == 1
                push!(arc_suppressed, (u, v))
            end
        end
        return true, arc_suppressed
    end
end

function solve_slave(sv::Data, arcs::Array{Tuple{Int, Int}, 1})
    path_cost, path = shortest_path_subgraph(sv, arcs)
    path_arcs::Array{Tuple{Int, Int}, 1} = []
    for i in 1:(length(path) - 1)
        push!(path_arcs, (path[i], path[i + 1]))
    end
    return path_cost, path_arcs
end

function solve_PL3(sv::Data, solver::MathProgBase.SolverInterface.AbstractMathProgSolver)
    arcs::Array{Tuple{Int, Int}, 1} = []
    for u in 1:sv.n, v in 1:sv.n
        if sv.adj[u][v]
            push!(arcs, (u, v))
        end
    end
    not_over::Bool = true
    slave_paths::Array{Array{Tuple{Int, Int}, 1}, 1} = []
    cost_paths::Array{Float32, 1} = []
    x::Array{Array{Tuple{Int, Int}, 1}, 1} = []
    while not_over
        not_over, arc_suppressed = solve_master(sv, arcs, slave_paths, solver)
        if not_over
            push!(x, arc_suppressed)
            sub_arcs::Array{Tuple{Int, Int}, 1} = setdiff(arcs, arc_suppressed)
            path_cost, path::Array{Tuple{Int, Int}, 1} = solve_slave(sv, sub_arcs)
            push!(slave_paths, path)
            push!(cost_paths, path_cost)
        end
    end
    maxval, maxidx = findmax(cost_paths)
    return x[maxidx], maxval
end

sol, val = solve_PL3(sv, CbcSolver())
