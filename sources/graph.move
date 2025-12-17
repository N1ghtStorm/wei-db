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


public enum EdgeLabel has copy, drop, store {
    Bytes(vector<u8>),
    Number(u64),
    Hash(Hash32),
}

public struct Edge has copy, drop, store {
    edge_id: Hash32,
    label: EdgeLabel,
    from_node: Hash32,
    to_node: Hash32,
}

public fun get_node_id(node: &Node): Hash32 {
    node.node_id
}

public fun get_edge_label(edge: &Edge): EdgeLabel {
    edge.label
}

public fun get_edge_from_node(edge: &Edge): Hash32 {
    edge.from_node
}

public fun get_edge_to_node(edge: &Edge): Hash32 {
    edge.to_node
}

public fun edge_labels_equal(label1: &EdgeLabel, label2: &EdgeLabel): bool {
    match (label1) {
        EdgeLabel::Bytes(b1) => {
            match (label2) {
                EdgeLabel::Bytes(b2) => {
                    let len1 = vector::length(b1);
                    let len2 = vector::length(b2);
                    if (len1 != len2) {
                        return false
                    };
                    let mut i = 0;
                    while (i < len1) {
                        if (*vector::borrow(b1, i) != *vector::borrow(b2, i)) {
                            return false
                        };
                        i = i + 1;
                    };
                    true
                },
                _ => false,
            }
        },
        EdgeLabel::Number(n1) => {
            match (label2) {
                EdgeLabel::Number(n2) => n1 == n2,
                _ => false,
            }
        },
        EdgeLabel::Hash(h1) => {
            match (label2) {
                EdgeLabel::Hash(h2) => h1 == h2,
                _ => false,
            }
        },
    }
}

public fun get_nodes(graph: &Graph): &vector<Node> {
    &graph.nodes
}

public fun get_edges(graph: &Graph): &vector<Edge> {
    &graph.edges
}