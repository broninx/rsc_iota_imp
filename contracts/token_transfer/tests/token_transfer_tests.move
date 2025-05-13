#[test_only]
module token_transfer::simple_transfer_tests;

use token_transfer::token_transfer::{Self, Wallet};
use iota::test_scenario;
use iota::coin;
use iota::iota::IOTA;

const EEmptyInventory: u64 = 3;
const EWrongAmount: u64 = 4;

const OWNER : address = @0xCAFE;
const RECEIVER: address = @0xFACE;

public struct MyToken has drop {
        value: u64
}

 public fun mint(amount: u64): MyToken {
        MyToken { value: amount }
}

public fun value(token: &MyToken): u64 {
        token.value
}

public fun transaction1(scenario: &mut test_scenario::Scenario){
    let ctx = test_scenario::ctx(scenario);
    token_transfer::initialize(ctx);
}

public fun transaction3(wallet: &mut token_transfer::Wallet<MyToken>, scenario: &mut test_scenario::Scenario){
    let ctx = test_scenario::ctx(scenario);
    let coin = coin::mint_for_testing<MyToken>(10000, ctx);
    token_transfer::deposit<MyToken>(coin,  wallet, ctx);
}

#[test]
public fun intended_way() {
    
    let mut scenario = test_scenario::begin(OWNER);
    transaction1(&mut scenario);

    test_scenario::next_tx(&mut scenario, OWNER);
    {
        assert!(test_scenario::has_most_recent_shared<Wallet<IOTA>>(), EEmptyInventory);
        let wallet = test_scenario::take_shared<Wallet<IOTA>>(&scenario);
        let ctx = test_scenario::ctx(&mut scenario);
        token_transfer::set_balance_and_receiver<MyToken>(RECEIVER, wallet, ctx);
    };

    test_scenario::next_tx(&mut scenario, OWNER);
    {
        assert!(test_scenario::has_most_recent_shared<Wallet<MyToken>>(), EEmptyInventory);
        let mut wallet = test_scenario::take_shared<Wallet<MyToken>>(&scenario);
        transaction3(&mut wallet, &mut scenario);
        test_scenario::return_shared(wallet);
    };

    test_scenario::next_tx(&mut scenario, RECEIVER);
    {
        let mut wallet = test_scenario::take_shared<Wallet<MyToken>>(&scenario);
        assert!(token_transfer::wallet_amount(&wallet) == 10000, EWrongAmount);
        let ctx = test_scenario::ctx(&mut scenario);
        token_transfer::withdrow(1000, &mut wallet, ctx); 
        assert!(token_transfer::wallet_amount(&wallet) == 9000, EWrongAmount);
        test_scenario::return_shared(wallet);
    };

    test_scenario::next_tx(&mut scenario, RECEIVER);
    {
        let mut wallet = test_scenario::take_shared<Wallet<MyToken>>(&scenario);
        let ctx = test_scenario::ctx(&mut scenario);
        token_transfer::withdrow(9000, &mut wallet, ctx); 
        assert!(token_transfer::wallet_amount(&wallet) == 0, EWrongAmount);
        test_scenario::return_shared(wallet);
    };
    test_scenario::end(scenario);
}

#[test, expected_failure(abort_code = token_transfer::EPermissionsDenied)]
public fun unauthorized_set_receiver() {
    
    let mut scenario = test_scenario::begin(OWNER);
    transaction1(&mut scenario);

    test_scenario::next_tx(&mut scenario, RECEIVER);
    {   
        let wallet = test_scenario::take_shared<Wallet<IOTA>>(&scenario);
        let ctx = test_scenario::ctx(&mut scenario);
        token_transfer::set_balance_and_receiver<MyToken>(RECEIVER, wallet, ctx);
    };

    test_scenario::end(scenario);
}

