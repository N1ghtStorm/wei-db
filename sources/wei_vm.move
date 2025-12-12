module wei_db_contract::wei_vm;

use wei_db_contract::graph::Hash32;
use std::string::String;
use wei_db_contract::graph::Node;
use wei_db_contract::graph::Edge;

public struct TraverseOutParams has drop {
}

public enum Opcode has drop {
    SetCurrentFromAllNodes,
    CreateNode {
        node_id: Hash32,
        node_root: Hash32,
        data: vector<u8>,
    },
    CreateEdge {
        label: String,
        from_node: Hash32,
        to_node: Hash32,
    },
    SetLimit(u64),
    TraverseOut(),
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
    traverse_params: Option<TraverseOutParams>,
    limit: Option<u64>,
}

public fun execute(op: vector<Opcode>): VmResult {

    VmResult::None
}
