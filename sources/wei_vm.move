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
                current_nodes = graph::traverse_out(graph, current_nodes, params);
            },
            _ => {},
        };
        i = i + 1;
    };
    
    let current_len = vector::length(&current_nodes);
    
    if (current_len == 1) {
        VmResult::ScalarHash(*vector::borrow(&current_nodes, 0))
    } else if (current_len > 0) {
        VmResult::Hashes(current_nodes)
    } else {
        VmResult::None
    }
}
