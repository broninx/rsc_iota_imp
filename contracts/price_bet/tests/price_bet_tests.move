
#[test_only]
module price_bet::price_bet_tests;

use price_bet::price_bet::{Self as pb, PriceBet};
use price_bet::oracle::{Self, Oracle};
use iota::test_scenario::{Self as ts, Scenario};
use iota::coin;
use iota::iota::IOTA;
use iota::clock::{Self, Clock};

const OWNER: address = @0xCAFE;
const ORACLE: address = @0xFACE;
const USER: address = @0xCEFA;

fun setup(): Scenario {
    let mut scenario = ts::begin(OWNER);
    let ctx = scenario.ctx();
    oracle::createOracle( ORACLE, 10, ctx);
    scenario
}

fun initialize_test(exchange_rate: u64, sender: address, mut scenario: Scenario): Scenario {
    scenario.next_tx(sender);
    let oracle = scenario.take_shared<Oracle>();
    let ctx = scenario.ctx();
    let initial_pot = coin::mint_for_testing(1000, ctx);
    pb::initialize(initial_pot, &oracle, 5, exchange_rate, ctx);
    ts::return_shared(oracle);
    scenario
}

fun join_test(value: u64, sender: address, clock: &Clock, mut scenario: Scenario): Scenario {
    scenario.next_tx(sender);
    let mut pb = scenario.take_shared<PriceBet>();
    let ctx = scenario.ctx();
    let bet = coin::mint_for_testing<IOTA>(value, ctx);
    pb::join(bet, &mut pb, clock, ctx);
    ts::return_shared(pb);
    scenario
}

fun win_test(sender: address, clock: &Clock, mut scenario: Scenario) {
    scenario.next_tx(sender);
    let pb = scenario.take_shared<PriceBet>();
    let oracle = scenario.take_shared<Oracle>();
    let ctx = scenario.ctx();
    pb::win(&oracle, pb, clock, ctx);
    ts::return_shared(oracle);
    scenario.end();
}

fun timeout_test(clock: &Clock, mut scenario: Scenario) {
    scenario.next_tx(OWNER);
    let pb = scenario.take_shared<PriceBet>();
    let ctx = scenario.ctx();
    pb::timeout(pb, clock, ctx);
    scenario.end();
}

#[test]
public fun intended_way_winner_owner(){
    let mut scenario = setup();
    let ctx = scenario.ctx();
    let mut clock = clock::create_for_testing(ctx);
    let scenario = initialize_test(9, OWNER, scenario);
    let scenario = join_test(1000, USER, &clock, scenario);
    clock.increment_for_testing(300001);
    timeout_test(&clock, scenario);
    clock.destroy_for_testing();
}

#[test]
public fun intended_way_winner_player(){
    let mut scenario = setup();
    let ctx = scenario.ctx();
    let mut clock = clock::create_for_testing(ctx);
    let scenario = initialize_test(9, OWNER, scenario);
    let scenario = join_test(1000, USER, &clock, scenario);
    clock.increment_for_testing(6000);
    win_test(USER, &clock, scenario);
    clock.destroy_for_testing();
}

#[test, expected_failure(abort_code = pb::EWrongAmount)]
public fun wrong_amount_join(){
    let mut scenario = setup();
    let ctx = scenario.ctx();
    let clock = clock::create_for_testing(ctx);
    let scenario = initialize_test(9, OWNER, scenario);
    let scenario = join_test(999, USER, &clock, scenario);
    win_test(USER, &clock, scenario);
    clock.destroy_for_testing();
}

#[test, expected_failure(abort_code = pb::EWrongState)]
public fun wrong_state_win(){
    let mut scenario = setup();
    let ctx = scenario.ctx();
    let clock = clock::create_for_testing(ctx);
    let scenario = initialize_test(9, OWNER, scenario);
    win_test(USER, &clock, scenario);
    clock.destroy_for_testing();
}

#[test, expected_failure(abort_code = pb::EWrongTime)]
public fun wrong_time_win(){
    let mut scenario = setup();
    let ctx = scenario.ctx();
    let mut clock = clock::create_for_testing(ctx);
    let scenario = initialize_test(9, OWNER, scenario);
    let scenario = join_test(1000, USER, &clock, scenario);
    clock.increment_for_testing(300001);
    win_test(USER, &clock, scenario);
    clock.destroy_for_testing();
}

#[test, expected_failure(abort_code = pb::ENotWin)]
public fun call_win_without_win(){
    let mut scenario = setup();
    let ctx = scenario.ctx();
    let mut clock = clock::create_for_testing(ctx);
    let scenario = initialize_test(15, OWNER, scenario);
    let scenario = join_test(1000, USER, &clock, scenario);
    clock.increment_for_testing(50000);
    win_test(USER, &clock, scenario);
    clock.destroy_for_testing();
}

#[test, expected_failure(abort_code = pb::EWrongState)]
public fun wrong_state_timeout(){
    let mut scenario = setup();
    let ctx = scenario.ctx();
    let mut clock = clock::create_for_testing(ctx);
    let scenario = initialize_test(9, OWNER, scenario);
    clock.increment_for_testing(600000);
    timeout_test(&clock, scenario);
    clock.destroy_for_testing();
}

#[test, expected_failure(abort_code = pb::EWrongTime)]
public fun time_not_finished_timeout(){
    let mut scenario = setup();
    let ctx = scenario.ctx();
    let mut clock = clock::create_for_testing(ctx);
    let scenario = initialize_test(9, OWNER, scenario);
    let scenario = join_test(1000, USER, &clock, scenario);
    clock.increment_for_testing(50000);
    timeout_test(&clock, scenario);
    clock.destroy_for_testing();
}