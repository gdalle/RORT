include("instances_io.jl")

using LightGraphs, SimpleWeightedGraphs

function shortest_path(sv::Data, x::Dict{Tuple{Int64,Int64}, Int64})
    g = SimpleWeightedGraph(sv.n)
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