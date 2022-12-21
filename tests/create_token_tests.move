#[test_only]
module candymachine::create_token_tests {
    use std::string::String;
    use std::string;
    use std::bcs;
    use std::vector;
    use std::unit_test;

    use aptos_framework::util::address_from_bytes;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_token::token::TokenDataId;

    use candymachine::candy_machine_of_token_data_id::{create_token, start, pause, resume, terminate};
    use candymachine::create_candy_machine_tests::{get_account, create_candy_machine_test};
    use candymachine::create_collection_tests::create_collection_test;
    use candymachine::candy_machine;

    const WRONG_LEFT_AMOUNT_OF_CANDY: u64 = 96;

    #[test(aptos_framework = @0x1, module_owner = @candymachine)]
    #[expected_failure(abort_code = 393226)]
    fun create_token_without_candy_machine(aptos_framework: &signer, module_owner: &signer) {
        let account = get_account(aptos_framework, module_owner);
        let invalid_candy_machine_address: address = address_from_bytes(
            x"0000000000000000000000000000000000000000000000000000000000000001"
        );

        create_token_test(&account, invalid_candy_machine_address, string::utf8(b"1"));
    }

    #[test(aptos_framework = @0x1, module_owner = @candymachine)]
    #[expected_failure(abort_code = 327691)]
    fun create_token_without_owner(aptos_framework: &signer, module_owner: &signer) {
        let account = get_account(aptos_framework, module_owner);
        let candy_machine_address = create_candy_machine_test(&account);
        create_collection_test(&account, candy_machine_address);

        let another_account = vector::borrow(&mut unit_test::create_signers_for_testing(2), 1);
        create_token_test(another_account, candy_machine_address, string::utf8(b"1"));
    }

    #[test(aptos_framework = @0x1, module_owner = @candymachine)]
    fun create_one_token_after_all_test(aptos_framework: &signer, module_owner: &signer) {
        let account = get_account(aptos_framework, module_owner);
        let candy_machine_address = create_candy_machine_test(&account);

        create_collection_test(&account, candy_machine_address);
        create_token_test(&account, candy_machine_address, string::utf8(b"1"));

        let left_amount_of_candy = candy_machine::get_left_amount_of_candy<AptosCoin, TokenDataId>(
            candy_machine_address
        );
        assert!(left_amount_of_candy == 1, WRONG_LEFT_AMOUNT_OF_CANDY);
    }

    #[test(aptos_framework = @0x1, module_owner = @candymachine)]
    fun create_three_token_after_all_test(aptos_framework: &signer, module_owner: &signer) {
        let account = get_account(aptos_framework, module_owner);
        let candy_machine_address = create_candy_machine_test(&account);

        let left_amount_of_candy = candy_machine::get_left_amount_of_candy<AptosCoin, TokenDataId>(
            candy_machine_address
        );
        assert!(left_amount_of_candy == 0, WRONG_LEFT_AMOUNT_OF_CANDY);

        create_tokens_after_all(&account, candy_machine_address, 3);

        let left_amount_of_candy = candy_machine::get_left_amount_of_candy<AptosCoin, TokenDataId>(
            candy_machine_address
        );
        assert!(left_amount_of_candy == 3, WRONG_LEFT_AMOUNT_OF_CANDY);
    }

    #[test(aptos_framework = @0x1, module_owner = @candymachine)]
    #[expected_failure(abort_code = 65636)]
    fun create_token_that_s_limitless(aptos_framework: &signer, module_owner: &signer) {
        let account = get_account(aptos_framework, module_owner);
        let candy_machine_address = create_candy_machine_test(&account);

        create_collection_test(&account, candy_machine_address);
        create_token_test_with_maximum(&account, candy_machine_address, string::utf8(bcs::to_bytes<u64>(&1)), 0);
    }

    #[test(aptos_framework = @0x1, module_owner = @candymachine)]
    #[expected_failure(abort_code = 196621)]
    fun create_token_after_start(aptos_framework: &signer, module_owner: &signer) {
        let account = get_account(aptos_framework, module_owner);
        let candy_machine_address = create_candy_machine_test(&account);

        create_tokens_after_all(&account, candy_machine_address, 3);

        start(&account, candy_machine_address);

        let token_id: String = string::utf8(bcs::to_bytes<u64>(&99));
        create_token_test(&account, candy_machine_address, token_id);
    }

