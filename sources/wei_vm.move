module wei_db_contract::wei_vm;

use wei_db_contract::graph::{Self, Hash32, Node, Edge, EdgeLabel, Graph};

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

public enum Opcode has drop {
    SetCurrentFromAllNodes,
    CreateNodes {
        nodes: vector<Node>,
    },
    CreateEdges {
        edges: vector<Edge>,
    },
    SetLimit(u64),
    TraverseOut(TraverseOutParams),
}

public enum VmResult has drop {
    SubGraph {
        nodes: vector<Node>,
        edges: vector<Edge>,
    },
    Hashes(vector<Hash32>),
    ScalarHash(Hash32),
    ScalarNumber(u64),
    None
}

public struct VM has drop {
    limit: Option<u64>,
}

public fun execute(op: vector<Opcode>, graph: &mut Graph): VmResult {
    let mut current_nodes = vector::empty<Hash32>();
    
    let op_len = vector::length(&op);
    let mut i = 0;
    
    while (i < op_len) {
        let opcode_ref = vector::borrow(&op, i);
        
        match (opcode_ref) {
            Opcode::SetCurrentFromAllNodes => {
                // Set current nodes to all nodes in graph
                current_nodes = vector::empty<Hash32>();
                let nodes = graph::get_nodes(graph);
                let nodes_len = vector::length(nodes);
                let mut j = 0;
                while (j < nodes_len) {
                    let node = vector::borrow(nodes, j);
                    vector::push_back(&mut current_nodes, graph::get_node_id(node));
                    j = j + 1;
                };
            },
            Opcode::TraverseOut(params) => {
                // Traverse from current nodes to find connected nodes via edges
                let mut new_current_nodes = vector::empty<Hash32>();
                let current_len = vector::length(&current_nodes);
                let edges = graph::get_edges(graph);
                let edges_len = vector::length(edges);
                
                let mut i_curr = 0;
                while (i_curr < current_len) {
                    let from_node = *vector::borrow(&current_nodes, i_curr);
                    
                    let mut j_edge = 0;
                    while (j_edge < edges_len) {
                        let edge = vector::borrow(edges, j_edge);
                        let edge_label = graph::get_edge_label(edge);
                        let edge_from = graph::get_edge_from_node(edge);
                        let edge_to = graph::get_edge_to_node(edge);
                        
                        // Check if edge matches traverse params
                        let should_include = check_edge_match(&edge_label, params);
                        
                        if (edge_from == from_node && should_include) {
                            // Check if to_node is already in new_current_nodes
                            let mut found = false;
                            let new_len = vector::length(&new_current_nodes);
                            let mut k = 0;
                            while (k < new_len && !found) {
                                if (*vector::borrow(&new_current_nodes, k) == edge_to) {
                                    found = true;
                                };
                                k = k + 1;
                            };
                            if (!found) {
                                vector::push_back(&mut new_current_nodes, edge_to);
                            };
                        };
                        j_edge = j_edge + 1;
                    };
                    i_curr = i_curr + 1;
                };
                current_nodes = new_current_nodes;
            },
            _ => {},
        };
        i = i + 1;
    };
    
    // Return result based on current nodes
    let current_len = vector::length(&current_nodes);
    
    if (current_len == 1) {
        VmResult::ScalarHash(*vector::borrow(&current_nodes, 0))
    } else if (current_len > 0) {
        VmResult::Hashes(current_nodes)
    } else {
        VmResult::None
    }
}

fun check_edge_match(label: &EdgeLabel, params: &TraverseOutParams): bool {
    // Check AND labels (all must match)
    let and_len = vector::length(&params.where_edge_and_labels);
    if (and_len > 0) {
        let mut all_match = true;
        let mut i = 0;
        while (i < and_len && all_match) {
            let required_label = vector::borrow(&params.where_edge_and_labels, i);
            if (!graph::edge_labels_equal(label, required_label)) {
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
            if (graph::edge_labels_equal(label, or_label)) {
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
            if (graph::edge_labels_equal(label, not_label)) {
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
            if (graph::edge_labels_equal(label, not_or_label)) {
                return false
            };
            i = i + 1;
        };
    };
    
    true
}
