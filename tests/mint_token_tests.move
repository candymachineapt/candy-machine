#[test_only]
module candymachine::mint_token_tests {
    use std::bcs;
    use std::string;
    use std::signer;

    use aptos_framework::util::address_from_bytes;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::coin;
    use aptos_token::token::{TokenDataId, create_token_id};
    use aptos_token::token;

    use candymachine::candy_machine;
    use candymachine::create_token_tests;
    use candymachine::create_collection_tests::create_collection_test;
    use candymachine::create_token_tests::{create_token_test_with_maximum};
    use candymachine::candy_machine_of_token_data_id::{mint, start, pause, resume, terminate};
    use candymachine::create_candy_machine_tests::{get_account, create_candy_machine_test};

    const WRONG_LEFT_AMOUNT_OF_CANDY: u64 = 93;
    const HAS_NOT_RECEIVE_THE_TOKEN: u64 = 94;
    const WRONG_AMOUNT_OF_COIN: u64 = 95;

    #[test(aptos_framework = @0x1, module_owner = @candymachine)]
    #[expected_failure(abort_code = 393226)]
    fun mint_token_without_candy_machine(aptos_framework: &signer, module_owner: &signer) {
        let account = get_account(aptos_framework, module_owner);
        let invalid_candy_machine_address: address = address_from_bytes(
            x"0000000000000000000000000000000000000000000000000000000000000001"
        );

        mint(&account, invalid_candy_machine_address);
    }

    #[test(aptos_framework = @0x1, module_owner = @candymachine)]
    #[expected_failure(abort_code = 196621)]
    fun mint_one_token_after_all_without_start(aptos_framework: &signer, module_owner: &signer) {
        let account = get_account(aptos_framework, module_owner);
        let candy_machine_address = create_candy_machine_test(&account);

        create_token_tests::create_tokens_after_all(&account, candy_machine_address, 5);

        let left_amount_of_candy = candy_machine::get_left_amount_of_candy<AptosCoin, TokenDataId>(
            candy_machine_address
        );
        assert!(left_amount_of_candy == 5, WRONG_LEFT_AMOUNT_OF_CANDY);

        mint(&account, candy_machine_address);
    }

    #[test(aptos_framework = @0x1, module_owner = @candymachine)]
    #[expected_failure(abort_code = 196621)]
    fun mint_one_token_after_all_after_pause(aptos_framework: &signer, module_owner: &signer) {
        let account = get_account(aptos_framework, module_owner);
        let candy_machine_address = create_candy_machine_test(&account);

        create_token_tests::create_tokens_after_all(&account, candy_machine_address, 5);
        start(&account, candy_machine_address);

        let left_amount_of_candy = candy_machine::get_left_amount_of_candy<AptosCoin, TokenDataId>(
            candy_machine_address
        );
        assert!(left_amount_of_candy == 5, WRONG_LEFT_AMOUNT_OF_CANDY);

        mint(&account, candy_machine_address);

        let left_amount_of_candy = candy_machine::get_left_amount_of_candy<AptosCoin, TokenDataId>(
            candy_machine_address
        );
        assert!(left_amount_of_candy == 4, WRONG_LEFT_AMOUNT_OF_CANDY);

        pause(&account, candy_machine_address);
        mint(&account, candy_machine_address);
    }

    #[test(aptos_framework = @0x1, module_owner = @candymachine)]
    fun mint_one_token_after_all_after_resume(aptos_framework: &signer, module_owner: &signer) {
        let account = get_account(aptos_framework, module_owner);
        let candy_machine_address = create_candy_machine_test(&account);

        create_token_tests::create_tokens_after_all(&account, candy_machine_address, 5);
        start(&account, candy_machine_address);

        let left_amount_of_candy = candy_machine::get_left_amount_of_candy<AptosCoin, TokenDataId>(
            candy_machine_address
        );
        assert!(left_amount_of_candy == 5, WRONG_LEFT_AMOUNT_OF_CANDY);

        mint(&account, candy_machine_address);

        let left_amount_of_candy = candy_machine::get_left_amount_of_candy<AptosCoin, TokenDataId>(
            candy_machine_address
        );
        assert!(left_amount_of_candy == 4, WRONG_LEFT_AMOUNT_OF_CANDY);

        pause(&account, candy_machine_address);
        resume(&account, candy_machine_address);
        mint(&account, candy_machine_address);

        let left_amount_of_candy = candy_machine::get_left_amount_of_candy<AptosCoin, TokenDataId>(
            candy_machine_address
        );
        assert!(left_amount_of_candy == 3, WRONG_LEFT_AMOUNT_OF_CANDY);
    }

    #[test(aptos_framework = @0x1, module_owner = @candymachine)]
    #[expected_failure(abort_code = 196621)]
    fun mint_one_token_after_all_after_terminate(aptos_framework: &signer, module_owner: &signer) {
        let account = get_account(aptos_framework, module_owner);
        let candy_machine_address = create_candy_machine_test(&account);

        create_token_tests::create_tokens_after_all(&account, candy_machine_address, 5);
        start(&account, candy_machine_address);

        let left_amount_of_candy = candy_machine::get_left_amount_of_candy<AptosCoin, TokenDataId>(
            candy_machine_address
        );
        assert!(left_amount_of_candy == 5, WRONG_LEFT_AMOUNT_OF_CANDY);

        terminate(&account, candy_machine_address);
        mint(&account, candy_machine_address);
    }

