module wei_db_contract::graph;

use std::string::String;

public struct Hash32(address)

public struct Graph {
    uid: UID,
    nodes: vector<Node>,
    edges: vector<Edge>,
}

public fun validate_graph(graph: &Graph): bool {
    true
}

public struct Node {
    node_id: Hash32,
    node_root: Hash32,
    node_data: vector<u8>,
}

public struct Edge {
    // We use aliases
    label: String,
    from_node: Hash32,
    to_node: Hash32,
}