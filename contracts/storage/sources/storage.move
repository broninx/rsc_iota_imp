module storage::storage;

public struct Storage has key {
    id: UID,
    byte_sequences: vector<u8>,
    string: vector<u8>
}

public fun initialize(ctx: &mut TxContext){
    let storage = Storage {
        id: object::new(ctx),
        byte_sequences: vector::empty<u8>(),
        string: vector::empty<u8>()
    };
    transfer::share_object(storage);
}

public fun storeBytes(storage: &mut Storage, byte_sequences: vector<u8>){
    storage.byte_sequences = byte_sequences;
}

public fun storeString(storage: &mut Storage, string: vector<u8>){
    storage.string = string;
}

#[test_only]
public fun init_test(ctx: &mut TxContext){
    let storage = Storage {
        id: object::new(ctx),
        byte_sequences: vector::empty<u8>(),
        string: vector::empty<u8>()
    };
    transfer::share_object(storage);
}