module candymachine::candy_machine {
    use std::signer;
    use std::vector;
    use std::error;
    use std::bcs;
    use std::hash;
    use std::signer::address_of;

    use aptos_std::from_bcs;
    use aptos_framework::account;
    use aptos_framework::timestamp;
    use aptos_framework::transaction_context;
    use aptos_framework::account::SignerCapability;
    use aptos_framework::coin;
    use aptos_framework::event;

    friend candymachine::candy_machine_of_token_data_id;

    #[test_only]
    friend candymachine::create_collection_tests;
    #[test_only]
    friend candymachine::create_candy_machine_tests;
    #[test_only]
    friend candymachine::create_token_tests;
    #[test_only]
    friend candymachine::mint_token_tests;
    #[test_only]
    friend candymachine::update_sell_price_tests;
    #[test_only]
    friend candymachine::random_tests;

    const CANDY_MACHINE_STATE_INITIAL: u8 = 0;
    const CANDY_MACHINE_STATE_ACTIVE: u8 = 1;
    const CANDY_MACHINE_STATE_IDLE: u8 = 2;
    const CANDY_MACHINE_STATE_FINAL: u8 = 3;

    struct CandyMachine<phantom CoinType, CandyType: store> has key {
        creator: address,
        resource_signer_cap: SignerCapability,
        candies: vector<CandyType>,
        sell_price: u64,
        left_amount_of_candy: u64,
        state: u8
    }

    struct CandyMachineCreateEvent has drop, store {
        candy_machine_address: address
    }

    struct CandyMachineOwner has key {
        candy_machine_create_events: event::EventHandle<CandyMachineCreateEvent>,
    }

    const CANDY_MACHINE_NOT_EXISTS: u64 = 10;
    const ONLY_CREATOR_PERMITTED: u64 = 11;
    const FAILED_WHEN_RANDOMIZING: u64 = 12;
    const CANDY_MACHINE_INVALID_STATE: u64 = 13;
    const THERE_IS_NO_CANDIES: u64 = 14;
    const SOLD_OUT: u64 = 15;

    public(friend) fun create_candy_machine<CoinType, CandyType: store>(
        account: &signer,
        seed: vector<u8>
    ): address acquires CandyMachineOwner {
        let (_, resource_signer_cap) = account::create_resource_account(account, seed);
        let resource_signer_from_cap: signer = account::create_signer_with_capability(&resource_signer_cap);

        let candies: vector<CandyType> = vector::empty<CandyType>();
        let creator: address = signer::address_of(account);
        let left_amount_of_candy: u64 = 0;
        let state: u8 = CANDY_MACHINE_STATE_INITIAL;
        let sell_price: u64 = 1; // initial price

        let candy_machine: CandyMachine<CoinType, CandyType> = CandyMachine<CoinType, CandyType> {
            creator, resource_signer_cap,
            candies, sell_price, left_amount_of_candy, state
        };

        move_to<CandyMachine<CoinType, CandyType>>(&resource_signer_from_cap, candy_machine);
        coin::register<CoinType>(&resource_signer_from_cap);

        let candy_machine_address: address = signer::address_of(&resource_signer_from_cap);

        if (!exists<CandyMachineOwner>(creator)) {
            let candy_machine_owner: CandyMachineOwner = CandyMachineOwner {
                candy_machine_create_events: account::new_event_handle<CandyMachineCreateEvent>(account),
            };

            move_to(account, candy_machine_owner);
        };

        let candy_machine_owner: &mut CandyMachineOwner = borrow_global_mut<CandyMachineOwner>(creator);
        let candy_machine_create_event: CandyMachineCreateEvent = CandyMachineCreateEvent {
            candy_machine_address: copy candy_machine_address,
        };
        event::emit_event(&mut candy_machine_owner.candy_machine_create_events, candy_machine_create_event);

        return candy_machine_address
    }

    public(friend) fun check_candy_machine_exists<CoinType, CandyType: store>(candy_machine_address: address) {
        let exists: bool = exists<CandyMachine<CoinType, CandyType>>(candy_machine_address);
        assert!(exists, error::not_found(CANDY_MACHINE_NOT_EXISTS));
    }

    public(friend) fun check_candy_machine_creator<CoinType, CandyType: store>(
        candy_machine_address: address,
        address: address
    ) acquires CandyMachine {
        let creator: address = Self::get_candy_machine_creator<CoinType, CandyType>(candy_machine_address);
        assert!(creator == address, error::permission_denied(ONLY_CREATOR_PERMITTED));
    }

