
#[test_only]
module simple_transfer::simple_transfer_tests;

use simple_transfer::simple_transfer::{Self, Wallet};
use iota::test_scenario;
use iota::coin;
use iota::iota::IOTA;

const EEmptyInventory: u64 = 3;
const EWrongAmount: u64 = 4;

const OWNER : address = @0xCAFE;
const RECEIVER: address = @0xFACE;

public fun transaction1(scenario: &mut test_scenario::Scenario){
    let ctx = test_scenario::ctx(scenario);
    simple_transfer::initialize(ctx);
}


#[test]
public fun intended_way() {
    
    let mut scenario = test_scenario::begin(OWNER);
    transaction1(&mut scenario);

    test_scenario::next_tx(&mut scenario, OWNER);
    {
        assert!(test_scenario::has_most_recent_shared<Wallet>(), EEmptyInventory);
        let mut wallet = test_scenario::take_shared<Wallet>(&scenario);
        let ctx = test_scenario::ctx(&mut scenario);
        simple_transfer::set_receiver(RECEIVER,&mut wallet, ctx);
        let coin = coin::mint_for_testing<IOTA>(10000, ctx);
        simple_transfer::deposit(coin, &mut wallet, ctx);
        test_scenario::return_shared(wallet);
    };

    test_scenario::next_tx(&mut scenario, RECEIVER);
    {
        let mut wallet = test_scenario::take_shared<Wallet>(&scenario);
        assert!(simple_transfer::wallet_amount(&wallet) == 10000, EWrongAmount);
        let ctx = test_scenario::ctx(&mut scenario);
        simple_transfer::withdrow(1000, &mut wallet, ctx); 
        assert!(simple_transfer::wallet_amount(&wallet) == 9000, EWrongAmount);
        test_scenario::return_shared(wallet);
    };

    test_scenario::next_tx(&mut scenario, RECEIVER);
    {
        let mut wallet = test_scenario::take_shared<Wallet>(&scenario);
        let ctx = test_scenario::ctx(&mut scenario);
        simple_transfer::withdrow(9000, &mut wallet, ctx); 
        assert!(simple_transfer::wallet_amount(&wallet) == 0, EWrongAmount);
        test_scenario::return_shared(wallet);
    };
    test_scenario::end(scenario);
}

#[test, expected_failure(abort_code = simple_transfer::EPermissionsDenied)]
public fun unauthorized_set_receiver() {
    
    let mut scenario = test_scenario::begin(OWNER);
    transaction1(&mut scenario);

    test_scenario::next_tx(&mut scenario, RECEIVER);
    {   
        let mut wallet = test_scenario::take_shared<Wallet>(&scenario);
        let ctx = test_scenario::ctx(&mut scenario);
        simple_transfer::set_receiver(RECEIVER,&mut wallet, ctx);
        test_scenario::return_shared(wallet);
    };

    test_scenario::end(scenario);
}

#[test, expected_failure(abort_code = simple_transfer::EPermissionsDenied)]
public fun receiver_just_setted() {
    
    let mut scenario = test_scenario::begin(OWNER);
    transaction1(&mut scenario);

    test_scenario::next_tx(&mut scenario, OWNER);
    {
        let mut wallet = test_scenario::take_shared<Wallet>(&scenario);
        let ctx = test_scenario::ctx(&mut scenario);
        simple_transfer::set_receiver(RECEIVER,&mut wallet, ctx);
        simple_transfer::set_receiver(RECEIVER,&mut wallet, ctx);
        test_scenario::return_shared(wallet);
    };
    
    test_scenario::end(scenario);
}

#[test, expected_failure(abort_code = simple_transfer::EPermissionsDenied)]
public fun receiver_cant_deposit() {
    
    let mut scenario = test_scenario::begin(OWNER);
    transaction1(&mut scenario);

    test_scenario::next_tx(&mut scenario, OWNER);
    {
        let mut wallet = test_scenario::take_shared<Wallet>(&scenario);
        let ctx = test_scenario::ctx(&mut scenario);
        simple_transfer::set_receiver(RECEIVER,&mut wallet, ctx);
        test_scenario::return_shared(wallet);
    };

    test_scenario::next_tx(&mut scenario, RECEIVER);
    {
        let mut wallet = test_scenario::take_shared<Wallet>(&scenario);
        let ctx = test_scenario::ctx(&mut scenario);
        let coin = coin::mint_for_testing<IOTA>(10000, ctx);
        simple_transfer::deposit(coin, &mut wallet, ctx);
        test_scenario::return_shared(wallet);
    };

    test_scenario::end(scenario);
}

#[test, expected_failure(abort_code = simple_transfer::EPermissionsDenied)]
public fun only_receiver_withdrow() {
    
    let mut scenario = test_scenario::begin(OWNER);
    transaction1(&mut scenario);

    test_scenario::next_tx(&mut scenario, OWNER);
    {
        let mut wallet = test_scenario::take_shared<Wallet>(&scenario);
        let ctx = test_scenario::ctx(&mut scenario);
        simple_transfer::set_receiver(RECEIVER,&mut wallet, ctx);
        let coin = coin::mint_for_testing<IOTA>(10000, ctx);
        simple_transfer::deposit(coin, &mut wallet, ctx);
        test_scenario::return_shared(wallet);
    };

    test_scenario::next_tx(&mut scenario, OWNER);
    {
        let mut wallet = test_scenario::take_shared<Wallet>(&scenario);
        let ctx = test_scenario::ctx(&mut scenario);
        simple_transfer::withdrow(1000, &mut wallet, ctx); 
        test_scenario::return_shared(wallet);
    };

    test_scenario::end(scenario);
}

#[test, expected_failure(abort_code = simple_transfer::EBiggerThanBalance)]
public fun withdorw_amount_bigger_than_balance() {
    
    let mut scenario = test_scenario::begin(OWNER);
    transaction1(&mut scenario);

    test_scenario::next_tx(&mut scenario, OWNER);
    {   
        assert!(test_scenario::has_most_recent_shared<Wallet>(), EEmptyInventory);
        let mut wallet = test_scenario::take_shared<Wallet>(&scenario);
        let ctx = test_scenario::ctx(&mut scenario);
        simple_transfer::set_receiver(RECEIVER,&mut wallet, ctx);
        let coin = coin::mint_for_testing<IOTA>(10000, ctx);
        simple_transfer::deposit(coin, &mut wallet, ctx);
        test_scenario::return_shared(wallet);
    };

    test_scenario::next_tx(&mut scenario, RECEIVER);
    {
        let mut wallet = test_scenario::take_shared<Wallet>(&scenario);
        assert!(simple_transfer::wallet_amount(&wallet) == 10000, EWrongAmount);
        let ctx = test_scenario::ctx(&mut scenario);
        simple_transfer::withdrow(10001, &mut wallet, ctx); 
        test_scenario::return_shared(wallet);
    };

    test_scenario::end(scenario);
}


// #[test, expected_failure(abort_code = ::simple_transfer::simple_transfer_tests::ENotImplemented)]
// fun test_simple_transfer_fail() {
//     abort ENotImplemented
// }

