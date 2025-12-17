module wei_db_contract::wei_vm;

use wei_db_contract::graph::{Self, Hash32, Node, Edge, Graph, TraverseOutParams};

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
    Nodes(vector<Node>),
    Hashes(vector<Hash32>),
    ScalarHash(Hash32),
    ScalarNumber(u64),
    None
}

public struct VM has drop {
    limit: Option<u64>,
}

public fun execute(op: vector<Opcode>, graph: &mut Graph): VmResult {
    let mut current_node_hashes = vector::empty<Hash32>();
    
    let op_len = vector::length(&op);
    let mut i = 0;
    
    while (i < op_len) {
        let opcode_ref = vector::borrow(&op, i);
        
        match (opcode_ref) {
            Opcode::SetCurrentFromAllNodes => {
                current_node_hashes = vector::empty<Hash32>();
                let nodes = graph::get_nodes(graph);
                let nodes_len = vector::length(nodes);
                let mut j = 0;
                while (j < nodes_len) {
                    let node = vector::borrow(nodes, j);
                    vector::push_back(&mut current_node_hashes, graph::get_node_id(node));
                    j = j + 1;
                };
            },
            Opcode::TraverseOut(params) => {
                let result_nodes = graph::traverse_out(graph, current_node_hashes, params);
                // Convert nodes back to hashes for next iteration
                current_node_hashes = vector::empty<Hash32>();
                let result_len = vector::length(&result_nodes);
                let mut k = 0;
                while (k < result_len) {
                    let node = vector::borrow(&result_nodes, k);
                    vector::push_back(&mut current_node_hashes, graph::get_node_id(node));
                    k = k + 1;
                };
            },
            _ => {},
        };
        i = i + 1;
    };
    
    // Convert hashes to full nodes
    let mut result_nodes = vector::empty<Node>();
    let nodes = graph::get_nodes(graph);
    let nodes_len = vector::length(nodes);
    let current_len = vector::length(&current_node_hashes);
    
    let mut i = 0;
    while (i < current_len) {
        let target_hash = *vector::borrow(&current_node_hashes, i);
        let mut j = 0;
        while (j < nodes_len) {
            let node = vector::borrow(nodes, j);
            if (graph::get_node_id(node) == target_hash) {
                vector::push_back(&mut result_nodes, *node);
                break
            };
            j = j + 1;
        };
        i = i + 1;
    };
    
    let result_len = vector::length(&result_nodes);
    
    if (result_len > 0) {
        VmResult::Nodes(result_nodes)
    } else {
        VmResult::None
    }
}
