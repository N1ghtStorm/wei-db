module wei_db_contract::counter;

use wei_db_contract::graph;
use wei_db_contract::wei_vm::{Self, VmResult};
use wei_db_contract::wei_parser;
use std::string::String;

fun init(ctx: &mut TxContext) {
    let graph = graph::create_empty_graph(ctx);
    transfer::public_transfer(graph, tx_context::sender(ctx));
}

entry fun create_graph(ctx: &mut TxContext) {
    let graph = graph::create_empty_graph(ctx);
    transfer::public_transfer(graph, tx_context::sender(ctx));
}

entry fun execute_query(cypher_query: String): VmResult {
    let _query = wei_parser::parse_query(cypher_query);
    wei_vm::execute(vector::empty<wei_vm::Opcode>())
}
