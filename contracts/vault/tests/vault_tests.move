
#[test_only]
module vault::vault_tests;

use vault::vault::{Self, Vault};
use iota::iota::IOTA;
use iota::test_scenario::{Self as ts, Scenario};
use iota::coin;
use iota::clock::{Self, Clock};

const EEmptyInventory: u64 = 5;

const OWNER: address = @0xCAFE;
const USER: address = @0xFACE;

fun setup(): Scenario {
    let mut scenario = ts::begin(OWNER);
    let ctx = ts::ctx(&mut scenario);
    vault::init_test(ctx);
    scenario
}

fun initialize_test(sender: address, mut scenario: Scenario): Scenario{
    ts::next_tx(&mut scenario, sender);
    assert!(ts::has_most_recent_shared<Vault<IOTA>>(), EEmptyInventory);
    let vault = ts::take_shared<Vault<IOTA>>(&scenario);
    let ctx = ts::ctx(&mut scenario);
    vault::initialize<IOTA>(b"abcd1234", 60, vault, ctx);
    scenario
}

fun receive_test(amount: u64,vault: &mut Vault<IOTA>,ctx: &mut TxContext){
    let coin = coin::mint_for_testing<IOTA>(amount, ctx);
    vault::receive<IOTA>(coin, vault);
}

fun withdraw_test(sender: address,invault_amount: u64, withdrawal_amount: u64,clock: &Clock, mut scenario: Scenario): Scenario {
    ts::next_tx(&mut scenario, sender);
    let mut vault = ts::take_shared<Vault<IOTA>>(&scenario);
    let ctx = ts::ctx(&mut scenario);
    receive_test(invault_amount, &mut vault, ctx);
    vault::withdraw(withdrawal_amount, &mut vault, clock, ctx);
    ts::return_shared(vault);
    scenario
}

fun finalize_test(sender: address, clock: &Clock, mut scenario: Scenario): Scenario {
    ts::next_tx(&mut scenario, sender);
    let mut vault = ts::take_shared<Vault<IOTA>>(&scenario);
    let ctx = ts::ctx(&mut scenario);
    vault::finalize(&mut vault, clock, ctx);
    ts::return_shared(vault);
    scenario
}

fun cancel_test(recovery_key: vector<u8>, sender: address, clock: &Clock, mut scenario: Scenario): Scenario{
    ts::next_tx(&mut scenario, sender);
    let mut vault = ts::take_shared<Vault<IOTA>>(&scenario);
    let ctx = ts::ctx(&mut scenario);
    vault::cancel(recovery_key, &mut vault, clock, ctx);
    ts::return_shared(vault);
    scenario
}

#[test]
public fun initended_way_finalize(){
    let mut scenario = setup();
    let ctx = ts::ctx(&mut scenario);
    let mut clock = clock::create_for_testing(ctx);

    let scenario = initialize_test(OWNER, scenario);

    let scenario = withdraw_test(OWNER, 1000, 500, &clock, scenario);

    clock.increment_for_testing(60001);
    let scenario = finalize_test(OWNER, &clock, scenario);

    clock.destroy_for_testing();
    ts::end(scenario);
}

#[test]
public fun initended_way_cancel(){
    let mut scenario = setup();
    let ctx = ts::ctx(&mut scenario);
    let clock = clock::create_for_testing(ctx);

    let scenario = initialize_test(OWNER, scenario);

    let scenario = withdraw_test(OWNER, 1000, 500, &clock, scenario);

    let scenario = cancel_test(b"abcd1234", OWNER, &clock, scenario);

    clock.destroy_for_testing();
    ts::end(scenario);
}

#[test, expected_failure(abort_code = vault::EPermissionDenied)]
public fun not_owner_withdraw(){
    let mut scenario = setup();
    let ctx = ts::ctx(&mut scenario);
    let clock = clock::create_for_testing(ctx);

    let scenario = initialize_test(OWNER, scenario);

    let scenario = withdraw_test(USER, 1000, 500, &clock, scenario);

    clock.destroy_for_testing();
    ts::end(scenario);
}