    #[test(aptos_framework = @0x1, module_owner = @candymachine)]
    fun mint_one_token_after_all(aptos_framework: &signer, module_owner: &signer) {
        let account = get_account(aptos_framework, module_owner);
        let candy_machine_address = create_candy_machine_test(&account);

        create_token_tests::create_tokens_after_all(&account, candy_machine_address, 5);
        start(&account, candy_machine_address);

        let left_amount_of_candy = candy_machine::get_left_amount_of_candy<AptosCoin, TokenDataId>(
            candy_machine_address
        );
        assert!(left_amount_of_candy == 5, WRONG_LEFT_AMOUNT_OF_CANDY);

        mint(&account, candy_machine_address);

        let left_amount_of_candy = candy_machine::get_left_amount_of_candy<AptosCoin, TokenDataId>(
            candy_machine_address
        );
        assert!(left_amount_of_candy == 4, WRONG_LEFT_AMOUNT_OF_CANDY);
    }

    #[test(aptos_framework = @0x1, module_owner = @candymachine)]
    fun mint_one_token_and_receive_it(aptos_framework: &signer, module_owner: &signer) {
        let account = get_account(aptos_framework, module_owner);
        let candy_machine_address = create_candy_machine_test(&account);
        let address: address = signer::address_of(&account);
        create_token_tests::create_tokens_after_all(&account, candy_machine_address, 1);
        start(&account, candy_machine_address);

        let left_amount_of_candy = candy_machine::get_left_amount_of_candy<AptosCoin, TokenDataId>(
            candy_machine_address
        );
        assert!(left_amount_of_candy == 1, WRONG_LEFT_AMOUNT_OF_CANDY);

        let coin_balance = coin::balance<AptosCoin>(address);
        assert!(coin_balance == 10000, WRONG_AMOUNT_OF_COIN);

        mint(&account, candy_machine_address);

        let left_amount_of_candy = candy_machine::get_left_amount_of_candy<AptosCoin, TokenDataId>(
            candy_machine_address
        );
        assert!(left_amount_of_candy == 0, WRONG_LEFT_AMOUNT_OF_CANDY);

        let token_name = string::utf8(b"Candy Machine #");
        let token_id = string::utf8(bcs::to_bytes<u64>(&1));
        string::append(&mut token_name, token_id);
        let token_data_id = token::create_token_data_id(
            candy_machine_address,
            string::utf8(b"Candy Machines"),
            token_name
        );
        let token_balance = token::balance_of(address, create_token_id(token_data_id, 0));
        assert!(token_balance == 1, HAS_NOT_RECEIVE_THE_TOKEN);

        let coin_balance = coin::balance<AptosCoin>(address);
        assert!(coin_balance == 9999, WRONG_AMOUNT_OF_COIN);
    }

    #[test(aptos_framework = @0x1, module_owner = @candymachine)]
    fun mint_token_that_s_maximum_greater_than_one(aptos_framework: &signer, module_owner: &signer) {
        let account = get_account(aptos_framework, module_owner);
        let candy_machine_address = create_candy_machine_test(&account);

        create_collection_test(&account, candy_machine_address);
        create_token_test_with_maximum(&account, candy_machine_address, string::utf8(b"1"), 5);
        start(&account, candy_machine_address);

        let left_amount_of_candy = candy_machine::get_left_amount_of_candy<AptosCoin, TokenDataId>(
            candy_machine_address
        );
        assert!(left_amount_of_candy == 5, WRONG_LEFT_AMOUNT_OF_CANDY);

        mint(&account, candy_machine_address);

        let left_amount_of_candy = candy_machine::get_left_amount_of_candy<AptosCoin, TokenDataId>(
            candy_machine_address
        );
        assert!(left_amount_of_candy == 4, WRONG_LEFT_AMOUNT_OF_CANDY);

        mint(&account, candy_machine_address);

        let left_amount_of_candy = candy_machine::get_left_amount_of_candy<AptosCoin, TokenDataId>(
            candy_machine_address
        );
        assert!(left_amount_of_candy == 3, WRONG_LEFT_AMOUNT_OF_CANDY);
    }

    #[test(aptos_framework = @0x1, module_owner = @candymachine)]
    #[expected_failure(abort_code = 196622)]
    fun mint_token_on_empty_candy_machine(aptos_framework: &signer, module_owner: &signer) {
        let account = get_account(aptos_framework, module_owner);
        let candy_machine_address = create_candy_machine_test(&account);
        start(&account, candy_machine_address);
    }

    #[test(aptos_framework = @0x1, module_owner = @candymachine)]
    #[expected_failure(abort_code = 196621)]
    fun mint_tokens_to_empty_candy_machine(aptos_framework: &signer, module_owner: &signer) {
        let account = get_account(aptos_framework, module_owner);
        let address: address = signer::address_of(&account);
        let candy_machine_address = create_candy_machine_test(&account);

        create_token_tests::create_tokens_after_all(&account, candy_machine_address, 1);
        start(&account, candy_machine_address);

        mint(&account, candy_machine_address);

        let token_name = string::utf8(b"Candy Machine #");
        let token_id = string::utf8(bcs::to_bytes<u64>(&1));
        string::append(&mut token_name, token_id);
        let token_data_id = token::create_token_data_id(
            candy_machine_address,
            string::utf8(b"Candy Machines"),
            token_name
        );
        let token_balance = token::balance_of(address, create_token_id(token_data_id, 0));
        assert!(token_balance == 1, HAS_NOT_RECEIVE_THE_TOKEN);

        mint(&account, candy_machine_address);
    }

    #[test(aptos_framework = @0x1, module_owner = @candymachine)]
    #[expected_failure(abort_code = 196621)]
    fun mint_token_that_triggers_final_state(aptos_framework: &signer, module_owner: &signer) {
        let account = get_account(aptos_framework, module_owner);
        let candy_machine_address = create_candy_machine_test(&account);

        create_token_tests::create_tokens_after_all(&account, candy_machine_address, 1);
        start(&account, candy_machine_address);
        mint(&account, candy_machine_address);
        terminate(&account, candy_machine_address);
    }
}
