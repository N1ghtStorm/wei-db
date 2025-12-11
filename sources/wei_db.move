module wei_db_contract::counter;

use wei_db_contract::graph;

fun init(ctx: &mut TxContext) {
    let graph = graph::create_empty_graph(ctx);
    transfer::public_transfer(graph, tx_context::sender(ctx));
}

entry fun create_graph(ctx: &mut TxContext) {
    let graph = graph::create_empty_graph(ctx);
    transfer::public_transfer(graph, tx_context::sender(ctx));
}
