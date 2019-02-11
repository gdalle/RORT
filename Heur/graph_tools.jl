include("instances_io.jl")

using LightGraphs, SimpleWeightedGraphs

function get_arcs(sv::Data)
    arcs::Array{Tuple{Int64, Int64}, 1} = []
    for u in 1:sv.n, v in 1:sv.n
        if sv.adj[u][v]
            push!(arcs, (u, v))
        end
    end
    return arcs
end

function shortest_path(sv::Data, x::Dict{Tuple{Int64,Int64}, Int64})
    g = SimpleWeightedDiGraph(sv.n)
    for (u, v) in get_arcs(sv)
        penalized = get(x, (u, v), 0)
        cost = sv.c[u][v] + penalized * sv.d[u][v]
        add_edge!(g, u, v, cost)
    end
    sp = dijkstra_shortest_paths(g, 1)
    path_cost = sp.dists[sv.n]
    path = []
    next_node = sv.n
    while next_node != 0
        prepend!(path, next_node)
        next_node = sp.parents[next_node]
    end
    return path_cost, path
end