#[test, expected_failure(abort_code = vault::ELowBalance)]
public fun low_balance_withdraw(){
    let mut scenario = setup();
    let ctx = ts::ctx(&mut scenario);
    let clock = clock::create_for_testing(ctx);

    let scenario = initialize_test(OWNER, scenario);

    let scenario = withdraw_test(OWNER, 1000, 1001, &clock, scenario);

    clock.destroy_for_testing();
    ts::end(scenario);
}

#[test, expected_failure(abort_code = vault::EWrongState)]
public fun not_withdrawal_finalize(){
    let mut scenario = setup();
    let ctx = ts::ctx(&mut scenario);
    let mut clock = clock::create_for_testing(ctx);

    let scenario = initialize_test(OWNER, scenario);

    clock.increment_for_testing(60001);
    let scenario = finalize_test(OWNER, &clock, scenario);

    clock.destroy_for_testing();
    ts::end(scenario);
}

#[test, expected_failure(abort_code = vault::EWrongTime)]
public fun finalize_under_finish_time(){
    let mut scenario = setup();
    let ctx = ts::ctx(&mut scenario);
    let mut clock = clock::create_for_testing(ctx);

    let scenario = initialize_test(OWNER, scenario);

    let scenario = withdraw_test(OWNER, 1000, 500, &clock, scenario);

    clock.increment_for_testing(30000);
    let scenario = finalize_test(OWNER, &clock, scenario);

    clock.destroy_for_testing();
    ts::end(scenario);
}

#[test, expected_failure(abort_code = vault::EPermissionDenied)]
public fun not_owner_finalize(){
    let mut scenario = setup();
    let ctx = ts::ctx(&mut scenario);
    let mut clock = clock::create_for_testing(ctx);

    let scenario = initialize_test(OWNER, scenario);

    let scenario = withdraw_test(OWNER, 1000, 500, &clock, scenario);

    clock.increment_for_testing(60001);
    let scenario = finalize_test(USER, &clock, scenario);

    clock.destroy_for_testing();
    ts::end(scenario);
}

#[test, expected_failure(abort_code = vault::EWrongState)]
public fun not_withdraw_cancel(){
    let mut scenario = setup();
    let ctx = ts::ctx(&mut scenario);
    let clock = clock::create_for_testing(ctx);

    let scenario = initialize_test(OWNER, scenario);

    let scenario = cancel_test(b"abcd1234", OWNER, &clock, scenario);

    clock.destroy_for_testing();
    ts::end(scenario);
}

#[test, expected_failure(abort_code = vault::EWrongTime)]
public fun cancel_over_time(){
    let mut scenario = setup();
    let ctx = ts::ctx(&mut scenario);
    let mut clock = clock::create_for_testing(ctx);

    let scenario = initialize_test(OWNER, scenario);

    let scenario = withdraw_test(OWNER, 1000, 500, &clock, scenario);

    clock.increment_for_testing(60001);
    let scenario = cancel_test(b"abcd1234", OWNER, &clock, scenario);

    clock.destroy_for_testing();
    ts::end(scenario);
}

#[test, expected_failure(abort_code = vault::EPermissionDenied)]
public fun not_owner_cancel(){
    let mut scenario = setup();
    let ctx = ts::ctx(&mut scenario);
    let clock = clock::create_for_testing(ctx);

    let scenario = initialize_test(OWNER, scenario);

    let scenario = withdraw_test(OWNER, 1000, 500, &clock, scenario);

    let scenario = cancel_test(b"abcd1234", USER, &clock, scenario);

    clock.destroy_for_testing();
    ts::end(scenario);
}

#[test, expected_failure(abort_code = vault::EPermissionDenied)]
public fun wrong_key_cancel(){
    let mut scenario = setup();
    let ctx = ts::ctx(&mut scenario);
    let clock = clock::create_for_testing(ctx);

    let scenario = initialize_test(OWNER, scenario);

    let scenario = withdraw_test(OWNER, 1000, 500, &clock, scenario);

    let scenario = cancel_test(b"ab12", OWNER, &clock, scenario);

    clock.destroy_for_testing();
    ts::end(scenario);
}