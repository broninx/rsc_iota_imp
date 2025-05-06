
#[test_only]
module bet::bet_tests {
    
    use bet::bet;
    use iota::coin;
    use iota::clock;
    use iota::test_scenario;
    use iota::iota::IOTA;

    const EEmptyInventory: u64 = 4;

    const PLAYER1: address = @0xCAFE;
    const PLAYER2: address = @0xFACE;
    const ORACLE: address = @0xADD;



    public fun transaction1(scenario: &mut test_scenario::Scenario){
        let ctx = test_scenario::ctx(scenario);
        let oracle = bet::create_oracle(ORACLE, 600000, ctx); 
        bet::transfer_share_object(oracle);
    }

    public fun transactin2(scenario: &mut test_scenario::Scenario, oracle: &bet::Oracle){
        let ctx = test_scenario::ctx( scenario);
        let cl = clock::create_for_testing(ctx);
        let coin = coin::mint_for_testing<IOTA>(10, ctx);
        bet::join(& cl, coin,
        PLAYER1, PLAYER2,oracle, ctx);
        cl.destroy_for_testing();
    }



    #[test]
    public fun bet_test_intended_way(){
        
  
                //transaction 1
        let mut scenario = test_scenario::begin(ORACLE);
        transaction1(&mut scenario);


        //transaction 2
        test_scenario::next_tx(&mut scenario, PLAYER1);
        {
            assert!(test_scenario::has_most_recent_shared<bet::Oracle>(), EEmptyInventory);
            let oracle = test_scenario::take_shared<bet::Oracle>(& scenario);
            transactin2(&mut scenario, &oracle);
            test_scenario::return_shared(oracle);
        };

        //transaction 3, case 1: the oracle predict the winner before the timeout
        test_scenario::next_tx(&mut scenario, ORACLE);
        {
            assert!(test_scenario::has_most_recent_shared<bet::Bet<IOTA>>(), EEmptyInventory);

            let bet = test_scenario::take_shared<bet::Bet<IOTA>>(&scenario); 
            let oracle = test_scenario::take_shared<bet::Oracle>(&scenario); 
            let ctx = test_scenario::ctx(&mut scenario);
            let cl = clock::create_for_testing(ctx);
            bet::win(bet, PLAYER1,&cl,ctx);
            cl.destroy_for_testing();
            oracle.destroy();
        };

        test_scenario::end( scenario);
    }


    #[test]
    public fun bet_test_timeout(){
        
  
       //transaction 1
        let mut scenario = test_scenario::begin(ORACLE);
        transaction1(&mut scenario);

        //transaction 2
        test_scenario::next_tx(&mut scenario, PLAYER1);
        {
            assert!(test_scenario::has_most_recent_shared<bet::Oracle>(), EEmptyInventory);
            let oracle = test_scenario::take_shared<bet::Oracle>(& scenario);
            transactin2(&mut scenario, &oracle);
            test_scenario::return_shared(oracle);
        };

        //transaction 3, case 2: the time is over
        test_scenario::next_tx(&mut scenario, PLAYER1);
        {
            assert!(test_scenario::has_most_recent_shared<bet::Bet<IOTA>>(), EEmptyInventory);

            let bet = test_scenario::take_shared<bet::Bet<IOTA>>(&scenario); 
            let oracle = test_scenario::take_shared<bet::Oracle>(&scenario); 
            let ctx = test_scenario::ctx(&mut scenario);
            let mut cl = clock::create_for_testing(ctx);
            cl.increment_for_testing(oracle.deadline() + 1);
            bet::timeout(bet, &cl,ctx);
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
        
  
        //transaction 1
        let mut scenario = test_scenario::begin(ORACLE);
        transaction1(&mut scenario);

        //transaction 2
        test_scenario::next_tx(&mut scenario, PLAYER1);
        {
            assert!(test_scenario::has_most_recent_shared<bet::Oracle>(), EEmptyInventory);
            let oracle = test_scenario::take_shared<bet::Oracle>(& scenario);
            transactin2(&mut scenario, &oracle);
            test_scenario::return_shared(oracle);
        };

        //transaction 3, case 3: the oracle predict the winner after the time_out (expected abort)
        test_scenario::next_tx(&mut scenario, ORACLE);
        {
            assert!(test_scenario::has_most_recent_shared<bet::Bet<IOTA>>(), EEmptyInventory);

            let bet = test_scenario::take_shared<bet::Bet<IOTA>>(&scenario); 
            let oracle = test_scenario::take_shared<bet::Oracle>(&scenario); 
            let ctx = test_scenario::ctx(&mut scenario);
            let mut cl = clock::create_for_testing(ctx);
            cl.increment_for_testing(oracle.deadline() + 1);
            bet::win(bet,PLAYER1,&cl,ctx);
            cl.destroy_for_testing();
            oracle.destroy();
        };
        test_scenario::end( scenario);
    }


    #[test, expected_failure(abort_code = bet::EPermissionDenied)]
    public fun bet_test_permission_denied(){

        
        //transaction 1
        let mut scenario = test_scenario::begin(ORACLE);
        transaction1(&mut scenario);
        
        //transaction 2
        test_scenario::next_tx(&mut scenario, PLAYER1);
        {
            assert!(test_scenario::has_most_recent_shared<bet::Oracle>(), EEmptyInventory);
            let oracle = test_scenario::take_shared<bet::Oracle>(& scenario);
            transactin2(&mut scenario, &oracle);
            test_scenario::return_shared(oracle);
        };
        
        //transactin 3, case 4: an account unauthorized try to set the winner
        test_scenario::next_tx(&mut scenario, PLAYER1);
        {
            assert!(test_scenario::has_most_recent_shared<bet::Bet<IOTA>>(), EEmptyInventory);

            let bet = test_scenario::take_shared<bet::Bet<IOTA>>(&scenario); 
            let oracle = test_scenario::take_shared<bet::Oracle>(&scenario); 
            let ctx = test_scenario::ctx(&mut scenario);
            let cl = clock::create_for_testing(ctx);
            bet::win(bet,PLAYER1,&cl,ctx);
            cl.destroy_for_testing();
            oracle.destroy()
        };
        test_scenario::end( scenario);
    }
}
