
#[test_only]
module token_transfer::token_transfer_tests;

use token_transfer::token_transfer::{Self, Wallet};
use iota::test_scenario::{Self, Scenario};
use iota::coin;
use iota::iota::IOTA;

const EEmptyInventory: u64 = 3;

const OWNER : address = @0xCAFE;
const RECEIVER: address = @0xFACE;

fun setup(): Scenario{
    let mut scenario = test_scenario::begin(OWNER);
    let ctx = test_scenario::ctx(&mut scenario);
    token_transfer::initialize(ctx);
    scenario
}

fun deposit_test(amount: u64, sender: address, mut scenario: Scenario): Scenario{
    test_scenario::next_tx(&mut scenario, sender);
    assert!(test_scenario::has_most_recent_shared<Wallet<IOTA>>(), EEmptyInventory);
    let mut wallet = test_scenario::take_shared<Wallet<IOTA>>(&scenario);
    let ctx = test_scenario::ctx(&mut scenario);
    let coin = coin::mint_for_testing<IOTA>(amount, ctx);
    token_transfer::deposit(coin, &mut wallet, ctx);
    test_scenario::return_shared(wallet);
    scenario
}

fun withdraw_test(amount: u64, sender: address, mut scenario: Scenario): Scenario{
    test_scenario::next_tx(&mut scenario, sender);
    let mut wallet = test_scenario::take_shared<Wallet<IOTA>>(&scenario);
    let ctx = test_scenario::ctx(&mut scenario);
    token_transfer::withdraw(amount, &mut wallet, ctx); 
    test_scenario::return_shared(wallet);
    scenario
}

#[test]
public fun intended_way() {
    let scenario = setup();

    let scenario = deposit_test(10000, OWNER, scenario);
    
    let scenario = withdraw_test(1000, RECEIVER, scenario);

    let scenario = withdraw_test(9000, RECEIVER, scenario);

    test_scenario::end(scenario);
}

#[test, expected_failure(abort_code = token_transfer::EPermissionsDenied)]
public fun unauthorized_set_receiver() {
    let mut scenario = setup();

    test_scenario::next_tx(&mut scenario, RECEIVER);
    {   
        let wallet = test_scenario::take_shared<Wallet<IOTA>>(&scenario);
        let ctx = test_scenario::ctx(&mut scenario);
        token_transfer::set_balance_and_receiver<IOTA>(RECEIVER, wallet, ctx);
    };

    test_scenario::end(scenario);
}

#[test, expected_failure(abort_code = token_transfer::EPermissionsDenied)]
public fun receiver_cant_deposit() {
    let scenario = setup();

    let scenario = deposit_test(1000, RECEIVER, scenario); 

    test_scenario::end(scenario);
}

#[test, expected_failure(abort_code = token_transfer::EPermissionsDenied)]
public fun only_receiver_withdraw() {
    let scenario = setup();

    let scenario = deposit_test(10000, OWNER, scenario); 

    let scenario = withdraw_test(10, OWNER, scenario); 

    test_scenario::end(scenario);
}

#[test, expected_failure(abort_code = token_transfer::EBiggerThanBalance)]
public fun withdorw_amount_bigger_than_balance() {
    let scenario = setup();

    let scenario = deposit_test(1000, OWNER, scenario); 

    let scenario = withdraw_test(1001, RECEIVER, scenario);

    test_scenario::end(scenario);
}

