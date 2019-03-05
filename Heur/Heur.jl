using Random; Random.seed!(63);
using Statistics
using StatsBase

include("instances_io.jl")
include("graph_tools.jl");


function choose_next_arc_fast(sv::Data, x::Dict{Tuple{Int64, Int64}, Int64})
    for (u, v) in get_arcs(sv)
        if !((u, v) in keys(x))
            return (u, v)
        end
    end
end

function choose_best_arc_on_shortest_path(sv::Data, x::Dict{Tuple{Int64, Int64}, Int64})
    _, _, shortest_path_edges = shortest_path(sv, x)
    max_pen_edge = (0, 0)
    max_pen = typemin(Int64)
    for (u, v) in shortest_path_edges
        if (u, v) in keys(x)
            continue
        end
        if sv.d[u][v] > max_pen
            max_pen_edge = (u, v)
            max_pen = sv.d[u][v]
        end
    end
    return max_pen_edge
end

function choose_next_arc(
        sv::Data,
        x::Dict{Tuple{Int64, Int64}, Int64},
        k::Int64,
        greedy::Bool
    )
    if greedy && (k > 0)
        (us, vs) = choose_best_arc_on_shortest_path(sv, x)
        if (us, vs) != (0, 0)
            return (us, vs)
        else
            return choose_next_arc_fast(sv, x)
        end
    else
        return choose_next_arc_fast(sv, x)
    end
end

function random_child(
        x::Dict{Tuple{Int64, Int64}, Int64},
        k::Int64,
        remaining_arcs::Array{Tuple{Int64, Int64}, 1}
    )
    x_completed::Dict{Tuple{Int64, Int64}, Int64} = copy(x)

    if (k <= 0) || (length(remaining_arcs) == 0)
        return x_completed
    elseif length(remaining_arcs) <= k
        for (u, v) in remaining_arcs
            x_completed[(u, v)] = 1
        end
        return x_completed
    else
        left_to_penalize::Set{Tuple{Int64, Int64}} = Set(
            sample(remaining_arcs, k, replace=false))
        for (u, v) in remaining_arcs
            if (u, v) in left_to_penalize
                x_completed[(u, v)] = 1
            else
                x_completed[(u, v)] = 0
            end
        end
        return x_completed
    end
end

function evaluate_subtree(
        sv::Data,
        x::Dict{Tuple{Int64, Int64}, Int64},
        k::Int64,
        p::Int64
    )
    if (k == 0) | (length(x) == length(sv.arcs))
        return shortest_path(sv, x)[1]
    else
        remaining_arcs::Array{Tuple{Int64, Int64}, 1} = [
            (u, v) for (u, v) in get_arcs(sv)
            if !((u, v) in keys(x))
        ]
        mean_cost::Float64 = 0
        for l in 1:p
            child = random_child(x, k, remaining_arcs)
            mean_cost += shortest_path(sv, child)[1] / p
        end
        return mean_cost
    end
end

function tree_search(sv::Data, p::Int, greedy::Bool, time_limit::Float64)
    x::Dict{Tuple{Int64, Int64}, Int64} = Dict{Tuple{Int64, Int64}, Int64}()
    k::Int64 = sv.k

    shuffle!(sv.arcs)

    arcs_explored::Int64 = 0
    start_time::Float64 = time()

    while true

        if (
            length(x) == length(get_arcs(sv)) ||
            (time() - start_time > time_limit)
        )
            break
        end

        next_arc::Tuple{Int64, Int64} = choose_next_arc(sv, x, k, greedy)

        if k == 0
            x[next_arc] = 0

        else
            x[next_arc] = 0
            mean_cost_0 = evaluate_subtree(sv, x, k, p)
            x[next_arc] = 1
            mean_cost_1 = evaluate_subtree(sv, x, k-1, p)

            if mean_cost_0 > mean_cost_1
                x[next_arc] = 0
            else
                x[next_arc] = 1
                k -= 1
            end
        end

        arcs_explored += 1
    end

    return shortest_path(sv, x)[1], x
end
