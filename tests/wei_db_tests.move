#[test_only]
module wei_db_contract::counter_tests;

use wei_db_contract::counter::{Self};
use sui::test_scenario::{Self, Scenario};
use sui::tx_context;
use sui::transfer;

const TEST_ADMIN: address = @0xA11CE;