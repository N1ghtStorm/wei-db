module wei_db_contract::wei_vm;

use wei_db_contract::graph::Hash32;
use std::string::String;

public struct WeiVM {
}

public enum Opcode {
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