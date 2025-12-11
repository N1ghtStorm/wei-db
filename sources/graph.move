module wei_db_contract::graph;

use std::string::String;
use sui::object::{Self, UID};
use sui::tx_context::TxContext;

public struct Hash32 has copy, drop, store (address)

public struct Graph has key, store {
    id: UID,
    nodes: vector<Node>,
    edges: vector<Edge>,
}

public fun create_empty_graph(ctx: &mut TxContext): Graph {
    Graph {
        id: sui::object::new(ctx),
        nodes: vector::empty(),
        edges: vector::empty(),
    }
}

public fun validate_graph(graph: &Graph): bool {
    true
}

public struct Node has copy, drop, store {
    node_id: Hash32,
    node_root: Hash32,
    node_data: vector<u8>,
}

public struct Edge has copy, drop, store {
    label: String,
    from_node: Hash32,
    to_node: Hash32,
}