    #[test(aptos_framework = @0x1, module_owner = @candymachine)]
    #[expected_failure(abort_code = 196621)]
    fun create_token_after_pause(aptos_framework: &signer, module_owner: &signer) {
        let account = get_account(aptos_framework, module_owner);
        let candy_machine_address = create_candy_machine_test(&account);

        create_tokens_after_all(&account, candy_machine_address, 3);

        start(&account, candy_machine_address);
        pause(&account, candy_machine_address);

        let token_id: String = string::utf8(bcs::to_bytes<u64>(&99));
        create_token_test(&account, candy_machine_address, token_id);
    }

    #[test(aptos_framework = @0x1, module_owner = @candymachine)]
    #[expected_failure(abort_code = 196621)]
    fun create_token_after_resume(aptos_framework: &signer, module_owner: &signer) {
        let account = get_account(aptos_framework, module_owner);
        let candy_machine_address = create_candy_machine_test(&account);

        create_tokens_after_all(&account, candy_machine_address, 3);

        start(&account, candy_machine_address);
        pause(&account, candy_machine_address);
        resume(&account, candy_machine_address);

        let token_id: String = string::utf8(bcs::to_bytes<u64>(&99));
        create_token_test(&account, candy_machine_address, token_id);
    }

    #[test(aptos_framework = @0x1, module_owner = @candymachine)]
    #[expected_failure(abort_code = 196621)]
    fun create_token_after_terminate(aptos_framework: &signer, module_owner: &signer) {
        let account = get_account(aptos_framework, module_owner);
        let candy_machine_address = create_candy_machine_test(&account);

        create_tokens_after_all(&account, candy_machine_address, 3);

        start(&account, candy_machine_address);
        terminate(&account, candy_machine_address);

        let token_id: String = string::utf8(bcs::to_bytes<u64>(&99));
        create_token_test(&account, candy_machine_address, token_id);
    }

    public fun create_tokens_after_all(account: &signer, candy_machine_address: address, count: u64) {
        create_collection_test(account, candy_machine_address);
        let i = 1;

        while (i <= count) {
            let token_id = string::utf8(bcs::to_bytes<u64>(&i));
            create_token_test(account, candy_machine_address, token_id);
            i = i + 1;
        };

        let left_amount_of_candy = candy_machine::get_left_amount_of_candy<AptosCoin, TokenDataId>(
            candy_machine_address
        );
        assert!(left_amount_of_candy == count, WRONG_LEFT_AMOUNT_OF_CANDY);
    }

    public fun create_token_test(account: &signer, candy_machine_address: address, token_id: String) {
        create_token_test_with_maximum(account, candy_machine_address, token_id, 1);
    }

    public fun create_token_test_with_maximum(
        account: &signer,
        candy_machine_address: address,
        token_id: String,
        token_maximum: u64
    ) {
        let (collection_name, token_name, token_description, token_uri, token_royalty_payee_address,
            token_royalty_points_denominator, token_royalty_points_numerator, token_property_keys,
            token_property_values, token_property_types, token_mutate_setting) = build_create_token_request(token_id);

        create_token(
            account,
            candy_machine_address,
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
    }

    public fun build_create_token_request(
        token_id: String
    ): (String, String, String, String, address, u64, u64, vector<String>,
        vector<vector<u8>>, vector<String>, vector<bool>) {
        let collection_name = string::utf8(b"Candy Machines");
        let token_name = string::utf8(b"Candy Machine #");
        string::append(&mut token_name, token_id);
        let token_description: String = string::utf8(b"First candy machine token");
        let token_uri: String = string::utf8(b"candymachine.apt/1");
        let token_royalty_payee_address: address = address_from_bytes(
            x"0000000000000000000000000000000000000000000000000000000000000001"
        );
        let token_royalty_points_denominator: u64 = 100;
        let token_royalty_points_numerator: u64 = 100;
        let token_property_keys: vector<String> = vector<String>[string::utf8(b"rank")];
        let token_property_values: vector<vector<u8>> = vector<vector<u8>>[bcs::to_bytes<u64>(&10)];
        let token_property_types: vector<String> = vector<String>[string::utf8(b"u64")];
        let token_mutate_setting: vector<bool> = vector<bool>[false, false, false, false, false];

        (collection_name, token_name, token_description, token_uri, token_royalty_payee_address,
            token_royalty_points_denominator, token_royalty_points_numerator, token_property_keys,
            token_property_values, token_property_types, token_mutate_setting)
    }
}
