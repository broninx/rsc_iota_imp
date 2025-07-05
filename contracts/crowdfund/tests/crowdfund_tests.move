
#[test_only]
module crowdfund::crowdfund_tests;

use crowdfund::crowdfund::{Self, Crowdfund};
use iota::test_scenario::{Self, Scenario};
use iota::iota::IOTA;
use iota::coin;
use iota::clock::{Self, Clock};



const OWNER: address = @0xCAFE;
const RECIPIENT: address = @0xFACE;
const DONOR1: address = @0xCAEF;
const DONOR2: address = @0xFECA;

fun initialize_test(): Scenario{
    let mut scenario = test_scenario::begin(OWNER);
    let ctx = test_scenario::ctx(&mut scenario);
    let clock = clock::create_for_testing(ctx);
    crowdfund::initialize(RECIPIENT, 6000, 6, &clock, ctx);
    clock.destroy_for_testing();
    scenario
}

fun donate_test(value: u64, sender: address, clock: &Clock, mut scenario: Scenario): Scenario {
    test_scenario::next_tx(&mut scenario, sender);
    let mut crowdfund = test_scenario::take_shared<Crowdfund>(&scenario);
    let ctx = test_scenario::ctx(&mut scenario);
    let coin = coin::mint_for_testing<IOTA>(value, ctx);
    crowdfund::donate(coin, &mut crowdfund, clock, ctx);
    test_scenario::return_shared(crowdfund);
    scenario
}

fun withdraw_test(sender: address, clock: &Clock, mut scenario: Scenario): Scenario {
    test_scenario::next_tx(&mut scenario, sender);
    let crowdfund = test_scenario::take_shared<Crowdfund>(&scenario);
    let ctx = test_scenario::ctx(&mut scenario);
    crowdfund::withdraw( crowdfund, clock, ctx);
    scenario
}

fun reclaim_test(sender: address, clock: &Clock, mut scenario: Scenario): Scenario {
    test_scenario::next_tx(&mut scenario, sender);
    let crowdfund = test_scenario::take_shared<Crowdfund>(&scenario);
    let ctx = test_scenario::ctx(&mut scenario);
    crowdfund::reclaim( crowdfund, clock, ctx);
    scenario
}

#[test]
public fun initended_way_goal_achived(){
    let mut scenario = initialize_test();

    let ctx = test_scenario::ctx(&mut scenario);
    let mut clock = clock::create_for_testing(ctx);
    let scenario = donate_test(1000, DONOR1, &clock, scenario);

    let scenario = donate_test(2000, DONOR2, &clock, scenario);

    let scenario = donate_test(4000, DONOR1, &clock, scenario);

    clock.increment_for_testing( 21600000);
    let scenario = withdraw_test(RECIPIENT, &clock, scenario);

    clock.destroy_for_testing();
    test_scenario::end(scenario);
}

#[test]
public fun initended_way_goal_not_achived(){
    let mut scenario = initialize_test();

    let ctx = test_scenario::ctx(&mut scenario);
    let mut clock = clock::create_for_testing(ctx);
    let scenario = donate_test(1000, DONOR1, &clock, scenario);

    let scenario = donate_test(2000, DONOR2, &clock, scenario);

    let scenario = donate_test(2000, DONOR1, &clock, scenario);

    clock.increment_for_testing( 21600000);
    let scenario = reclaim_test(DONOR1, &clock, scenario);

    clock.destroy_for_testing();
    test_scenario::end(scenario);
}

#[test, expected_failure(abort_code = crowdfund::ETimeFinished)]
public fun time_finished_donate(){
    let mut scenario = initialize_test();

    let ctx = test_scenario::ctx(&mut scenario);
    let mut clock = clock::create_for_testing(ctx);
    clock.increment_for_testing( 21600001);
    let scenario = donate_test(1000, DONOR1, &clock, scenario);

    clock.destroy_for_testing();
    test_scenario::end(scenario);
}

#[test, expected_failure(abort_code = crowdfund::EPermissionDenied)]
public fun withdraw_not_recipient(){
    let mut scenario = initialize_test();

    let ctx = test_scenario::ctx(&mut scenario);
    let mut clock = clock::create_for_testing(ctx);
    let scenario = donate_test(6000, DONOR1,&clock, scenario);

    clock.increment_for_testing( 21600000);
    let scenario = withdraw_test(DONOR1, &clock, scenario);

    clock.destroy_for_testing();
    test_scenario::end(scenario);
}

#[test, expected_failure(abort_code = crowdfund::ETimeNotFinished)]
public fun time_not_finished_withdraw(){
    let mut scenario = initialize_test();

    let ctx = test_scenario::ctx(&mut scenario);
    let mut clock = clock::create_for_testing(ctx);
    let scenario = donate_test(6000, DONOR1, &clock, scenario);

    clock.increment_for_testing( 21500000);
    let scenario = withdraw_test(RECIPIENT, &clock, scenario);

    clock.destroy_for_testing();
    test_scenario::end(scenario);
}

#[test, expected_failure(abort_code = crowdfund::EGoalNotAchived)]
public fun goal_not_achived_withdraw(){
    let mut scenario = initialize_test();

    let ctx = test_scenario::ctx(&mut scenario);
    let mut clock = clock::create_for_testing(ctx);
    let scenario = donate_test(5000, DONOR1, &clock, scenario);

    clock.increment_for_testing( 21600000);
    let scenario = withdraw_test(RECIPIENT, &clock, scenario);

    clock.destroy_for_testing();
    test_scenario::end(scenario);
}

#[test, expected_failure(abort_code = crowdfund::ETimeNotFinished)]
public fun time_not_finished_reclaim(){
    let mut scenario = initialize_test();

    let ctx = test_scenario::ctx(&mut scenario);
    let mut clock = clock::create_for_testing(ctx);
    let scenario = donate_test(4000, DONOR1, &clock, scenario);

    clock.increment_for_testing( 21400000);
    let scenario = reclaim_test(DONOR1, &clock, scenario);

    clock.destroy_for_testing();
    test_scenario::end(scenario);
}

#[test, expected_failure(abort_code = crowdfund::EGoalAchived)]
public fun goal_achived_reclaim(){
    let mut scenario = initialize_test();

    let ctx = test_scenario::ctx(&mut scenario);
    let mut clock = clock::create_for_testing(ctx);
    let scenario = donate_test(7000, DONOR1, &clock, scenario);

    clock.increment_for_testing( 21600000);
    let scenario = reclaim_test(DONOR1, &clock, scenario);

    clock.destroy_for_testing();
    test_scenario::end(scenario);
}

#[test, expected_failure(abort_code = crowdfund::ENotDonor)]
public fun not_donor_reclaim(){
    let mut scenario = initialize_test();

    let ctx = test_scenario::ctx(&mut scenario);
    let mut clock = clock::create_for_testing(ctx);
    let scenario = donate_test(5000, DONOR1, &clock, scenario);

    clock.increment_for_testing( 21600000);
    let scenario = reclaim_test(DONOR2, &clock, scenario);

    clock.destroy_for_testing();
    test_scenario::end(scenario);
}