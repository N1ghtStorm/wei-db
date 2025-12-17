#[test_only]
module wei_db_contract::graph_tests;

use wei_db_contract::graph::{Self, Graph, Hash32, Node, Edge, EdgeLabel, TraverseOutParams};
use sui::test_scenario::{Self, Scenario};
use sui::tx_context;

const TEST_ADMIN: address = @0xA11CE;

fun create_test_node(node_id: Hash32, node_root: Hash32): Node {
    graph::create_node(node_id, node_root, vector::empty<u8>())
}

fun create_test_edge(edge_id: Hash32, label: EdgeLabel, from_node: Hash32, to_node: Hash32): Edge {
    graph::create_edge(edge_id, label, from_node, to_node)
}

fun create_empty_params(): TraverseOutParams {
    graph::create_traverse_out_params(
        vector::empty<EdgeLabel>(),
        vector::empty<EdgeLabel>(),
        vector::empty<EdgeLabel>(),
        vector::empty<EdgeLabel>(),
    )
}

#[test]
fun test_traverse_out_simple() {
    let mut scenario = test_scenario::begin(TEST_ADMIN);
    let ctx = test_scenario::ctx(&mut scenario);
    
    // Create graph with nodes and edges
    let mut graph = graph::create_empty_graph(ctx);
    
    let node1_id = graph::create_hash32(@0x1);
    let node1 = create_test_node(node1_id, graph::create_hash32(@0x10));
    
    let node2_id = graph::create_hash32(@0x2);
    let node2 = create_test_node(node2_id, graph::create_hash32(@0x20));
    
    // Add nodes to graph
    graph::add_node(&mut graph, node1);
    graph::add_node(&mut graph, node2);
    
    // Create edge from node1 to node2
    let edge1 = create_test_edge(graph::create_hash32(@0x100), graph::create_edge_label_number(1), node1_id, node2_id);
    graph::add_edge(&mut graph, edge1);
    
    // Traverse from node1
    let mut from_nodes = vector::empty<Hash32>();
    vector::push_back(&mut from_nodes, node1_id);
    let params = create_empty_params();
    
    let result = graph::traverse_out(&graph, from_nodes, &params);
    
    // Should return node2
    assert!(vector::length(&result) == 1, 1);
    let result_node = *vector::borrow(&result, 0);
    assert!(graph::get_node_id(&result_node) == node2_id, 2);
    
    test_scenario::end(scenario);
}

#[test]
fun test_traverse_out_with_and_filter() {
    let mut scenario = test_scenario::begin(TEST_ADMIN);
    let ctx = test_scenario::ctx(&mut scenario);
    
    let mut graph = graph::create_empty_graph(ctx);
    
    let node1_id = graph::create_hash32(@0x1);
    let node1 = create_test_node(node1_id, graph::create_hash32(@0x10));
    let node2_id = graph::create_hash32(@0x2);
    let node2 = create_test_node(node2_id, graph::create_hash32(@0x20));
    let node3_id = graph::create_hash32(@0x3);
    let node3 = create_test_node(node3_id, graph::create_hash32(@0x30));
    
    graph::add_node(&mut graph, node1);
    graph::add_node(&mut graph, node2);
    graph::add_node(&mut graph, node3);
    
    // Create edges: node1 -> node2 (label 1), node1 -> node3 (label 2)
    let edge1 = create_test_edge(graph::create_hash32(@0x100), graph::create_edge_label_number(1), node1_id, node2_id);
    let edge2 = create_test_edge(graph::create_hash32(@0x101), graph::create_edge_label_number(2), node1_id, node3_id);
    
    graph::add_edge(&mut graph, edge1);
    graph::add_edge(&mut graph, edge2);
    
    // Traverse with AND filter for label 1
    let mut from_nodes = vector::empty<Hash32>();
    vector::push_back(&mut from_nodes, node1_id);
    
    let mut and_labels = vector::empty<EdgeLabel>();
    vector::push_back(&mut and_labels, graph::create_edge_label_number(1));
    let params = graph::create_traverse_out_params(
        and_labels,
        vector::empty<EdgeLabel>(),
        vector::empty<EdgeLabel>(),
        vector::empty<EdgeLabel>(),
    );
    
    let result = graph::traverse_out(&graph, from_nodes, &params);
    
    // Should return only node2 (edge with label 1)
    assert!(vector::length(&result) == 1, 3);
    let result_node = *vector::borrow(&result, 0);
    assert!(graph::get_node_id(&result_node) == node2_id, 4);
    
    test_scenario::end(scenario);
}