#[test, expected_failure(abort_code = token_transfer::EPermissionsDenied)]
public fun receiver_just_setted() {
    
    let mut scenario = test_scenario::begin(OWNER);
    transaction1(&mut scenario);

    test_scenario::next_tx(&mut scenario, OWNER);
    {
        let wallet = test_scenario::take_shared<Wallet<IOTA>>(&scenario);
        let ctx = test_scenario::ctx(&mut scenario);
        token_transfer::set_balance_and_receiver<IOTA>(RECEIVER, wallet, ctx);
    };
    
    test_scenario::next_tx(&mut scenario, OWNER);
    {
        let wallet = test_scenario::take_shared<Wallet<IOTA>>(&scenario);
        let ctx = test_scenario::ctx(&mut scenario);
        token_transfer::set_balance_and_receiver<MyToken>(RECEIVER, wallet, ctx);
    };
    test_scenario::end(scenario);
}

#[test, expected_failure(abort_code = token_transfer::EPermissionsDenied)]
public fun receiver_cant_deposit() {
    
    let mut scenario = test_scenario::begin(OWNER);
    transaction1(&mut scenario);

    test_scenario::next_tx(&mut scenario, OWNER);
    {
        let wallet = test_scenario::take_shared<Wallet<IOTA>>(&scenario);
        let ctx = test_scenario::ctx(&mut scenario);
        token_transfer::set_balance_and_receiver<MyToken>(RECEIVER, wallet, ctx);
    };

    test_scenario::next_tx(&mut scenario, RECEIVER);
    {
        let mut wallet = test_scenario::take_shared<Wallet<MyToken>>(&scenario);
        let ctx = test_scenario::ctx(&mut scenario);
        let coin = coin::mint_for_testing<MyToken>(10000, ctx);
        token_transfer::deposit(coin, &mut wallet, ctx);
        test_scenario::return_shared(wallet);
    };

    test_scenario::end(scenario);
}

#[test, expected_failure(abort_code = token_transfer::EPermissionsDenied)]
public fun only_receiver_withdrow() {
    
    let mut scenario = test_scenario::begin(OWNER);
    transaction1(&mut scenario);

    test_scenario::next_tx(&mut scenario, OWNER);
    {
        let wallet = test_scenario::take_shared<Wallet<IOTA>>(&scenario);
        let ctx = test_scenario::ctx(&mut scenario);
        token_transfer::set_balance_and_receiver<MyToken>(RECEIVER, wallet, ctx);
     
    };

    test_scenario::next_tx(&mut scenario, OWNER);
    {
        let mut wallet = test_scenario::take_shared<Wallet<MyToken>>(&scenario);
        transaction3(&mut wallet, &mut scenario);
        test_scenario::return_shared(wallet);
    };

    test_scenario::next_tx(&mut scenario, OWNER);
    {
        let mut wallet = test_scenario::take_shared<Wallet<MyToken>>(&scenario);
        let ctx = test_scenario::ctx(&mut scenario);
        token_transfer::withdrow(1000, &mut wallet, ctx); 
        test_scenario::return_shared(wallet);
    };

    test_scenario::end(scenario);
}

#[test, expected_failure(abort_code = token_transfer::EBiggerThanBalance)]
public fun withdorw_amount_bigger_than_balance() {
    
    let mut scenario = test_scenario::begin(OWNER);
    transaction1(&mut scenario);

    test_scenario::next_tx(&mut scenario, OWNER);
    {   
        let wallet = test_scenario::take_shared<Wallet<IOTA>>(&scenario);
        let ctx = test_scenario::ctx(&mut scenario);
        token_transfer::set_balance_and_receiver<MyToken>(RECEIVER, wallet, ctx);
    };

    test_scenario::next_tx(&mut scenario, OWNER);
    {
        let mut wallet = test_scenario::take_shared<Wallet<MyToken>>(&scenario);
        transaction3(&mut wallet, &mut scenario);
        test_scenario::return_shared(wallet);
    };

    test_scenario::next_tx(&mut scenario, RECEIVER);
    {
        let mut wallet = test_scenario::take_shared<Wallet<MyToken>>(&scenario);
        assert!(token_transfer::wallet_amount(&wallet) == 10000, EWrongAmount);
        let ctx = test_scenario::ctx(&mut scenario);
        token_transfer::withdrow(10001, &mut wallet, ctx); 
        test_scenario::return_shared(wallet);
    };

    test_scenario::end(scenario);
}
