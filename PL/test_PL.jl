using CPLEX
# Import modules
include("instances_io.jl")
include("PL.jl")
# Choose parameters
l, c, k, s, maxc, maxd = 5, 5, 20, 3, 10, 20
# Choose time limit (seconds)
time_limit = 10.
# Generate instance
sv = generate(l, c, k, s, maxc, maxd)
# Choose method
method = "PL2"
# Solve problem
if method == "PL1"
    solver = CplexSolver(CPX_PARAM_SCRIND=0, CPX_PARAM_TILIM=time_limit)
    obj_value, x_opt = solve_PL1(sv, solver)
elseif method == "PL2"
    solver = CplexSolver(CPX_PARAM_SCRIND=0)
    obj_value, x_opt, count = solve_PL2(sv, solver, time_limit)
elseif method == "PL3"
    solver = CplexSolver(CPX_PARAM_SCRIND=0)
    obj_value, x_opt, count = solve_PL3(sv, solver, time_limit)
end
println("Objective: ", obj_value)
println("Solution: ", x_opt)
