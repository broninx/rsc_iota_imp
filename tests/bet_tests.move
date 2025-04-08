
#[test_only]
module rsc_iota_imp::bet_tests {
    
    use rsc_iota_imp::bet;
    use iota::coin;
    use iota::clock;
    use iota::test_scenario;
    use iota::iota::IOTA;

    const EEmptyInventory: u64 = 4;


    #[test]
    public fun bet_test_intended_way(){
        
  
        let player1: address = @0xCAFE;
        let player2: address = @0xFACE;
        let oracle: address = @0xADD;

        //transaction 1
        let mut scenario = test_scenario::begin(oracle);
        {
            bet::initialize(oracle, 200000, test_scenario::ctx(&mut scenario));
        };

        //transaction 2
        test_scenario::next_tx(&mut scenario, player1);
        {
            assert!(test_scenario::has_most_recent_shared<bet::Oracle>(), EEmptyInventory);
            let ctx = test_scenario::ctx(&mut scenario);
            let cl = clock::create_for_testing(ctx);
            let coin = coin::mint_for_testing<IOTA>(10, ctx);
            bet::join(& cl, 
            coin,
            player1, 
            player2, 
            ctx);
            cl.destroy_for_testing();
        };

        //transaction 3, case 1: the oracle predict the winner before the timeout
        test_scenario::next_tx(&mut scenario, oracle);
        {
            assert!(test_scenario::has_most_recent_shared<bet::Bet<IOTA>>(), EEmptyInventory);

            let bet = test_scenario::take_shared<bet::Bet<IOTA>>(&scenario); 
            let oracle = test_scenario::take_shared<bet::Oracle>(&scenario); 
            let ctx = test_scenario::ctx(&mut scenario);
            let cl = clock::create_for_testing(ctx);
            bet::win(bet, &oracle, player1,&cl,ctx);
            cl.destroy_for_testing();
            oracle.destroy();
        };

        test_scenario::end( scenario);
    }

    #[test]
    public fun bet_test_timeout(){
        
  
        let player1: address = @0xCAFE;
        let player2: address = @0xFACE;
        let oracle: address = @0xADD;

        //transaction 1
        let mut scenario = test_scenario::begin(oracle);
        {
            bet::initialize(oracle, 200000, test_scenario::ctx(&mut scenario));
        };

        //transaction 2
        test_scenario::next_tx(&mut scenario, player1);
        {
            assert!(test_scenario::has_most_recent_shared<bet::Oracle>(), EEmptyInventory);
            let ctx = test_scenario::ctx(&mut scenario);
            let cl = clock::create_for_testing(ctx);
            let coin = coin::mint_for_testing<IOTA>(10, ctx);
            bet::join(& cl, 
            coin,
            player1, 
            player2, 
            ctx);
            cl.destroy_for_testing();
        };

        //transaction 3, case 2: the time is over
        test_scenario::next_tx(&mut scenario, player1);
        {
            assert!(test_scenario::has_most_recent_shared<bet::Bet<IOTA>>(), EEmptyInventory);

            let bet = test_scenario::take_shared<bet::Bet<IOTA>>(&scenario); 
            let oracle = test_scenario::take_shared<bet::Oracle>(&scenario); 
            let ctx = test_scenario::ctx(&mut scenario);
            let mut cl = clock::create_for_testing(ctx);
            cl.increment_for_testing(oracle.deadline() + 1);
            bet::timeout(bet, &oracle, &cl, ctx);
            cl.destroy_for_testing();
            oracle.destroy()
        };

        test_scenario::end( scenario);
    }
// #[test, expected_failure(abort_code = ::rsc_iota_imp::rsc_iota_imp_tests::ENotImplemented)]
//     fun test_rsc_iota_imp_fail() {
//         abort ENotImplemented
//     }


    #[test, expected_failure(abort_code = bet::EOverTimeLimit)]
    public fun bet_test_set_winner_over_time(){
        
  
        let player1: address = @0xCAFE;
        let player2: address = @0xFACE;
        let oracle: address = @0xADD;

        //transaction 1
        let mut scenario = test_scenario::begin(oracle);
        {
            bet::initialize(oracle, 200000, test_scenario::ctx(&mut scenario));
        };

        //transaction 2
        test_scenario::next_tx(&mut scenario, player1);
        {
            assert!(test_scenario::has_most_recent_shared<bet::Oracle>(), EEmptyInventory);
            let ctx = test_scenario::ctx(&mut scenario);
            let cl = clock::create_for_testing(ctx);
            let coin = coin::mint_for_testing<IOTA>(10, ctx);
            bet::join(& cl, 
            coin,
            player1, 
            player2, 
            ctx);
            cl.destroy_for_testing();
        };

        //transaction 3, case 3: the oracle predict the winner after the time_out (expected abort)
        test_scenario::next_tx(&mut scenario, oracle);
        {
            assert!(test_scenario::has_most_recent_shared<bet::Bet<IOTA>>(), EEmptyInventory);

            let bet = test_scenario::take_shared<bet::Bet<IOTA>>(&scenario); 
            let oracle = test_scenario::take_shared<bet::Oracle>(&scenario); 
            let ctx = test_scenario::ctx(&mut scenario);
            let mut cl = clock::create_for_testing(ctx);
            cl.increment_for_testing(oracle.deadline() + 1);
            bet::win(bet, &oracle, player1,&cl,ctx);
            cl.destroy_for_testing();
            oracle.destroy();
        };
        test_scenario::end( scenario);
    }


    #[test, expected_failure(abort_code = bet::EPermissionDenied)]
    public fun bet_test_permission_denied(){

        let player1: address = @0xCAFE;
        let player2: address = @0xFACE;
        let oracle: address = @0xADD;

        //transaction 1
        let mut scenario = test_scenario::begin(oracle);
        {
            bet::initialize(oracle, 200000, test_scenario::ctx(&mut scenario));
        };

        //transaction 2
        test_scenario::next_tx(&mut scenario, player1);
        {
            assert!(test_scenario::has_most_recent_shared<bet::Oracle>(), EEmptyInventory);
            let ctx = test_scenario::ctx(&mut scenario);
            let cl = clock::create_for_testing(ctx);
            let coin = coin::mint_for_testing<IOTA>(10, ctx);
            bet::join(& cl, 
            coin,
            player1, 
            player2, 
            ctx);
            cl.destroy_for_testing();
        };
        //transactin 3, case 4: an account unauthorized try to set the winner
        test_scenario::next_tx(&mut scenario, player1);
        {
            assert!(test_scenario::has_most_recent_shared<bet::Bet<IOTA>>(), EEmptyInventory);

            let bet = test_scenario::take_shared<bet::Bet<IOTA>>(&scenario); 
            let oracle = test_scenario::take_shared<bet::Oracle>(&scenario); 
            let ctx = test_scenario::ctx(&mut scenario);
            let cl = clock::create_for_testing(ctx);
            bet::win(bet, &oracle, player1,&cl,ctx);
            cl.destroy_for_testing();
            oracle.destroy()
        };
        test_scenario::end( scenario);
    }
}
