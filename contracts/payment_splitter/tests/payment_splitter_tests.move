
#[test_only]
module payment_splitter::payment_splitter_tests; 

use payment_splitter::payment_splitter::{Self as ps, PaymentSplitter, Owner};
use iota::test_scenario::{Self as ts, Scenario};
use iota::iota::IOTA;
use iota::coin;
use iota::vec_map;

const EBalanceNotEmpty: u64 = 3;

const OWNER: address = @0xCAFE;
const USER1: address = @0xACFE;
const USER2: address = @0xCFAE;
const USER3: address = @0xCEFA;
const USER4: address = @0xFACE;
const USER5: address = @0xEFAC;

fun setup(): Scenario{
    let mut scenario = ts::begin(OWNER);
    let ctx = scenario.ctx();
    ps::init_test(ctx);
    scenario
}

fun initialize_test(shareholders: vector<address>, shares: vector<u64>, mut scenario: Scenario): Scenario{
    scenario.next_tx(OWNER);
    let owner = scenario.take_shared<Owner>();
    let ctx = scenario.ctx();
    ps::initialize<IOTA>(shareholders, shares, owner, ctx);
    scenario
}

fun receive_test(value: u64, mut scenario: Scenario): Scenario{
    scenario.next_tx(OWNER);
    let mut payment_splitter = scenario.take_shared<PaymentSplitter<IOTA>>();
    let ctx = scenario.ctx();
    let coin = coin::mint_for_testing<IOTA>(value, ctx);
    ps::receive(coin, &mut payment_splitter);
    ts::return_shared(payment_splitter);
    scenario
}

fun release_test(scenario: &mut Scenario) {
    scenario.next_tx(OWNER);
    let mut payment_splitter = scenario.take_shared<PaymentSplitter<IOTA>>();
    ps::release(&mut payment_splitter);
    ts::return_shared(payment_splitter);
}

fun take_amount_test(sender: address, mut scenario: Scenario): Scenario {
    scenario.next_tx(sender);
    let mut payment_splitter = scenario.take_shared<PaymentSplitter<IOTA>>();
    let ctx = scenario.ctx();
    ps::take_amount(&mut payment_splitter, ctx);
    ts::return_shared(payment_splitter);
    scenario
}

#[test]
public fun intended_way(){
    let scenario = setup();
    let scenario = initialize_test(vector[USER1, USER2, USER3, USER4], vector[1, 1, 1, 1], scenario);
    let mut scenario = receive_test(100, scenario);
    release_test(&mut scenario);
    let scenario = take_amount_test(USER1, scenario);
    let scenario = take_amount_test(USER2, scenario);
    let scenario = take_amount_test(USER3, scenario);
    let mut scenario = take_amount_test(USER4, scenario);
    scenario.next_tx(OWNER);
    let payment_splitter = scenario.take_shared<PaymentSplitter<IOTA>>();
    assert!(payment_splitter.balance().value() == 0, EBalanceNotEmpty);
    ts::return_shared(payment_splitter);
    scenario.end();
}

#[test, expected_failure(abort_code = ps::EWrongSharesDistribution)]
public fun wrong_initialzie_vectors(){
    let scenario = setup();
    let scenario = initialize_test(vector[USER1, USER2, USER3, USER4], vector[1, 1, 1], scenario);
    scenario.end();
}

#[test, expected_failure(abort_code = ps::EBalanceEmpty)]
public fun release_with_empty_balance(){
    let scenario = setup();
    let mut scenario = initialize_test(vector[USER1, USER2, USER3, USER4], vector[1, 1, 1, 1], scenario);
    release_test(&mut scenario);
    scenario.end();
}

#[test, expected_failure(abort_code = vec_map::EKeyDoesNotExist)]
public fun not_receiver_take_amount(){
    let scenario = setup();
    let scenario = initialize_test(vector[USER1, USER2, USER3, USER4], vector[1, 1, 1, 1], scenario);
    let mut scenario = receive_test(100, scenario);
    release_test(&mut scenario);
    let scenario = take_amount_test(USER5, scenario);
    scenario.end();
}
