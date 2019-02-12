include("instances_io.jl")

using JuMP
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

function shortest_path(g::SimpleWeightedDiGraph, s::Int64, t::Int64)
    sp::LightGraphs.DijkstraState = dijkstra_shortest_paths(g, 1)
    path_cost::Float64 = sp.dists[t]

    path::Array{Int64, 1} = zeros(Int64, 0)
    next_node::Int64 = t
    while next_node != 0
        prepend!(path, next_node)
        next_node = sp.parents[next_node]
    end

    path_edges::Array{Tuple{Int64, Int64}, 1} = []
    for i in 1:length(path)-1
        (u, v)=(path[i], path[i+1])
        push!(path_edges, (u, v))
    end

    return path_cost, path, path_edges
end

function shortest_path(sv::Data, x::Dict{Tuple{Int64,Int64}, Int64})
    g::SimpleWeightedDiGraph = SimpleWeightedDiGraph(sv.n)
    for (u, v) in get_arcs(sv)
        penalized = get(x, (u, v), 0)
        cost = sv.c[u][v] + penalized * sv.d[u][v]
        add_edge!(g, u, v, cost)
    end
    return shortest_path(g, 1, sv.n)
end

function shortest_path(sv::Data, x::JuMP.JuMPArray{Float64,1,Tuple{Array{Tuple{Int64, Int64},1}}})
    g::SimpleWeightedDiGraph = SimpleWeightedDiGraph(sv.n)
    for (u, v) in get_arcs(sv)
        penalized = x[(u,v)]
        cost = sv.c[u][v] + penalized * sv.d[u][v]
        add_edge!(g, u, v, cost)
    end
    return shortest_path(g, 1, sv.n)
end

function shortest_path(sv::Data, sub_arcs::Array{Tuple{Int, Int}, 1})
    g::SimpleWeightedDiGraph = SimpleWeightedDiGraph(sv.n)
    for (u, v) in sub_arcs
        add_edge!(g, u, v, sv.c[u][v])
    end
    return shortest_path(g, 1, sv.n)
end
