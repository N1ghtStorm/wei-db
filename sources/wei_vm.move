module wei_db_contract::wei_vm;

use wei_db_contract::graph::Hash32;
use std::string::String;
use wei_db_contract::graph::Node;
use wei_db_contract::graph::Edge;
use wei_db_contract::graph::EdgeLabel;

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
