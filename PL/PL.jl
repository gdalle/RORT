using Random; Random.seed!(63);
using MathProgBase
using JuMP

include("../instances_io.jl")
include("../graph_tools.jl");

function solve_PL1(
        sv::Data,
        solver::MathProgBase.SolverInterface.AbstractMathProgSolver
    )

    arcs::Array{Tuple{Int64, Int64}, 1} = get_arcs(sv)

    m = Model(solver=CbcSolver())

    @variable(m, x[arcs], Bin)
    @variable(m, p[1:sv.n])

    @objective(m, Max, p[sv.n] - p[1])

    @constraint(m, sum(x) <= sv.k)

    for (u, v) in arcs
        @constraint(m, p[v] - p[u] - sv.d[u][v] * x[(u, v)] <= sv.c[u][v])
    end

    status = solve(m)
    obj = getobjectivevalue(m)
    x_val = getvalue(x)
    pi_val = getvalue(p)

    return obj, x_val
end

function solve_PL2(
        sv::Data,
        solver::MathProgBase.SolverInterface.AbstractMathProgSolver
    )

    arcs::Array{Tuple{Int64, Int64}, 1} = get_arcs(sv)

    master = Model(solver=solver)

    x = @variable(master, x[arcs], Bin)
    z = @variable(master, z<=10e7)

    s, t = 1, sv.n # source and target nodes
    @objective(master, Max, z)

    @constraint(master, sum(x[(u,v)] for (u,v) in arcs) <= sv.k)

    obj = Inf
    path_cost = 0

    while obj > path_cost + 0.5
        solve(master, relaxation=false)
        global x_opt = getvalue(x)
        obj = getobjectivevalue(master)
        (path_cost, path, path_edges) = shortest_path(sv, x_opt)
        println(path_cost, " <= value <= ", obj)
        @constraint(
            master,
            sum(sv.c[u][v] + sv.d[u][v] * x[(u,v)] for (u, v) in path_edges) >= z
        )
    end

    return obj, x_opt
end

function solve_PL3_master(
        sv::Data,
        arcs::Array{Tuple{Int, Int}, 1},
        slave_paths::Array{Array{Tuple{Int, Int}, 1}, 1},
        solver::MathProgBase.SolverInterface.AbstractMathProgSolver
    )
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

function solve_PL3_slave(
        sv::Data,
        arcs::Array{Tuple{Int, Int}, 1}
    )
    path_cost, path = shortest_path(sv, arcs)
    path_arcs::Array{Tuple{Int, Int}, 1} = []
    for i in 1:(length(path) - 1)
        push!(path_arcs, (path[i], path[i + 1]))
    end
    return path_cost, path_arcs
end

function solve_PL3(
        sv::Data,
        solver::MathProgBase.SolverInterface.AbstractMathProgSolver
    )
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
        not_over, arc_suppressed = solve_PL3_master(sv, arcs, slave_paths, solver)
        if not_over
            push!(x, arc_suppressed)
            sub_arcs::Array{Tuple{Int, Int}, 1} = setdiff(arcs, arc_suppressed)
            path_cost, path::Array{Tuple{Int, Int}, 1} = solve_PL3_slave(sv, sub_arcs)
            push!(slave_paths, path)
            push!(cost_paths, path_cost)
        end
    end
    maxval, maxidx = findmax(cost_paths)
    return maxval, x[maxidx]
end
