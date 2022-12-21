module candymachine::candy_machine_of_token_data_id {
    use std::signer;
    use std::error;
    use std::string::String;

    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_token::token;
    use aptos_token::token::{TokenMutabilityConfig, TokenDataId};

    use candymachine::candy_machine;
    use std::vector;
    use std::signer::address_of;
    use aptos_framework::event;
    use aptos_framework::account;
    use std::string;

    #[test_only]
    friend candymachine::create_candy_machine_tests;
    #[test_only]
    friend candymachine::create_collection_tests;

    const INVALID_TOKEN_MAXIMUM_VALUE: u64 = 100;
    const ONLY_MODULE_ACCOUNT_PERMITTED: u64 = 101;

    struct CreateCandyMachineEvent has drop, store {
        creator: address,
        candy_machine_address: address
    }

    struct MintEvent has drop, store {
        minter: address,
        candy_machine_address: address,
        token_data_id: TokenDataId,
        price: u64
    }

    struct CandyMachineEvents has key {
        create_candy_machine_events: event::EventHandle<CreateCandyMachineEvent>,
        mint_events: event::EventHandle<MintEvent>,
    }

    public entry fun initialize(
        module_account: &signer
    ) {
        let module_address: address = address_of(module_account);
        assert!(module_address == @candymachine, error::permission_denied(ONLY_MODULE_ACCOUNT_PERMITTED));

        if (!exists<CandyMachineEvents>(module_address)) {
            let candy_machine_events: CandyMachineEvents = CandyMachineEvents {
                create_candy_machine_events: account::new_event_handle<CreateCandyMachineEvent>(module_account),
                mint_events: account::new_event_handle<MintEvent>(module_account),
            };

            move_to(module_account, candy_machine_events);
        };
    }

    public entry fun create_candy_machine(account: &signer, seed: vector<u8>) acquires CandyMachineEvents {
        let candy_machine_address = candy_machine::create_candy_machine<AptosCoin, TokenDataId>(account, seed);

        let creator: address = address_of(account);
        let candy_machine_events: &mut CandyMachineEvents = borrow_global_mut<CandyMachineEvents>(@candymachine);
        let create_candy_machine_event: CreateCandyMachineEvent = CreateCandyMachineEvent {
            creator,
            candy_machine_address: copy candy_machine_address,
        };
        event::emit_event(&mut candy_machine_events.create_candy_machine_events, create_candy_machine_event);
    }

    public entry fun create_collection(account: &signer, candy_machine_address: address,
                                       collection_name: String,
                                       collection_description: String,
                                       collection_uri: String,
                                       collection_maximum: u64,
                                       collection_mutate_setting: vector<bool>
    ) {
        candy_machine::check_candy_machine_exists<AptosCoin, TokenDataId>(candy_machine_address);

        let signer_address: address = signer::address_of(account);
        candy_machine::check_candy_machine_creator<AptosCoin, TokenDataId>(candy_machine_address, signer_address);

        let resource_signer_from_cap: signer = candy_machine::borrow_resource_signer_from_cap<AptosCoin, TokenDataId>(
            candy_machine_address
        );

        let _ = collection_mutate_setting;

        token::create_collection(
            &resource_signer_from_cap,
            collection_name,
            collection_description,
            collection_uri,
            collection_maximum,
            vector<bool>[false, false, false] // forcing to false
        );
    }

    public entry fun create_tokens_of_offchain_bulk(account: &signer, candy_machine_address: address,
                                                    collection_name: String,
                                                    token_base_name: String,
                                                    token_common_description: String,
                                                    token_base_uri: String,
                                                    token_base_uri_start_index: u64,
                                                    token_base_uri_finish_index: u64,
                                                    token_royalty_payee_address: address,
                                                    token_royalty_points_denominator: u64,
                                                    token_royalty_points_numerator: u64,
    ) {
        let (_account, _candy_machine_address,
            _collection_name,
            _token_base_name,
            _token_common_description,
            _token_base_uri,
            _token_base_uri_start_index,
            _token_base_uri_finish_index,
            _token_royalty_payee_address,
            _token_royalty_points_denominator,
            _token_royalty_points_numerator
        ) = (account, candy_machine_address,
            collection_name,
            token_base_name,
            token_common_description,
            token_base_uri,
            token_base_uri_start_index,
            token_base_uri_finish_index,
            token_royalty_payee_address,
            token_royalty_points_denominator,
            token_royalty_points_numerator
        );
    }

    public entry fun create_tokens_from_base(account: &signer, candy_machine_address: address,
                                             collection_name: String,
                                             token_base_name: String,
                                             token_common_description: String,
                                             token_base_uri: String,
                                             token_base_uri_suffix: String,
                                             token_base_uri_start_index: u64,
                                             token_base_uri_finish_index: u64,
                                             token_royalty_payee_address: address,
                                             token_royalty_points_denominator: u64,
                                             token_royalty_points_numerator: u64,
    ) {
        candy_machine::check_candy_machine_exists<AptosCoin, TokenDataId>(candy_machine_address);

        let signer_address: address = signer::address_of(account);
        candy_machine::check_candy_machine_creator<AptosCoin, TokenDataId>(candy_machine_address, signer_address);

        let resource_signer_from_cap: signer = candy_machine::borrow_resource_signer_from_cap<AptosCoin, TokenDataId>(
            candy_machine_address
        );

        let empty_string_vector = vector::empty<String>();
        let empty_vector_u8_vector = vector::empty<vector<u8>>();

        let default_token_mutate_setting = vector<bool>[false, false, false, false, false]; // forcing to false
        let token_mutate_config: TokenMutabilityConfig = token::create_token_mutability_config(
            &default_token_mutate_setting
        );

        let length: u64 = token_base_uri_finish_index - token_base_uri_start_index + 1;
        let i = 0;

        while (i < length) {
            let token_name: &mut String = &mut copy token_base_name;
            string::append(token_name, num_str(token_base_uri_start_index + i));

            let token_maximum: u64 = 1;
            let token_uri: &mut String = &mut copy token_base_uri;

            string::append(token_uri, num_str(token_base_uri_start_index + i));
            string::append(token_uri, token_base_uri_suffix);

            let token_data_id: TokenDataId = token::create_tokendata(
                &resource_signer_from_cap,
                collection_name,
                *token_name,
                token_common_description,
                token_maximum, // maximum = 0 = unlimited
                *token_uri,
                token_royalty_payee_address,
                token_royalty_points_denominator,
                token_royalty_points_numerator,
                token_mutate_config,
                empty_string_vector,
                empty_vector_u8_vector,
                empty_string_vector
            );

            candy_machine::create_candy<AptosCoin, TokenDataId>(candy_machine_address, token_data_id);

            i = i + 1;
        }
    }

    public entry fun create_tokens_bulk(account: &signer, candy_machine_address: address,
                                        collection_name_all: vector<String>,
                                        token_name_all: vector<String>,
                                        token_description_all: vector<String>,
                                        token_maximum_all: vector<u64>,
                                        token_uri_all: vector<String>,
                                        token_royalty_payee_address_all: vector<address>,
                                        token_royalty_points_denominator_all: vector<u64>,
                                        token_royalty_points_numerator_all: vector<u64>,
                                        token_property_keys_all: vector<vector<String>>,
                                        token_property_values_all: vector<vector<vector<u8>>>,
                                        token_property_types_all: vector<vector<String>>,
                                        token_mutate_setting_all: vector<vector<bool>>
    ) {
        let length: u64 = vector::length(&token_uri_all);
        let i = 0;
        while (i < length) {
            let collection_name = *vector::borrow<String>(&collection_name_all, i);
            let token_name = *vector::borrow<String>(&token_name_all, i);
            let token_description = *vector::borrow<String>(&token_description_all, i);
            let token_maximum = *vector::borrow<u64>(&token_maximum_all, i);
            let token_uri = *vector::borrow<String>(&token_uri_all, i);
            let token_royalty_payee_address = *vector::borrow<address>(&token_royalty_payee_address_all, i);
            let token_royalty_points_denominator = *vector::borrow<u64>(&token_royalty_points_denominator_all, i);
            let token_royalty_points_numerator = *vector::borrow<u64>(&token_royalty_points_numerator_all, i);
            let token_property_keys = *vector::borrow<vector<String>>(&token_property_keys_all, i);
            let token_property_values = *vector::borrow<vector<vector<u8>>>(&token_property_values_all, i);
            let token_property_types = *vector::borrow<vector<String>>(&token_property_types_all, i);
            let token_mutate_setting = *vector::borrow<vector<bool>>(&token_mutate_setting_all, i);

            create_token(account, candy_machine_address,
                collection_name,
                token_name,
                token_description,
                token_maximum,
                token_uri,
                token_royalty_payee_address,
                token_royalty_points_denominator,
                token_royalty_points_numerator,
                token_property_keys,
                token_property_values,
                token_property_types,
                token_mutate_setting
            );

            i = i + 1;
        }
    }

    public entry fun create_token(account: &signer, candy_machine_address: address,
                                  collection_name: String,
                                  token_name: String,
                                  token_description: String,
                                  token_maximum: u64,
                                  token_uri: String,
                                  token_royalty_payee_address: address,
                                  token_royalty_points_denominator: u64,
                                  token_royalty_points_numerator: u64,
                                  token_property_keys: vector<String>,
                                  token_property_values: vector<vector<u8>>,
                                  token_property_types: vector<String>,
                                  token_mutate_setting: vector<bool>
    ) {
        candy_machine::check_candy_machine_exists<AptosCoin, TokenDataId>(candy_machine_address);

        let signer_address: address = signer::address_of(account);
        candy_machine::check_candy_machine_creator<AptosCoin, TokenDataId>(candy_machine_address, signer_address);

        assert!(token_maximum != 0, error::invalid_argument(INVALID_TOKEN_MAXIMUM_VALUE));

        let resource_signer_from_cap: signer = candy_machine::borrow_resource_signer_from_cap<AptosCoin, TokenDataId>(
            candy_machine_address
        );

        let _ = token_mutate_setting;

        let default_token_mutate_setting = vector<bool>[false, false, false, false, false]; // forcing to false
        let token_mutate_config: TokenMutabilityConfig = token::create_token_mutability_config(
            &default_token_mutate_setting
        );

        let token_data_id: TokenDataId = token::create_tokendata(
            &resource_signer_from_cap,
            collection_name,
            token_name,
            token_description,
            token_maximum, // maximum = 0 = unlimited
            token_uri,
            token_royalty_payee_address,
            token_royalty_points_denominator,
            token_royalty_points_numerator,
            token_mutate_config,
            token_property_keys,
            token_property_values,
            token_property_types
        );

        let i = 1;
        while (i <= token_maximum) {
            candy_machine::create_candy<AptosCoin, TokenDataId>(candy_machine_address, token_data_id);
            i = i + 1;
        };
    }

    public entry fun mint(account: &signer, candy_machine_address: address) acquires CandyMachineEvents {
        candy_machine::check_candy_machine_exists<AptosCoin, TokenDataId>(candy_machine_address);

        candy_machine::insert_coin<AptosCoin, TokenDataId>(account, candy_machine_address);
        let lucky_token_data_id: TokenDataId = candy_machine::pull_lever<AptosCoin, TokenDataId>(candy_machine_address);
        let resource_signer_from_cap: signer = candy_machine::borrow_resource_signer_from_cap<AptosCoin, TokenDataId>(
            candy_machine_address
        );

        let receiver_address: address = signer::address_of(account);
        token::opt_in_direct_transfer(account, true);
        token::mint_token_to(&resource_signer_from_cap, receiver_address, lucky_token_data_id, 1);
        // FIXME: old_value = get_direct_transfer
        // token::opt_in_direct_transfer(account,old_value);

        let sell_price_of_candy: u64 = candy_machine::get_sell_price_of_candy<AptosCoin, TokenDataId>(
            candy_machine_address
        );
        let candy_machine_events: &mut CandyMachineEvents = borrow_global_mut<CandyMachineEvents>(@candymachine);
        let mint_event: MintEvent = MintEvent {
            minter: copy receiver_address,
            candy_machine_address: copy candy_machine_address,
            token_data_id: lucky_token_data_id,
            price: sell_price_of_candy
        };

        event::emit_event(&mut candy_machine_events.mint_events, mint_event);
    }

    public entry fun update_sell_price(account: &signer, candy_machine_address: address, sell_price: u64) {
        candy_machine::check_candy_machine_exists<AptosCoin, TokenDataId>(candy_machine_address);

        let signer_address: address = signer::address_of(account);
        candy_machine::check_candy_machine_creator<AptosCoin, TokenDataId>(candy_machine_address, signer_address);

        candy_machine::update_sell_price_of_candy<AptosCoin, TokenDataId>(candy_machine_address, sell_price);
    }

    public entry fun start(account: &signer, candy_machine_address: address) {
        candy_machine::check_candy_machine_exists<AptosCoin, TokenDataId>(candy_machine_address);

        let signer_address: address = signer::address_of(account);
        candy_machine::check_candy_machine_creator<AptosCoin, TokenDataId>(candy_machine_address, signer_address);

        candy_machine::start<AptosCoin, TokenDataId>(candy_machine_address);
    }

    public entry fun pause(account: &signer, candy_machine_address: address) {
        candy_machine::check_candy_machine_exists<AptosCoin, TokenDataId>(candy_machine_address);

        let signer_address: address = signer::address_of(account);
        candy_machine::check_candy_machine_creator<AptosCoin, TokenDataId>(candy_machine_address, signer_address);

        candy_machine::pause<AptosCoin, TokenDataId>(candy_machine_address);
    }

    public entry fun resume(account: &signer, candy_machine_address: address) {
        candy_machine::check_candy_machine_exists<AptosCoin, TokenDataId>(candy_machine_address);

        let signer_address: address = signer::address_of(account);
        candy_machine::check_candy_machine_creator<AptosCoin, TokenDataId>(candy_machine_address, signer_address);

        candy_machine::resume<AptosCoin, TokenDataId>(candy_machine_address);
    }

    public entry fun terminate(account: &signer, candy_machine_address: address) {
        candy_machine::check_candy_machine_exists<AptosCoin, TokenDataId>(candy_machine_address);

        let signer_address: address = signer::address_of(account);
        candy_machine::check_candy_machine_creator<AptosCoin, TokenDataId>(candy_machine_address, signer_address);

        candy_machine::terminate<AptosCoin, TokenDataId>(candy_machine_address);
    }

    public entry fun withdraw(account: &signer, candy_machine_address: address) {
        candy_machine::check_candy_machine_exists<AptosCoin, TokenDataId>(candy_machine_address);

        candy_machine::withdraw<AptosCoin, TokenDataId>(account, candy_machine_address);
    }

    fun num_str(num: u64): String
    {
        let v1 = vector::empty();
        while (num / 10 > 0) {
            let rem = num % 10;
            vector::push_back(&mut v1, (rem + 48 as u8));
            num = num / 10;
        };
        vector::push_back(&mut v1, (num + 48 as u8));
        vector::reverse(&mut v1);
        string::utf8(v1)
    }
}