    public(friend) fun get_candy_machine_creator<CoinType, CandyType: store>(
        candy_machine_address: address
    ): address acquires CandyMachine {
        let candy_machine: &CandyMachine<CoinType, CandyType> = borrow_global<CandyMachine<CoinType, CandyType>>(
            candy_machine_address
        );
        candy_machine.creator
    }

    public(friend) fun borrow_resource_signer_from_cap<CoinType, CandyType: store>(
        candy_machine_address: address
    ): signer acquires CandyMachine {
        let candy_machine: &CandyMachine<CoinType, CandyType> = borrow_global<CandyMachine<CoinType, CandyType>>(
            candy_machine_address
        );
        let resource_signer_from_cap: signer = account::create_signer_with_capability(
            &candy_machine.resource_signer_cap
        );

        return resource_signer_from_cap
    }

    public(friend) fun get_left_amount_of_candy<CoinType, CandyType: store>(
        candy_machine_address: address
    ): u64 acquires CandyMachine {
        let candy_machine: &CandyMachine<CoinType, CandyType> = borrow_global<CandyMachine<CoinType, CandyType>>(
            candy_machine_address
        );
        candy_machine.left_amount_of_candy
    }

    public(friend) fun get_sell_price_of_candy<CoinType, CandyType: store>(
        candy_machine_address: address
    ): u64 acquires CandyMachine {
        let candy_machine: &CandyMachine<CoinType, CandyType> = borrow_global<CandyMachine<CoinType, CandyType>>(
            candy_machine_address
        );
        candy_machine.sell_price
    }

    public(friend) fun create_candy<CoinType, CandyType: store>(
        candy_machine_address: address, candy: CandyType
    ) acquires CandyMachine {
        let candy_machine: &mut CandyMachine<CoinType, CandyType> = borrow_global_mut<CandyMachine<CoinType, CandyType>>(
            candy_machine_address
        );
        assert!(candy_machine.state == CANDY_MACHINE_STATE_INITIAL, error::invalid_state(CANDY_MACHINE_INVALID_STATE));

        vector::push_back(&mut candy_machine.candies, candy);

        candy_machine.left_amount_of_candy = candy_machine.left_amount_of_candy + 1;
    }

    public(friend) fun start<CoinType, CandyType: store>(candy_machine_address: address) acquires CandyMachine {
        let candy_machine: &mut CandyMachine<CoinType, CandyType> = borrow_global_mut<CandyMachine<CoinType, CandyType>>(
            candy_machine_address
        );
        assert!(candy_machine.state == CANDY_MACHINE_STATE_INITIAL, error::invalid_state(CANDY_MACHINE_INVALID_STATE));

        let amount_of_candy: u64 = vector::length(&candy_machine.candies);
        assert!(amount_of_candy != 0, error::invalid_state(THERE_IS_NO_CANDIES));

        candy_machine.state = CANDY_MACHINE_STATE_ACTIVE;
    }

    public(friend) fun update_sell_price_of_candy<CoinType, CandyType: store>(
        candy_machine_address: address,
        sell_price: u64
    ) acquires CandyMachine {
        let candy_machine: &mut CandyMachine<CoinType, CandyType> = borrow_global_mut<CandyMachine<CoinType, CandyType>>(
            candy_machine_address
        );
        assert!(candy_machine.state == CANDY_MACHINE_STATE_INITIAL, error::invalid_state(CANDY_MACHINE_INVALID_STATE));

        candy_machine.sell_price = sell_price;
    }

    public(friend) fun pause<CoinType, CandyType: store>(candy_machine_address: address) acquires CandyMachine {
        let candy_machine: &mut CandyMachine<CoinType, CandyType> = borrow_global_mut<CandyMachine<CoinType, CandyType>>(
            candy_machine_address
        );
        assert!(candy_machine.state == CANDY_MACHINE_STATE_ACTIVE, error::invalid_state(CANDY_MACHINE_INVALID_STATE));

        candy_machine.state = CANDY_MACHINE_STATE_IDLE;
    }

