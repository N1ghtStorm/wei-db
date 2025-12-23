module wei_db_contract::wei_vm;

use wei_db_contract::graph::{Self, Hash32, Node, Edge, Graph, TraverseOutParams};

public enum Opcode has drop {
    SetVmresultType(VmOutputType),
    SetCurrentFromAllNodes,
    SetLimit(u64),
    TraverseOut(TraverseOutParams),
}

public enum VmUnit has drop {
    Node(Node),
    Edge(Edge),
    Hash(Hash32),
}

public enum VmOutputType has drop, copy {
    Units,
    Scalar,
    None,
}

public enum VmOutput has drop {
    Units(vector<VmUnit>),
    Scalar(VmUnit),
    None
}

public fun execute_read_only(op: vector<Opcode>, graph: &Graph): VmOutput {
    let mut current_node_hashes = vector::empty<Hash32>();

    let mut vm_result_type: VmOutputType = VmOutputType::None;
    let mut result_nodes = vector::empty<Node>();

    let op_len = vector::length(&op);
    let mut i = 0;
    
    while (i < op_len) {
        let opcode_ref = vector::borrow(&op, i);
        
        match (opcode_ref) {
            Opcode::SetVmresultType(result) => {
                vm_result_type = *result;
            },
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
                result_nodes = graph::traverse_out(graph, current_node_hashes, params);
            },
            _ => {},
        };
        i = i + 1;
    };
    
    match (vm_result_type) {
        VmOutputType::Units => {
            let units = result_nodes.map!(|x| VmUnit::Node(x));
            VmOutput::Units(units)
        },
        VmOutputType::Scalar => {
            VmOutput::None
        },
        VmOutputType::None => {
            VmOutput::None
        }
    }
}
