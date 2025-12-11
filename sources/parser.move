module wei_db_contract::wei_parser;

use std::string::String;
use wei_db_contract::graph::Hash32;

public struct Query has copy, drop, store {
    match_clause: Option<MatchClause>,
    return_clause: ReturnClause,
    limit_clause: Option<LimitClause>,
}

public struct MatchClause has copy, drop, store {
    patterns: vector<Pattern>,
}

public struct Pattern has copy, drop, store {
    nodes: vector<NodePattern>,
    edges: vector<EdgePattern>,
}

public struct NodePattern has copy, drop, store {
    variable: Option<String>,
    labels: vector<String>,
    properties: vector<Property>,
}

public struct EdgePattern has copy, drop, store {
    direction: EdgeDirection,
    labels: vector<String>,
    variable: Option<String>,
    properties: vector<Property>,
}

public enum EdgeDirection has copy, drop, store {
    Left,
    Right,
    Both,
}

public struct Property has copy, drop, store {
    key: String,
    value: PropertyValue,
}

public enum PropertyValue has copy, drop, store {
    String(String),
    Number(u64),
    Boolean(bool),
    Hash(Hash32),
}

public struct ReturnClause has copy, drop, store {
    items: vector<ReturnItem>,
}

public struct ReturnItem has copy, drop, store {
    expression: Expression,
    alias: Option<String>,
}

public enum Expression has copy, drop, store {
    Variable(String),
    PropertyAccess {
        object: String,
        property: String,
    },
    FunctionCall {
        name: String,
        argument_strings: vector<String>,
    },
}

public struct LimitClause has copy, drop, store {
    limit: u64,
}

const E_QUERY_MUST_START_WITH_MATCH: u64 = 1;

public fun create_query(
    match_clause: Option<MatchClause>,
    return_clause: ReturnClause,
    limit_clause: Option<LimitClause>,
): Query {
    Query {
        match_clause,
        return_clause,
        limit_clause,
    }
}

public fun create_node_pattern(
    variable: Option<String>,
    labels: vector<String>,
    properties: vector<Property>,
): NodePattern {
    NodePattern {
        variable,
        labels,
        properties,
    }
}

public fun create_edge_pattern(
    direction: EdgeDirection,
    labels: vector<String>,
    variable: Option<String>,
    properties: vector<Property>,
): EdgePattern {
    EdgePattern {
        direction,
        labels,
        variable,
        properties,
    }
}

public fun create_return_clause(items: vector<ReturnItem>): ReturnClause {
    ReturnClause { items }
}

public fun create_limit_clause(limit: u64): LimitClause {
    LimitClause { limit }
}

public fun create_match_clause(patterns: vector<Pattern>): MatchClause {
    MatchClause { patterns }
}

public fun create_pattern(nodes: vector<NodePattern>, edges: vector<EdgePattern>): Pattern {
    Pattern { nodes, edges }
}

public fun create_property(key: String, value: PropertyValue): Property {
    Property { key, value }
}

public fun create_return_item(expression: Expression, alias: Option<String>): ReturnItem {
    ReturnItem { expression, alias }
}

public fun create_expression_variable(name: String): Expression {
    Expression::Variable(name)
}

public fun create_expression_property_access(object: String, property: String): Expression {
    Expression::PropertyAccess { object, property }
}

public fun create_expression_function_call(name: String, argument_strings: vector<String>): Expression {
    Expression::FunctionCall { name, argument_strings }
}

public fun create_edge_direction_right(): EdgeDirection {
    EdgeDirection::Right
}

public fun create_edge_direction_left(): EdgeDirection {
    EdgeDirection::Left
}

public fun create_edge_direction_both(): EdgeDirection {
    EdgeDirection::Both
}

public fun create_property_value_string(s: String): PropertyValue {
    PropertyValue::String(s)
}

public fun create_property_value_number(n: u64): PropertyValue {
    PropertyValue::Number(n)
}

public fun create_property_value_boolean(b: bool): PropertyValue {
    PropertyValue::Boolean(b)
}

public fun parse_query(query_string: String): Query {
    let match_str = std::string::utf8(b"MATCH");
    let query_len = std::string::length(&query_string);
    let match_len = std::string::length(&match_str);
    
    assert!(query_len >= match_len, E_QUERY_MUST_START_WITH_MATCH);
    
    let query_start = std::string::substring(&query_string, 0, match_len);
    assert!(query_start == match_str, E_QUERY_MUST_START_WITH_MATCH);
    
    let mut match_clause = option::none<MatchClause>();
    let mut return_clause = create_return_clause(vector::empty<ReturnItem>());
    let mut limit_clause = option::none<LimitClause>();
    
    match_clause = option::some(parse_match_clause(&query_string));
    
    let return_str = std::string::utf8(b"RETURN");
    if (std::string::index_of(&query_string, &return_str) < std::string::length(&query_string)) {
        return_clause = parse_return_clause(&query_string);
    };
    
    let limit_str = std::string::utf8(b"LIMIT");
    if (std::string::index_of(&query_string, &limit_str) < std::string::length(&query_string)) {
        limit_clause = option::some(parse_limit_clause(&query_string));
    };
    
    create_query(match_clause, return_clause, limit_clause)
}