    public(friend) fun resume<CoinType, CandyType: store>(candy_machine_address: address) acquires CandyMachine {
        let candy_machine: &mut CandyMachine<CoinType, CandyType> = borrow_global_mut<CandyMachine<CoinType, CandyType>>(
            candy_machine_address
        );
        assert!(candy_machine.state == CANDY_MACHINE_STATE_IDLE, error::invalid_state(CANDY_MACHINE_INVALID_STATE));

        candy_machine.state = CANDY_MACHINE_STATE_ACTIVE;
    }

    public(friend) fun terminate<CoinType, CandyType: store>(candy_machine_address: address) acquires CandyMachine {
        let candy_machine: &mut CandyMachine<CoinType, CandyType> = borrow_global_mut<CandyMachine<CoinType, CandyType>>(
            candy_machine_address
        );
        let state: u8 = candy_machine.state;
        assert!(
            state == CANDY_MACHINE_STATE_ACTIVE || state == CANDY_MACHINE_STATE_IDLE,
            error::invalid_state(CANDY_MACHINE_INVALID_STATE)
        );

        candy_machine.state = CANDY_MACHINE_STATE_FINAL;
    }

    public(friend) fun insert_coin<CoinType, CandyType: store>(
        account: &signer,
        candy_machine_address: address
    ) acquires CandyMachine {
        let candy_machine: & CandyMachine<CoinType, CandyType> = borrow_global<CandyMachine<CoinType, CandyType>>(
            candy_machine_address
        );
        coin::transfer<CoinType>(account, candy_machine_address, candy_machine.sell_price);
    }

    public(friend) fun withdraw<CoinType, CandyType: store>(
        account: &signer,
        candy_machine_address: address
    ) acquires CandyMachine {
        let address: address = address_of(account);
        check_candy_machine_creator<CoinType, CandyType>(candy_machine_address, address);

        let resource_signer_from_cap: signer = borrow_resource_signer_from_cap<CoinType, CandyType>(
            candy_machine_address
        );
        let balance: u64 = coin::balance<CoinType>(candy_machine_address);

        coin::transfer<CoinType>(&resource_signer_from_cap, address, balance);
    }

    public(friend) fun pull_lever<CoinType, CandyType: copy + store>(
        candy_machine_address: address
    ): CandyType acquires CandyMachine {
        let candy_machine: &mut CandyMachine<CoinType, CandyType> = borrow_global_mut<CandyMachine<CoinType, CandyType>>(
            candy_machine_address
        );
        assert!(candy_machine.state == CANDY_MACHINE_STATE_ACTIVE, error::invalid_state(CANDY_MACHINE_INVALID_STATE));

        let amount_of_candy: u64 = vector::length(&candy_machine.candies);
        let left_amount_of_candy: u64 = candy_machine.left_amount_of_candy;

        // unnecessary code
        assert!(left_amount_of_candy != 0, error::invalid_state(SOLD_OUT));

        let lucky_index: u64 = pseudo_random(
            candy_machine_address,
            amount_of_candy + left_amount_of_candy,
            left_amount_of_candy
        );
        let last_index_of_lefts: u64 = left_amount_of_candy - 1;

        vector::swap<CandyType>(&mut candy_machine.candies, lucky_index, last_index_of_lefts);
        candy_machine.left_amount_of_candy = left_amount_of_candy - 1;

        let luck_candy: &CandyType = vector::borrow<CandyType>(&candy_machine.candies, last_index_of_lefts);
        let result: CandyType = *luck_candy;

        if (candy_machine.left_amount_of_candy == 0) {
            candy_machine.state = CANDY_MACHINE_STATE_FINAL
        };

        result
    }

    public(friend) fun pseudo_random(add: address, random_number: u64, max: u64): u64 {
        assert!(max > 0, FAILED_WHEN_RANDOMIZING);

        let x: vector<u8> = bcs::to_bytes<address>(&add);
        let y: vector<u8> = bcs::to_bytes<u64>(&random_number);
        let z: vector<u8> = bcs::to_bytes<u64>(&timestamp::now_microseconds());
        let script_hash: vector<u8> = transaction_context::get_script_hash();

        vector::append(&mut x, y);
        vector::append(&mut x, z);
        vector::append(&mut x, script_hash);

        let tmp: vector<u8> = hash::sha2_256(x);
        let data: vector<u8> = vector<u8>[];
        let i: u64 = 24;
        while (i < 32) {
            let x: &u8 = vector::borrow(&tmp, i);
            vector::append(&mut data, vector<u8>[*x]);
            i = i + 1;
        };

        let random: u64 = from_bcs::to_u64(data) % max;
        random
    }
}
