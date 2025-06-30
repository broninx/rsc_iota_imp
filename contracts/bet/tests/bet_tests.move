
#[test_only]
module bet::bet_tests {
    
    use bet::bet::{Self, Bet};
    use iota::coin;
    use iota::clock::{Self, Clock};
    use iota::test_scenario::{Self as ts, Scenario};
    use iota::iota::IOTA;

    const EEmptyInventory: u64 = 4;

    const PLAYER1: address = @0xCAFE;
    const PLAYER2: address = @0xFACE;
    const ORACLE: address = @0xADD;


    public fun setup(): Scenario{
        let mut scenario = ts::begin(ORACLE);
        let ctx = scenario.ctx();
        bet::init_test(ctx); 
        scenario
    }

    public fun join1_test(mut scenario: Scenario): Scenario{
        scenario.next_tx(PLAYER1);
        assert!(ts::has_most_recent_shared<bet::Oracle>(), EEmptyInventory);
        let oracle = scenario.take_shared<bet::Oracle>();
        let ctx = scenario.ctx();
        let coin = coin::mint_for_testing<IOTA>(10, ctx);
        bet::join1( coin,
        &oracle, ctx);
        ts::return_shared(oracle);
        scenario
    }

    public fun join2_test(mut scenario: Scenario): Scenario{
        scenario.next_tx(PLAYER1);
        assert!(ts::has_most_recent_shared<bet::Oracle>(), EEmptyInventory);
        let mut bet = scenario.take_shared<Bet<IOTA>>();
        let ctx = scenario.ctx();
        let cl = clock::create_for_testing(ctx);
        let coin = coin::mint_for_testing<IOTA>(10, ctx);
        bet::join2( &cl, coin,
         &mut bet, ctx);
        cl.destroy_for_testing();
        ts::return_shared(bet);
        scenario
    }

    fun win_test(winner: address, sender: address, clock: Clock, mut scenario: Scenario){
        scenario.next_tx(sender);
        assert!(ts::has_most_recent_shared<bet::Bet<IOTA>>(), EEmptyInventory);
        let bet = scenario.take_shared<bet::Bet<IOTA>>(); 
        let ctx = scenario.ctx();
        bet::win(bet, winner,&clock,ctx);
        clock.destroy_for_testing();
        scenario.end();
    }

    fun timeout_test(clock: Clock, mut scenario: Scenario){
        scenario.next_tx(PLAYER1);
        let bet = scenario.take_shared<bet::Bet<IOTA>>(); 
        let ctx = scenario.ctx();
        bet::timeout(bet, &clock,ctx);
        clock.destroy_for_testing();
        scenario.end();
    } 

    #[test]
    public fun intended_way(){
        let scenario = setup();

        let scenario = join1_test(scenario);
        let mut scenario = join2_test(scenario);

        let ctx = scenario.ctx();
        let cl = clock::create_for_testing(ctx);
        win_test(PLAYER1, ORACLE, cl, scenario);
    }


    #[test]
    public fun timeout(){
        let scenario = setup();
        
        let scenario = join1_test(scenario);
        let mut scenario = join2_test(scenario);
        
        let ctx = scenario.ctx();
        let mut cl = clock::create_for_testing(ctx);
        cl.increment_for_testing(600001);
        timeout_test(cl, scenario);
    }


    #[test, expected_failure(abort_code = bet::EOverTimeLimit)]
    public fun set_winner_over_time(){
        let scenario = setup();

        let scenario = join1_test(scenario);
        let mut scenario = join2_test(scenario);
        let ctx = scenario.ctx();
        let mut clock = clock::create_for_testing(ctx);
        clock.increment_for_testing(600001);
        win_test(PLAYER1, ORACLE, clock, scenario) 
    }


    #[test, expected_failure(abort_code = bet::EPermissionDenied)]
    public fun permission_denied_win(){
        let scenario = setup();
        
        let scenario = join1_test(scenario);
        let mut scenario = join2_test(scenario);
        let ctx = scenario.ctx();
        let clock = clock::create_for_testing(ctx);
        
        win_test(PLAYER1, PLAYER2, clock, scenario)
    }

    #[test, expected_failure( abort_code = bet::EWinnerNotPlayer)]
    public fun winner_not_player(){
        let scenario = setup();
        
        let scenario = join1_test(scenario);
        let mut scenario = join2_test(scenario);
        let ctx = scenario.ctx();
        let clock = clock::create_for_testing(ctx);

        win_test(ORACLE, ORACLE, clock, scenario)
    }

    #[test, expected_failure(abort_code = bet::ETimeIsNotFinish)]
    public fun timeout_before_finish(){
        
        let scenario = setup();
        
        let scenario = join1_test(scenario);
        let mut scenario = join2_test(scenario);
        let ctx = scenario.ctx();
        let clock = clock::create_for_testing(ctx);

        timeout_test(clock, scenario);
    }
}