#[test]
fun test_traverse_out_with_or_filter() {
    let mut scenario = test_scenario::begin(TEST_ADMIN);
    let ctx = test_scenario::ctx(&mut scenario);
    
    let mut graph = graph::create_empty_graph(ctx);
    
    let node1_id = graph::create_hash32(@0x1);
    let node1 = create_test_node(node1_id, graph::create_hash32(@0x10));
    let node2_id = graph::create_hash32(@0x2);
    let node2 = create_test_node(node2_id, graph::create_hash32(@0x20));
    let node3_id = graph::create_hash32(@0x3);
    let node3 = create_test_node(node3_id, graph::create_hash32(@0x30));
    
    graph::add_node(&mut graph, node1);
    graph::add_node(&mut graph, node2);
    graph::add_node(&mut graph, node3);
    
    // Create edges: node1 -> node2 (label 1), node1 -> node3 (label 2)
    let edge1 = create_test_edge(graph::create_hash32(@0x100), graph::create_edge_label_number(1), node1_id, node2_id);
    let edge2 = create_test_edge(graph::create_hash32(@0x101), graph::create_edge_label_number(2), node1_id, node3_id);
    
    graph::add_edge(&mut graph, edge1);
    graph::add_edge(&mut graph, edge2);
    
    // Traverse with OR filter for label 1 or 2
    let mut from_nodes = vector::empty<Hash32>();
    vector::push_back(&mut from_nodes, node1_id);
    
    let mut or_labels = vector::empty<EdgeLabel>();
    vector::push_back(&mut or_labels, graph::create_edge_label_number(1));
    vector::push_back(&mut or_labels, graph::create_edge_label_number(2));
    let params = graph::create_traverse_out_params(
        vector::empty<EdgeLabel>(),
        or_labels,
        vector::empty<EdgeLabel>(),
        vector::empty<EdgeLabel>(),
    );
    
    let result = graph::traverse_out(&graph, from_nodes, &params);
    
    // Should return both node2 and node3
    assert!(vector::length(&result) == 2, 5);
    
    let mut found_node2 = false;
    let mut found_node3 = false;
    let len = vector::length(&result);
    let mut i = 0;
    while (i < len) {
        let node = vector::borrow(&result, i);
        let node_id = graph::get_node_id(node);
        if (node_id == node2_id) {
            found_node2 = true;
        };
        if (node_id == node3_id) {
            found_node3 = true;
        };
        i = i + 1;
    };
    assert!(found_node2, 6);
    assert!(found_node3, 7);
    
    test_scenario::end(scenario);
}

