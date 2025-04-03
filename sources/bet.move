module rsc_iota_imp::bet;

  use iota::coin;
  use iota::clock::{Clock, timestamp_ms};
  use iota::balance;

  // unit of measurement in milliseconds
  const DEADLINE: u64 = 200000;

    
  public struct Bet<phantom T> has key {
      id: UID,
      amount: coin::Coin<T>,// need better understand
      player1: address,
      player2: address,
      oracle: address,
      end_time: u64
    }

  public entry fun join<T> (clock: &Clock, wager: u64, p1: address, p2: address, o: address, ctx: &mut TxContext){
      let bet = Bet<T>{
          id: object::new(ctx),
          amount: coin::zero(ctx),//todo
          player1: p1,
          player2: p2,
          oracle: o,
          end_time: timestamp_ms(clock) + DEADLINE
        };
      //transfer something (see better also transfer module) ?
    }
  
  public fun win() {
      //TODO
    }

