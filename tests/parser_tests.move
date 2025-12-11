#[test_only]
module wei_db_contract::parser_tests;

use wei_db_contract::wei_parser;
use std::string;

#[test]
fun test_parse_query_match_return_limit() {
    let query_str = string::utf8(b"MATCH (n)-[:Follows]->(m) RETURN m LIMIT 10");
    let query = wei_parser::parse_query(query_str);
    
    assert!(option::is_some(&wei_parser::get_match_clause(&query)), 100);
    assert!(vector::length(&wei_parser::get_return_items(&wei_parser::get_return_clause(&query))) == 1, 101);
    assert!(option::is_some(&wei_parser::get_limit_clause(&query)), 102);
    
    let match_clause_opt = wei_parser::get_match_clause(&query);
    if (option::is_some(&match_clause_opt)) {
        let match_clause = *option::borrow(&match_clause_opt);
        assert!(vector::length(&wei_parser::get_patterns(&match_clause)) == 1, 103);
    };
    
    let limit_clause_opt = wei_parser::get_limit_clause(&query);
    if (option::is_some(&limit_clause_opt)) {
        let limit_clause = *option::borrow(&limit_clause_opt);
        assert!(wei_parser::get_limit(&limit_clause) == 10, 104);
    };
}

#[test]
fun test_parse_query_match_return() {
    let query_str = string::utf8(b"MATCH (n)-[:Follows]->(m) RETURN m");
    let query = wei_parser::parse_query(query_str);
    
    assert!(option::is_some(&wei_parser::get_match_clause(&query)), 105);
    assert!(vector::length(&wei_parser::get_return_items(&wei_parser::get_return_clause(&query))) == 1, 106);
    assert!(option::is_none(&wei_parser::get_limit_clause(&query)), 107);
}

#[test]
#[expected_failure(abort_code = wei_parser::E_QUERY_MUST_START_WITH_MATCH)]
fun test_parse_query_return_only_fails() {
    let query_str = string::utf8(b"RETURN n");
    let _query = wei_parser::parse_query(query_str);
}

#[test]
#[expected_failure(abort_code = wei_parser::E_QUERY_MUST_START_WITH_MATCH)]
fun test_parse_query_with_limit_fails() {
    let query_str = string::utf8(b"RETURN m LIMIT 20");
    let _query = wei_parser::parse_query(query_str);
}

#[test]
#[expected_failure(abort_code = wei_parser::E_QUERY_MUST_START_WITH_MATCH)]
fun test_parse_query_empty_string_fails() {
    let query_str = string::utf8(b"");
    let _query = wei_parser::parse_query(query_str);
}

#[test]
#[expected_failure(abort_code = wei_parser::E_QUERY_MUST_START_WITH_MATCH)]
fun test_parse_query_not_starting_with_match_fails() {
    let query_str = string::utf8(b"SELECT * FROM table");
    let _query = wei_parser::parse_query(query_str);
}

#[test]
fun test_parse_query_full_pattern() {
    let query_str = string::utf8(b"MATCH (n)-[:Follows]->(m) RETURN m LIMIT 10");
    let query = wei_parser::parse_query(query_str);
    
    let match_clause_opt = wei_parser::get_match_clause(&query);
    if (option::is_some(&match_clause_opt)) {
        let match_clause = *option::borrow(&match_clause_opt);
        let patterns = wei_parser::get_patterns(&match_clause);
        let pattern = *vector::borrow(&patterns, 0);
        
        let nodes = wei_parser::get_nodes(&pattern);
        let edges = wei_parser::get_edges(&pattern);
        
        assert!(vector::length(&nodes) == 2, 115);
        assert!(vector::length(&edges) == 1, 116);
        
        let node_n = vector::borrow(&nodes, 0);
        let node_m = vector::borrow(&nodes, 1);
        
        let var_n_opt = wei_parser::get_variable(node_n);
        let var_m_opt = wei_parser::get_variable(node_m);
        
        if (option::is_some(&var_n_opt)) {
            let var_n = *option::borrow(&var_n_opt);
            assert!(string::as_bytes(&var_n) == b"n", 117);
        };
        
        if (option::is_some(&var_m_opt)) {
            let var_m = *option::borrow(&var_m_opt);
            assert!(string::as_bytes(&var_m) == b"m", 118);
        };
        
        let edge = vector::borrow(&edges, 0);
        assert!(vector::length(&wei_parser::get_edge_labels(edge)) == 1, 119);
    };
}
