
#[test_only]
module vesting::vesting_tests;

use vesting::vesting::{Self, Vesting};
use iota::test_scenario::{Self as ts, Scenario};
use iota::coin;
use iota::iota::IOTA;
use iota::clock::{Self, Clock};

const EWrongAmount: u64 = 1;

const OWNER: address = @0xCAFE;
const USER: address = @0xFACE;

fun setup(): Scenario {
    let mut scenario = ts::begin(OWNER);
    let ctx = ts::ctx(&mut scenario);
    vesting::init_test(ctx);
    scenario
}

fun initialize_test(sender: address, clock: &Clock, mut scenario: Scenario): Scenario {
    ts::next_tx(&mut scenario, sender);
    let mut vesting = ts::take_shared<Vesting>(&scenario);
    let ctx = ts::ctx(&mut scenario);
    let coin = coin::mint_for_testing<IOTA>(100, ctx);
    vesting::initialize(USER, 10, 100, coin, &mut vesting, clock, ctx);
    ts::return_shared(vesting);
    scenario
}

fun release_test(sender: address, clock: &Clock, mut scenario: Scenario): Scenario {
    ts::next_tx(&mut scenario, sender);
    let mut vesting = ts::take_shared<Vesting>(&scenario);
    let ctx = ts::ctx(&mut scenario);
    vesting::release(&mut vesting, clock, ctx);
    ts::return_shared(vesting);
    scenario
}

#[test] 
public fun intended_way_zero(){
    let mut scenario = setup();
    let ctx = ts::ctx(&mut scenario);
    let mut clock = clock::create_for_testing(ctx);

    let scenario = initialize_test(OWNER, &clock, scenario);

    clock.increment_for_testing(5);
    let mut scenario = release_test(USER, &clock, scenario);

    ts::next_tx(&mut scenario, OWNER);
    let vesting = ts::take_shared<Vesting>(&scenario);
    assert!(vesting.value() == 100, EWrongAmount);
    ts::return_shared(vesting);

    clock.destroy_for_testing();
    ts::end(scenario);
}

#[test] 
public fun intended_way_relases(){
    let mut scenario = setup();
    let ctx = ts::ctx(&mut scenario);
    let mut clock = clock::create_for_testing(ctx);

    let scenario = initialize_test(OWNER, &clock, scenario);

    clock.increment_for_testing(60);
    let scenario = release_test(USER, &clock, scenario);


    clock.increment_for_testing(30);
    let mut scenario = release_test(USER, &clock, scenario);

    ts::next_tx(&mut scenario, OWNER);
    let vesting = ts::take_shared<Vesting>(&scenario);
    assert!(vesting.value() == 10, EWrongAmount);
    ts::return_shared(vesting);

    clock.destroy_for_testing();
    ts::end(scenario);
}

#[test] 
public fun intended_way_all(){
    let mut scenario = setup();
    let ctx = ts::ctx(&mut scenario);
    let mut clock = clock::create_for_testing(ctx);

    let scenario = initialize_test(OWNER, &clock, scenario);

    clock.increment_for_testing(20000);
    let mut scenario = release_test(USER, &clock, scenario);

    ts::next_tx(&mut scenario, OWNER);
    let vesting = ts::take_shared<Vesting>(&scenario);
    assert!(vesting.value() == 0, EWrongAmount);
    ts::return_shared(vesting);

    clock.destroy_for_testing();
    ts::end(scenario);
}

#[test] 
public fun intended_way_percentage(){
    let mut scenario = setup();
    let ctx = ts::ctx(&mut scenario);
    let mut clock = clock::create_for_testing(ctx);

    let scenario = initialize_test(OWNER, &clock, scenario);

    clock.increment_for_testing(27);
    let mut scenario = release_test(USER, &clock, scenario);

    ts::next_tx(&mut scenario, OWNER);
    let vesting = ts::take_shared<Vesting>(&scenario);
    assert!(vesting.value() == 83, EWrongAmount);
    ts::return_shared(vesting);

    clock.destroy_for_testing();
    ts::end(scenario);
}

#[test, expected_failure(abort_code = vesting::EPermissionDenied)] 
public fun not_owner_initialize(){
    let mut scenario = setup();
    let ctx = ts::ctx(&mut scenario);
    let clock = clock::create_for_testing(ctx);

    let scenario = initialize_test(USER, &clock, scenario);

    clock.destroy_for_testing();
    ts::end(scenario);
}

#[test, expected_failure(abort_code = vesting::EPermissionDenied)] 
public fun not_beneficiary_release(){
    let mut scenario = setup();
    let ctx = ts::ctx(&mut scenario);
    let mut clock = clock::create_for_testing(ctx);

    let scenario = initialize_test(OWNER, &clock, scenario);

    clock.increment_for_testing(27);
    let scenario = release_test(OWNER, &clock, scenario);

    clock.destroy_for_testing();
    ts::end(scenario);
}