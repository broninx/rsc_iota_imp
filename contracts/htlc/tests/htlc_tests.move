
#[test_only]
module htlc::htlc_tests;

use htlc::htlc::{Self, Htlc};
use iota::test_scenario;
use iota::iota::IOTA;
use iota::coin;
use iota::clock;

const EEmptyInventory: u64 = 4;

const OWNER: address = @0xCAFE;
const RECEIVER: address = @0xFACE;

// public struct Secret has drop {
//     hash: vector<u8>
// }

public fun setup(): test_scenario::Scenario {
    let mut scenario = test_scenario::begin(OWNER);
    {
        let ctx = test_scenario::ctx(&mut scenario);
        htlc::init_test(ctx);
    };
    scenario
}

public fun initialize_htlc(sender: address, mut scenario: test_scenario::Scenario): test_scenario::Scenario {
    test_scenario::next_tx(&mut scenario, sender);
    {
        assert!(test_scenario::has_most_recent_shared<Htlc>(), EEmptyInventory);
        let htlc = test_scenario::take_shared<Htlc>(&scenario);
        let ctx = test_scenario::ctx(&mut scenario);
        let hash = b"Hello";
        let two_min = 120000;
        let coin = coin::mint_for_testing<IOTA>(1000, ctx);
        let clock = clock::create_for_testing(ctx);
        htlc::initialize(RECEIVER, hash, two_min, coin, htlc, &clock, ctx);
        clock::destroy_for_testing(clock);
    };
    scenario
}

public fun reveal_test(
    secret: vector<u8>, 
    sender: address, 
    mut scenario: test_scenario::Scenario
    ): test_scenario::Scenario {
    test_scenario::next_tx(&mut scenario, sender);
    {
        assert!(test_scenario::has_most_recent_shared<Htlc>(), EEmptyInventory);
        let htlc = test_scenario::take_shared<Htlc>(&scenario);
        let ctx = test_scenario::ctx(&mut scenario);
        htlc::reveal(secret, htlc, ctx);
        assert!(!test_scenario::has_most_recent_shared<Htlc>(), EEmptyInventory);
    };
    scenario
}
#[test]
fun intended_way_reveal() {

    let scenario = initialize_htlc(OWNER, setup());

    let scenario = reveal_test(b"Hello", OWNER, scenario);
    test_scenario::end(scenario);
}

#[test]
fun intended_way_timeout() {

    let mut scenario = initialize_htlc(OWNER, setup());

    test_scenario::next_tx(&mut scenario, OWNER);
    {
        assert!(test_scenario::has_most_recent_shared<Htlc>(), EEmptyInventory);
        let htlc = test_scenario::take_shared<Htlc>(&scenario);
        let ctx = test_scenario::ctx(&mut scenario);
        let mut clock = clock::create_for_testing(ctx);
        clock.increment_for_testing(htlc.reveal_timeout() + 1);
        htlc::timeout(&clock, htlc);
        assert!(!test_scenario::has_most_recent_shared<Htlc>(), EEmptyInventory);
        clock::destroy_for_testing(clock);
    };
    test_scenario::end(scenario);
}

#[test, expected_failure(abort_code = htlc::EJustInitialized)]
fun double_initialize(){
    let scenario = initialize_htlc(OWNER, setup());
    let scenario = initialize_htlc(OWNER, scenario);
    test_scenario::end(scenario);
}

#[test, expected_failure(abort_code = htlc::EPermissionDenied)]
fun receiver_initialize(){
    let scenario = initialize_htlc(RECEIVER, setup());
    test_scenario::end(scenario);
}

#[test, expected_failure(abort_code = htlc::EPermissionDenied)]
fun receiver_reveal(){
    let scenario = initialize_htlc(OWNER, setup());
    let scenario = reveal_test(b"Hello", RECEIVER, scenario);
    test_scenario::end(scenario);
}

#[test, expected_failure(abort_code = htlc::EWrongSecret)]
fun wrong_secret(){
    let scenario = initialize_htlc(OWNER, setup());
    let scenario = reveal_test(b"XD", OWNER, scenario);
    test_scenario::end(scenario);
}

#[test, expected_failure(abort_code = htlc::ETimeNotFinished)]
fun time_not_finished(){
    let mut scenario = initialize_htlc(OWNER, setup());
    test_scenario::next_tx(&mut scenario, OWNER);
    {
        assert!(test_scenario::has_most_recent_shared<Htlc>(), EEmptyInventory);
        let htlc = test_scenario::take_shared<Htlc>(&scenario);
        let ctx = test_scenario::ctx(&mut scenario);
        let mut clock = clock::create_for_testing(ctx);
        clock.increment_for_testing(htlc.reveal_timeout() - 1);
        htlc::timeout(&clock, htlc);
        assert!(!test_scenario::has_most_recent_shared<Htlc>(), EEmptyInventory);
        clock::destroy_for_testing(clock);
    };
    test_scenario::end(scenario);
}
    // #[test, expected_failure(abort_code = ::htlc::htlc_tests::ENotImplemented)]
    // fun test_htlc_fail() {
    //     abort ENotImplemented
    // }