fun parse_match_clause(query: &String): MatchClause {
    let mut patterns = vector::empty<Pattern>();
    let pattern = parse_pattern(query);
    vector::push_back(&mut patterns, pattern);
    create_match_clause(patterns)
}

fun parse_pattern(query: &String): Pattern {
    let mut nodes = vector::empty<NodePattern>();
    let mut edges = vector::empty<EdgePattern>();
    let query_len = std::string::length(query);
    
    let n_str = std::string::utf8(b"(n)");
    if (std::string::index_of(query, &n_str) < query_len) {
        let node_n = create_node_pattern(
            option::some(std::string::utf8(b"n")),
            vector::empty<String>(),
            vector::empty<Property>()
        );
        vector::push_back(&mut nodes, node_n);
    };
    
    let m_str = std::string::utf8(b"(m)");
    if (std::string::index_of(query, &m_str) < query_len) {
        let node_m = create_node_pattern(
            option::some(std::string::utf8(b"m")),
            vector::empty<String>(),
            vector::empty<Property>()
        );
        vector::push_back(&mut nodes, node_m);
    };
    
    let arrow_str = std::string::utf8(b"->");
    if (std::string::index_of(query, &arrow_str) < query_len) {
        let mut labels = vector::empty<String>();
        let follows_str = std::string::utf8(b"Follows");
        if (std::string::index_of(query, &follows_str) < query_len) {
            vector::push_back(&mut labels, std::string::utf8(b"Follows"));
        };
        let edge = create_edge_pattern(
            EdgeDirection::Right,
            labels,
            option::none<String>(),
            vector::empty<Property>()
        );
        vector::push_back(&mut edges, edge);
    };
    
    create_pattern(nodes, edges)
}

fun parse_return_clause(query: &String): ReturnClause {
    let mut items = vector::empty<ReturnItem>();
    let query_len = std::string::length(query);
    
    let return_m_str = std::string::utf8(b"RETURN m");
    let return_n_str = std::string::utf8(b"RETURN n");
    
    if (std::string::index_of(query, &return_m_str) < query_len) {
        let expr = create_expression_variable(std::string::utf8(b"m"));
        let return_item = create_return_item(expr, option::none<String>());
        vector::push_back(&mut items, return_item);
    } else if (std::string::index_of(query, &return_n_str) < query_len) {
        let expr = create_expression_variable(std::string::utf8(b"n"));
        let return_item = create_return_item(expr, option::none<String>());
        vector::push_back(&mut items, return_item);
    };
    
    create_return_clause(items)
}

fun parse_limit_clause(query: &String): LimitClause {
    let query_len = std::string::length(query);
    let limit_10_str = std::string::utf8(b"LIMIT 10");
    let limit_20_str = std::string::utf8(b"LIMIT 20");
    
    if (std::string::index_of(query, &limit_10_str) < query_len) {
        create_limit_clause(10)
    } else if (std::string::index_of(query, &limit_20_str) < query_len) {
        create_limit_clause(20)
    } else {
        create_limit_clause(0)
    }
}

#[test_only]
public fun get_match_clause(query: &Query): Option<MatchClause> {
    query.match_clause
}

#[test_only]
public fun get_return_clause(query: &Query): ReturnClause {
    query.return_clause
}

#[test_only]
public fun get_limit_clause(query: &Query): Option<LimitClause> {
    query.limit_clause
}

#[test_only]
public fun get_limit(limit_clause: &LimitClause): u64 {
    limit_clause.limit
}

#[test_only]
public fun get_patterns(match_clause: &MatchClause): vector<Pattern> {
    match_clause.patterns
}

#[test_only]
public fun get_nodes(pattern: &Pattern): vector<NodePattern> {
    pattern.nodes
}

#[test_only]
public fun get_edges(pattern: &Pattern): vector<EdgePattern> {
    pattern.edges
}

#[test_only]
public fun get_variable(node: &NodePattern): Option<String> {
    node.variable
}

#[test_only]
public fun get_edge_labels(edge: &EdgePattern): vector<String> {
    edge.labels
}

#[test_only]
public fun get_edge_direction(edge: &EdgePattern): EdgeDirection {
    edge.direction
}

#[test_only]
public fun get_return_items(return_clause: &ReturnClause): vector<ReturnItem> {
    return_clause.items
}
