
using Pkg
# Pkg.update()
# Pkg.add("Random")
# Pkg.add("JuMP")
# Pkg.add("Cbc")

using Random
using MathProgBase
using JuMP
using Cbc

Random.seed!(63);

include("instances_io.jl");

l = 5 # number of lines in the grid-like graph
c = 5 # number of columns in the grid-like graph
k = 10 # number of edges the adversary can penalize
maxc = 5 # range of initial edge cost
maxd = 50 # range of penalized edge cost
sv = generate(l, c, k, maxc, maxd);

arcs = []
for u in 1:sv.n, v in 1:sv.n
    if sv.adj[u][v]
        push!(arcs, (u, v))
    end
end

m = Model(solver=CbcSolver())

@variable(m, x[arcs], Bin)
@variable(m, pi[1:sv.n])

@objective(m, Max, pi[sv.n] - pi[1])

print(m)

@constraint(m, sum(x) <= k);

for (u, v) in arcs
    @constraint(m, pi[v] - pi[u] - sv.d[u][v] * x[(u, v)] <= sv.c[u][v])
end

t = @elapsed(status = solve(m))
obj = getobjectivevalue(m)
x_val = getvalue(x)
pi_val = getvalue(pi)
println("Status ", status)
println("Objective ", obj)

function solve_LP1(sv::Data, solver::MathProgBase.SolverInterface.AbstractMathProgSolver)
   
    arcs::Array{Tuple{Int, Int}, 1} = []
    for u in 1:sv.n, v in 1:sv.n
        if sv.adj[u][v]
            push!(arcs, (u, v))
        end
    end
                
    m::Model = Model(solver=CbcSolver())

    @variable(m, x[arcs], Bin)
    @variable(m, pi[1:sv.n])

    @objective(m, Max, pi[sv.n] - pi[1])
    
    @constraint(m, sum(x) <= k);            
                
    for (u, v) in arcs
        @constraint(m, pi[v] - pi[u] - sv.d[u][v] * x[(u, v)] <= sv.c[u][v])
    end
                
    solve_time::Float64 = @elapsed(status::Symbol = solve(m))
    obj::Float64 = getobjectivevalue(m)
    return status, obj, solve_time

end

solve_LP1(sv, CbcSolver())
