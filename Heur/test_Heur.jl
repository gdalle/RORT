# Import modules
include("instances_io.jl")
include("Heur.jl")
# Choose parameters
l, c, k, s, maxc, maxd = 5, 5, 20, 3, 10, 20
# Choose time limit (seconds)
time_limit = 10.
# Generate instance
sv = generate(l, c, k, s, maxc, maxd)
# Choose MC parameters
p = 100
greedy = true
# Solve problem
obj_value, x_opt = tree_search(sv, p, greedy, time_limit)
println("Objective: ", obj_value)
println("Solution: ", x_opt)
