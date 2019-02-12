using Random; Random.seed!(63);
using Statistics

include("../instances_io.jl")
include("../graph_tools.jl");

function intelligent_arc_ordering(sv::Data)
    arcs = get_arcs(sv)
    function sorting_criterion(a::Tuple{Int64, Int64})
        u, v = a
        return sv.d[u][v]
    end
    return sort(arcs, by=sorting_criterion, rev=true)
end

function random_child(
        ordered_arcs::Array{Tuple{Int64, Int64}, 1},
        x::Dict{Tuple{Int64, Int64}, Int64},
        k::Int64
    )
    n_arcs::Int64 = length(ordered_arcs)
    n_fixed::Int64 = length(x)
    if (k <= 0) | (n_arcs == n_fixed)
        return copy(x)
    end

    left_to_penalize::Array{Int64, 1} = rand(n_fixed+1:n_arcs, k)

    x_completed::Dict{Tuple{Int64, Int64}, Int64} = copy(x)
    for (a, (u, v)) in enumerate(ordered_arcs[n_fixed+1:n_arcs])
        if a in left_to_penalize
            x_completed[(u, v)] = 1
        else
            x_completed[(u, v)] = 0
        end
    end

    return x_completed

end

function evaluate_subtree(sv::Data, ordered_arcs::Array{Tuple{Int64, Int64}, 1},
        x::Dict{Tuple{Int64, Int64}, Int64},
        k::Int64,
        p::Int64
    )
    if (k == 0) | (length(x) == length(ordered_arcs))
        return shortest_path(sv, x)[1]
    else
        mean_cost::Float64 = 0
        for l in 1:p
            child = random_child(ordered_arcs, x, k)
            mean_cost += shortest_path(sv, child)[1] / p
        end
        return mean_cost
    end
end

function tree_search(sv::Data, p::Int)
    ordered_arcs::Array{Tuple{Int64, Int64}, 1} = intelligent_arc_ordering(sv)
    x::Dict{Tuple{Int64, Int64}, Int64} = Dict{Tuple{Int64, Int64}, Int64}()
    k::Int64 = sv.k

    for next_arc in ordered_arcs

        if k == 0
            x[next_arc] = 0
        else
            x[next_arc] = 0
            mean_cost_0 = evaluate_subtree(sv, ordered_arcs, x, k, p)
            x[next_arc] = 1
            mean_cost_1 = evaluate_subtree(sv, ordered_arcs, x, k-1, p)

            if mean_cost_0 > mean_cost_1
                x[next_arc] = 0
            else
                x[next_arc] = 1
                k -= 1
            end
        end
    end

    return shortest_path(sv, x)[1], x
end