#[test]
fun test_traverse_out_with_not_filter() {
    let mut scenario = test_scenario::begin(TEST_ADMIN);
    let ctx = test_scenario::ctx(&mut scenario);
    
    let mut graph = graph::create_empty_graph(ctx);
    
    let node1_id = graph::create_hash32(@0x1);
    let node1 = create_test_node(node1_id, graph::create_hash32(@0x10));
    let node2_id = graph::create_hash32(@0x2);
    let node2 = create_test_node(node2_id, graph::create_hash32(@0x20));
    let node3_id = graph::create_hash32(@0x3);
    let node3 = create_test_node(node3_id, graph::create_hash32(@0x30));
    
    graph::add_node(&mut graph, node1);
    graph::add_node(&mut graph, node2);
    graph::add_node(&mut graph, node3);
    
    // Create edges: node1 -> node2 (label 1), node1 -> node3 (label 2)
    let edge1 = create_test_edge(graph::create_hash32(@0x100), graph::create_edge_label_number(1), node1_id, node2_id);
    let edge2 = create_test_edge(graph::create_hash32(@0x101), graph::create_edge_label_number(2), node1_id, node3_id);
    
    graph::add_edge(&mut graph, edge1);
    graph::add_edge(&mut graph, edge2);
    
    // Traverse with NOT filter for label 1 (should exclude edge with label 1)
    let mut from_nodes = vector::empty<Hash32>();
    vector::push_back(&mut from_nodes, node1_id);
    
    let mut not_labels = vector::empty<EdgeLabel>();
    vector::push_back(&mut not_labels, graph::create_edge_label_number(1));
    let params = graph::create_traverse_out_params(
        vector::empty<EdgeLabel>(),
        vector::empty<EdgeLabel>(),
        not_labels,
        vector::empty<EdgeLabel>(),
    );
    
    let result = graph::traverse_out(&graph, from_nodes, &params);
    
    // Should return only node3 (edge with label 2, label 1 excluded)
    assert!(vector::length(&result) == 1, 8);
    let result_node = *vector::borrow(&result, 0);
    assert!(graph::get_node_id(&result_node) == node3_id, 9);
    
    test_scenario::end(scenario);
}

#[test]
fun test_traverse_out_no_edges() {
    let mut scenario = test_scenario::begin(TEST_ADMIN);
    let ctx = test_scenario::ctx(&mut scenario);
    
    let mut graph = graph::create_empty_graph(ctx);
    
    let node1_id = graph::create_hash32(@0x1);
    let node1 = create_test_node(node1_id, graph::create_hash32(@0x10));
    
    graph::add_node(&mut graph, node1);
    // No edges added
    
    let mut from_nodes = vector::empty<Hash32>();
    vector::push_back(&mut from_nodes, node1_id);
    let params = create_empty_params();
    
    let result = graph::traverse_out(&graph, from_nodes, &params);
    
    // Should return empty (no edges from node1)
    assert!(vector::length(&result) == 0, 10);
    
    test_scenario::end(scenario);
}

#[test]
fun test_traverse_out_multiple_from_nodes() {
    let mut scenario = test_scenario::begin(TEST_ADMIN);
    let ctx = test_scenario::ctx(&mut scenario);
    
    let mut graph = graph::create_empty_graph(ctx);
    
    let node1_id = graph::create_hash32(@0x1);
    let node1 = create_test_node(node1_id, graph::create_hash32(@0x10));
    let node2_id = graph::create_hash32(@0x2);
    let node2 = create_test_node(node2_id, graph::create_hash32(@0x20));
    let node3_id = graph::create_hash32(@0x3);
    let node3 = create_test_node(node3_id, graph::create_hash32(@0x30));
    let node4_id = graph::create_hash32(@0x4);
    let node4 = create_test_node(node4_id, graph::create_hash32(@0x40));
    
    graph::add_node(&mut graph, node1);
    graph::add_node(&mut graph, node2);
    graph::add_node(&mut graph, node3);
    graph::add_node(&mut graph, node4);
    
    // Create edges: node1 -> node3, node2 -> node4
    let edge1 = create_test_edge(graph::create_hash32(@0x100), graph::create_edge_label_number(1), node1_id, node3_id);
    let edge2 = create_test_edge(graph::create_hash32(@0x101), graph::create_edge_label_number(1), node2_id, node4_id);
    
    graph::add_edge(&mut graph, edge1);
    graph::add_edge(&mut graph, edge2);
    
    // Traverse from both node1 and node2
    let mut from_nodes = vector::empty<Hash32>();
    vector::push_back(&mut from_nodes, node1_id);
    vector::push_back(&mut from_nodes, node2_id);
    let params = create_empty_params();
    
    let result = graph::traverse_out(&graph, from_nodes, &params);
    
    // Should return both node3 and node4
    assert!(vector::length(&result) == 2, 11);
    
    let mut found_node3 = false;
    let mut found_node4 = false;
    let len = vector::length(&result);
    let mut i = 0;
    while (i < len) {
        let node = vector::borrow(&result, i);
        let node_id = graph::get_node_id(node);
        if (node_id == node3_id) {
            found_node3 = true;
        };
        if (node_id == node4_id) {
            found_node4 = true;
        };
        i = i + 1;
    };
    assert!(found_node3, 12);
    assert!(found_node4, 13);
    
    test_scenario::end(scenario);
}

