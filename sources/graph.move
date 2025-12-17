module wei_db_contract::graph;

use std::string::String;
use sui::object::{Self, UID};
use sui::tx_context::TxContext;

public struct Hash32 has copy, drop, store (address)

public fun create_hash32(addr: address): Hash32 {
    Hash32(addr)
}

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

#[test_only]
public fun add_node(graph: &mut Graph, node: Node) {
    vector::push_back(&mut graph.nodes, node);
}

#[test_only]
public fun add_edge(graph: &mut Graph, edge: Edge) {
    vector::push_back(&mut graph.edges, edge);
}

#[test_only]
public fun create_edge_label_number(n: u64): EdgeLabel {
    EdgeLabel::Number(n)
}

#[test_only]
public fun create_edge_label_bytes(b: vector<u8>): EdgeLabel {
    EdgeLabel::Bytes(b)
}

#[test_only]
public fun create_edge_label_hash(h: Hash32): EdgeLabel {
    EdgeLabel::Hash(h)
}

#[test_only]
public fun create_node(node_id: Hash32, node_root: Hash32, node_data: vector<u8>): Node {
    Node {
        node_id,
        node_root,
        node_data,
    }
}

#[test_only]
public fun create_edge(edge_id: Hash32, label: EdgeLabel, from_node: Hash32, to_node: Hash32): Edge {
    Edge {
        edge_id,
        label,
        from_node,
        to_node,
    }
}

#[test_only]
public fun create_traverse_out_params(
    where_edge_and_labels: vector<EdgeLabel>,
    where_edge_or_labels: vector<EdgeLabel>,
    where_edge_not_and_labels: vector<EdgeLabel>,
    where_edge_not_or_labels: vector<EdgeLabel>,
): TraverseOutParams {
    TraverseOutParams {
        where_edge_and_labels,
        where_edge_or_labels,
        where_edge_not_and_labels,
        where_edge_not_or_labels,
    }
}

public struct TraverseOutParams has drop {
    // labels to include with AND ruling
    where_edge_and_labels: vector<EdgeLabel>,
    // labels to include with OR ruling
    where_edge_or_labels: vector<EdgeLabel>,
    // labels to exclude with AND ruling
    where_edge_not_and_labels: vector<EdgeLabel>,
    // labels to exclude with OR ruling
    where_edge_not_or_labels: vector<EdgeLabel>,
}

public fun traverse_out(
    graph: &Graph,
    from_nodes: vector<Hash32>,
    params: &TraverseOutParams,
): vector<Node> {
    let mut result_node_hashes = vector::empty<Hash32>();
    let from_len = vector::length(&from_nodes);
    let edges = get_edges(graph);
    let edges_len = vector::length(edges);
    
    let mut i = 0;
    while (i < from_len) {
        let from_node = *vector::borrow(&from_nodes, i);
        
        let mut j = 0;
        while (j < edges_len) {
            let edge = vector::borrow(edges, j);
            let edge_label = get_edge_label(edge);
            let edge_from = get_edge_from_node(edge);
            let edge_to = get_edge_to_node(edge);
            
            // Check if edge matches traverse params
            let should_include = check_edge_match(&edge_label, params);
            
            if (edge_from == from_node && should_include) {
                // Check if to_node is already in result_node_hashes
                let mut found = false;
                let result_len = vector::length(&result_node_hashes);
                let mut k = 0;
                while (k < result_len && !found) {
                    if (*vector::borrow(&result_node_hashes, k) == edge_to) {
                        found = true;
                    };
                    k = k + 1;
                };
                if (!found) {
                    vector::push_back(&mut result_node_hashes, edge_to);
                };
            };
            j = j + 1;
        };
        i = i + 1;
    };
    
    // Convert hashes to full nodes
    let mut result_nodes = vector::empty<Node>();
    let nodes = get_nodes(graph);
    let nodes_len = vector::length(nodes);
    let result_hashes_len = vector::length(&result_node_hashes);
    
    let mut i_hash = 0;
    while (i_hash < result_hashes_len) {
        let target_hash = *vector::borrow(&result_node_hashes, i_hash);
        let mut j_node = 0;
        while (j_node < nodes_len) {
            let node = vector::borrow(nodes, j_node);
            if (get_node_id(node) == target_hash) {
                vector::push_back(&mut result_nodes, *node);
                break
            };
            j_node = j_node + 1;
        };
        i_hash = i_hash + 1;
    };
    
    result_nodes
}

fun check_edge_match(label: &EdgeLabel, params: &TraverseOutParams): bool {
    // Check AND labels (all must match)
    let and_len = vector::length(&params.where_edge_and_labels);
    if (and_len > 0) {
        let mut all_match = true;
        let mut i = 0;
        while (i < and_len && all_match) {
            let required_label = vector::borrow(&params.where_edge_and_labels, i);
            if (!edge_labels_equal(label, required_label)) {
                all_match = false;
            };
            i = i + 1;
        };
        if (!all_match) {
            return false
        };
    };
    
    // Check OR labels (at least one must match)
    let or_len = vector::length(&params.where_edge_or_labels);
    if (or_len > 0) {
        let mut any_match = false;
        let mut i = 0;
        while (i < or_len && !any_match) {
            let or_label = vector::borrow(&params.where_edge_or_labels, i);
            if (edge_labels_equal(label, or_label)) {
                any_match = true;
            };
            i = i + 1;
        };
        if (!any_match) {
            return false
        };
    };
    
    // Check NOT AND labels (none should match)
    let not_and_len = vector::length(&params.where_edge_not_and_labels);
    if (not_and_len > 0) {
        let mut i = 0;
        while (i < not_and_len) {
            let not_label = vector::borrow(&params.where_edge_not_and_labels, i);
            if (edge_labels_equal(label, not_label)) {
                return false
            };
            i = i + 1;
        };
    };
    
    // Check NOT OR labels (if any matches, exclude)
    let not_or_len = vector::length(&params.where_edge_not_or_labels);
    if (not_or_len > 0) {
        let mut i = 0;
        while (i < not_or_len) {
            let not_or_label = vector::borrow(&params.where_edge_not_or_labels, i);
            if (edge_labels_equal(label, not_or_label)) {
                return false
            };
            i = i + 1;
        };
    };
    
    true
}