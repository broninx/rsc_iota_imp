
#[test_only]
module auction::auction_tests; 

use auction::auction::{Self, Auction};
use iota::iota::IOTA;
use iota::test_scenario::{Self, Scenario};
use iota::coin; 
use iota::clock::{Self, Clock};

const EEmptyInventory: u64 = 4;

const SELLER: address = @0xCAFE;
const BIDDER: address = @0xFACE;

fun setup(): Scenario{
    let mut scenario = test_scenario::begin(SELLER);
    let ctx = test_scenario::ctx(&mut scenario);
    auction::init_test(ctx);
    scenario
}

fun initialize_test(mut scenario: Scenario): Scenario{
    test_scenario::next_tx(&mut scenario, SELLER);
    assert!(test_scenario::has_most_recent_shared<Auction>(), EEmptyInventory);
    let mut auction = test_scenario::take_shared<Auction>(&scenario);
    let ctx = test_scenario::ctx(&mut scenario);
    let starter_bid = coin::mint_for_testing<IOTA>(500, ctx);
    auction::initialize(b"pen", starter_bid, 5, &mut auction, ctx);
    test_scenario::return_shared(auction);
    scenario
}

fun start_test(sender: address, mut scenario: Scenario): Scenario{
    test_scenario::next_tx(&mut scenario, sender);
    let mut auction = test_scenario::take_shared<Auction>(&scenario);
    let ctx = test_scenario::ctx(&mut scenario);
    let clock = clock::create_for_testing(ctx);
    auction::start(&mut auction,&clock, ctx);
    test_scenario::return_shared(auction);
    clock.destroy_for_testing();
    scenario
}

fun bid_test(clock: Clock, bid_amount: u64, mut scenario: Scenario): Scenario{
    test_scenario::next_tx(&mut scenario, BIDDER);
    let mut auction = test_scenario::take_shared<Auction>(&scenario);
    let ctx = test_scenario::ctx(&mut scenario);
    let bid = coin::mint_for_testing<IOTA>(bid_amount, ctx);
    auction::bid(bid, &mut auction, &clock, ctx);
    test_scenario::return_shared(auction);
    clock.destroy_for_testing();
    scenario
}

fun end_test(clock: Clock, sender: address, mut scenario: Scenario): Scenario {
    test_scenario::next_tx(&mut scenario, sender);
    let auction = test_scenario::take_shared<Auction>(&scenario);
    let ctx = test_scenario::ctx(&mut scenario);
    auction::end(auction, &clock, ctx);
    clock.destroy_for_testing();
    assert!(!test_scenario::has_most_recent_shared<Auction>(), EEmptyInventory);
    scenario
}

#[test]
public fun intended_way_bid() {
    let scenario = initialize_test(setup());
    
    let mut scenario = start_test(SELLER, scenario);

    let ctx = test_scenario::ctx(&mut scenario);
    let mut clock = clock::create_for_testing(ctx);
    clock.increment_for_testing(60000);
    let mut scenario = bid_test(clock, 700, scenario);


    let ctx = test_scenario::ctx(&mut scenario);
    let mut clock = clock::create_for_testing(ctx);
    clock.increment_for_testing(300001);
    let scenario = end_test(clock, SELLER, scenario);

    test_scenario::end(scenario);
}

#[test]
public fun intended_way_no_bid() {
    let scenario = initialize_test(setup());
    
    let mut scenario = start_test(SELLER, scenario);

    let ctx = test_scenario::ctx(&mut scenario);
    let mut clock = clock::create_for_testing(ctx);
    clock.increment_for_testing(300001);
    let scenario = end_test(clock, SELLER, scenario);

    test_scenario::end(scenario);
}

#[test, expected_failure(abort_code = auction::EPermissionDenied)]
public fun wrong_state_start() {
    let scenario = initialize_test(setup());
    
    let scenario = start_test(SELLER, scenario);
    let scenario = start_test(SELLER, scenario);

    test_scenario::end(scenario);
}

#[test, expected_failure(abort_code = auction::EPermissionDenied)]
public fun wrong_sender_start() {
    let scenario = initialize_test(setup());
    
    let scenario = start_test(BIDDER, scenario);

    test_scenario::end(scenario);
}

#[test, expected_failure(abort_code = auction::EPermissionDenied)]
public fun wrong_state_bid() {
    let mut scenario = initialize_test(setup());
    
    let ctx = test_scenario::ctx(&mut scenario);
    let mut clock = clock::create_for_testing(ctx);
    clock.increment_for_testing(60000);
    let scenario = bid_test(clock, 700, scenario);

    test_scenario::end(scenario);
}

#[test, expected_failure(abort_code = auction::ETimeFinished)]
public fun wrong_time_bid() {
    let scenario = initialize_test(setup());
    
    let mut scenario = start_test(SELLER, scenario);

    let ctx = test_scenario::ctx(&mut scenario);
    let mut clock = clock::create_for_testing(ctx);
    clock.increment_for_testing(300001);
    let scenario = bid_test(clock, 700, scenario);

    test_scenario::end(scenario);
}

#[test, expected_failure(abort_code = auction::EBidTooMuchLower)]
public fun wrong_amount_bid() {
    let scenario = initialize_test(setup());
    
    let mut scenario = start_test(SELLER, scenario);

    let ctx = test_scenario::ctx(&mut scenario);
    let mut clock = clock::create_for_testing(ctx);
    clock.increment_for_testing(299999);
    let scenario = bid_test(clock, 499, scenario);

    test_scenario::end(scenario);
}

#[test, expected_failure(abort_code = auction::EPermissionDenied)]
public fun wrong_state_end() {
    let mut scenario = initialize_test(setup());
    
    let ctx = test_scenario::ctx(&mut scenario);
    let mut clock = clock::create_for_testing(ctx);
    clock.increment_for_testing(300001);
    let scenario = end_test(clock, SELLER, scenario);

    test_scenario::end(scenario);
}

#[test, expected_failure(abort_code = auction::ETimeNotFinished)]
public fun wrong_time_end() {
    let scenario = initialize_test(setup());
    
    let mut scenario = start_test(SELLER, scenario);

    let ctx = test_scenario::ctx(&mut scenario);
    let mut clock = clock::create_for_testing(ctx);
    clock.increment_for_testing(3000);
    let scenario = end_test(clock, SELLER, scenario);

    test_scenario::end(scenario);
}

#[test, expected_failure(abort_code = auction::EPermissionDenied)]
public fun wrong_sender_end() {
    let scenario = initialize_test(setup());
    
    let mut scenario = start_test(SELLER, scenario);

    let ctx = test_scenario::ctx(&mut scenario);
    let mut clock = clock::create_for_testing(ctx);
    clock.increment_for_testing(300001);
    let scenario = end_test(clock, BIDDER, scenario);

    test_scenario::end(scenario);
}