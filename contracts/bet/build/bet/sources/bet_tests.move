
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


    public fun setup(): test_scenario::Scenario{
        let mut scenario = test_scenario::begin(ORACLE);
        let ctx = test_scenario::ctx(&mut scenario);
        let oracle = bet::create_oracle(ORACLE, 600000, ctx); 
        bet::transfer_share_object(oracle);
        scenario
    }

    public fun join_test(mut scenario: test_scenario::Scenario): test_scenario::Scenario{
        test_scenario::next_tx(&mut scenario, PLAYER1);
        {
            assert!(test_scenario::has_most_recent_shared<bet::Oracle>(), EEmptyInventory);
            let oracle = test_scenario::take_shared<bet::Oracle>(& scenario);
            let ctx = test_scenario::ctx(&mut  scenario);
            let cl = clock::create_for_testing(ctx);
            let coin = coin::mint_for_testing<IOTA>(10, ctx);
            bet::join(& cl, coin,
            PLAYER1, PLAYER2,&oracle, ctx);
            cl.destroy_for_testing();
            test_scenario::return_shared(oracle);
        };
        scenario
    }


    #[test]
    public fun intended_way(){
        
        let scenario = setup();

        let mut scenario = join_test(scenario);

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
    public fun timeout(){
  
        let scenario = setup();
        
        let mut scenario = join_test(scenario);

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


    #[test, expected_failure(abort_code = bet::EOverTimeLimit)]
    public fun set_winner_over_time(){
        
        let scenario = setup();

        let mut scenario = join_test(scenario);

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
    public fun permission_denied_win(){

        let scenario = setup();
        
        let mut scenario = join_test(scenario);
        
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

    #[test, expected_failure( abort_code = bet::EWinnerNotPlayer)]
    public fun winner_not_player(){
        
        let scenario = setup();
        
        let mut scenario = join_test(scenario);

        test_scenario::next_tx(&mut scenario, ORACLE);
        {
            assert!(test_scenario::has_most_recent_shared<bet::Bet<IOTA>>(), EEmptyInventory);
            let bet = test_scenario::take_shared<bet::Bet<IOTA>>(&scenario); 
            let oracle = test_scenario::take_shared<bet::Oracle>(&scenario); 
            let ctx = test_scenario::ctx(&mut scenario);
            let cl = clock::create_for_testing(ctx);
            bet::win(bet, ORACLE,&cl,ctx);
            cl.destroy_for_testing();
            oracle.destroy();
        };

        test_scenario::end( scenario);
    }

    #[test, expected_failure(abort_code = bet::ETimeIsNotFinish)]
    public fun timeout_before_finish(){
        
        let scenario = setup();
        
        let mut scenario = join_test(scenario);

        test_scenario::next_tx(&mut scenario, PLAYER1);
        {
            assert!(test_scenario::has_most_recent_shared<bet::Bet<IOTA>>(), EEmptyInventory);
            let bet = test_scenario::take_shared<bet::Bet<IOTA>>(&scenario); 
            let oracle = test_scenario::take_shared<bet::Oracle>(&scenario); 
            let ctx = test_scenario::ctx(&mut scenario);
            let mut cl = clock::create_for_testing(ctx);
            cl.increment_for_testing(oracle.deadline() - 1);
            bet::timeout(bet, &cl,ctx);
            cl.destroy_for_testing();
            oracle.destroy()
        };

        test_scenario::end( scenario);
    }
}