#[test]
fun test_traverse_out_duplicate_prevention() {
    let mut scenario = test_scenario::begin(TEST_ADMIN);
    let ctx = test_scenario::ctx(&mut scenario);
    
    let mut graph = graph::create_empty_graph(ctx);
    
    let node1_id = graph::create_hash32(@0x1);
    let node1 = create_test_node(node1_id, graph::create_hash32(@0x10));
    let node2_id = graph::create_hash32(@0x2);
    let node2 = create_test_node(node2_id, graph::create_hash32(@0x20));
    
    graph::add_node(&mut graph, node1);
    graph::add_node(&mut graph, node2);
    
    // Create multiple edges from node1 to node2 (different labels)
    let edge1 = create_test_edge(graph::create_hash32(@0x100), graph::create_edge_label_number(1), node1_id, node2_id);
    let edge2 = create_test_edge(graph::create_hash32(@0x101), graph::create_edge_label_number(2), node1_id, node2_id);
    
    graph::add_edge(&mut graph, edge1);
    graph::add_edge(&mut graph, edge2);
    
    let mut from_nodes = vector::empty<Hash32>();
    vector::push_back(&mut from_nodes, node1_id);
    let params = create_empty_params();
    
    let result = graph::traverse_out(&graph, from_nodes, &params);
    
    // Should return node2 only once (duplicate prevention)
    assert!(vector::length(&result) == 1, 14);
    let result_node = *vector::borrow(&result, 0);
    assert!(graph::get_node_id(&result_node) == node2_id, 15);
    
    test_scenario::end(scenario);
}

#[test]
fun test_traverse_out_no_matching_edges() {
    let mut scenario = test_scenario::begin(TEST_ADMIN);
    let ctx = test_scenario::ctx(&mut scenario);
    
    let mut graph = graph::create_empty_graph(ctx);
    
    let node1_id = graph::create_hash32(@0x1);
    let node1 = create_test_node(node1_id, graph::create_hash32(@0x10));
    let node2_id = graph::create_hash32(@0x2);
    let node2 = create_test_node(node2_id, graph::create_hash32(@0x20));
    let node3_id = graph::create_hash32(@0x3);
    let node3 = create_test_node(node3_id, graph::create_hash32(@0x30));
    
    graph::add_node(&mut graph, node1);
    graph::add_node(&mut graph, node2);
    graph::add_node(&mut graph, node3);
    
    // Create edge from node2 to node3 (not from node1)
    let edge1 = create_test_edge(graph::create_hash32(@0x100), graph::create_edge_label_number(1), node2_id, node3_id);
    graph::add_edge(&mut graph, edge1);
    
    // Traverse from node1 (no edges from node1)
    let mut from_nodes = vector::empty<Hash32>();
    vector::push_back(&mut from_nodes, node1_id);
    let params = create_empty_params();
    
    let result = graph::traverse_out(&graph, from_nodes, &params);
    
    // Should return empty
    assert!(vector::length(&result) == 0, 16);
    
    test_scenario::end(scenario);
}

