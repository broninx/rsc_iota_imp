
#[test_only]
module payment_splitter::payment_splitter_tests; 

use payment_splitter::payment_splitter::{Self as ps, PaymentSplitter, Owner};
use iota::test_scenario::{Self as ts, Scenario};
use iota::iota::IOTA;
use iota::coin;

const OWNER: address = @0xCAFE;
const USER1: address = @0xACFE;
const USER2: address = @0xCFAE;
const USER3: address = @0xCEFA;
const USER4: address = @0xFACE;

fun setup(): Scenario{
    let mut scenario = ts::begin(OWNER);
    let ctx = scenario.ctx();
    ps::init_test(ctx);
    scenario
}

fun initialize_test(mut scenario: Scenario): Scenario{
    scenario.next_tx(OWNER);
    let owner = scenario.take_shared<Owner>();
    let ctx = scenario.ctx();
    ps::initialize<IOTA>(vector[USER1, USER2, USER3, USER4], vector[1, 1, 1, 1], owner, ctx);
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
    let scenario = initialize_test(scenario);
    let mut scenario = receive_test(100, scenario);
    release_test(&mut scenario);
    let scenario = take_amount_test(USER1, scenario);
    scenario.end();
}
