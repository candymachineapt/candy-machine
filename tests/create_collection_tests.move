#[test_only]
module candymachine::create_collection_tests {
    use std::unit_test;
    use std::vector;
    use std::string::String;
    use std::string;

    use aptos_framework::util::address_from_bytes;
    use aptos_token::token;

    use candymachine::candy_machine_of_token_data_id::{create_collection};
    use candymachine::create_candy_machine_tests::{get_account, create_candy_machine_test};

    const FAILED_CANDY_MACHINE_COLLECTION_NOT_EXISTS: u64 = 97;

    #[test(aptos_framework = @0x1, module_owner = @candymachine)]
    #[expected_failure(abort_code = 393226)]
    fun create_collection_without_candy_machine(aptos_framework: &signer, module_owner: &signer) {
        let account = get_account(aptos_framework, module_owner);

        let invalid_candy_machine_address: address = address_from_bytes(
            x"0000000000000000000000000000000000000000000000000000000000000001"
        );
        let (collection_name, collection_description, collection_uri,
            collection_maximum, collection_mutate_setting) = Self::build_create_collection_request();

        create_collection(&account, invalid_candy_machine_address, collection_name,
            collection_description, collection_uri, collection_maximum, collection_mutate_setting);
    }

    #[test(aptos_framework = @0x1, module_owner = @candymachine)]
    #[expected_failure(abort_code = 327691)]
    fun create_collection_without_owner(aptos_framework: &signer, module_owner: &signer) {
        let account = get_account(aptos_framework, module_owner);
        let candy_machine_address = create_candy_machine_test(&account);

        let another_account = vector::borrow(&mut unit_test::create_signers_for_testing(2), 1);

        create_collection_test(another_account, candy_machine_address);
    }

    #[test(aptos_framework = @0x1, module_owner = @candymachine)]
    fun create_collection_after_all(aptos_framework: &signer, module_owner: &signer) {
        let account = get_account(aptos_framework, module_owner);
        let candy_machine_address = create_candy_machine_test(&account);

        create_collection_test(&account, candy_machine_address);
    }

    public fun create_collection_test(account: &signer, candy_machine_address: address) {
        let (collection_name, collection_description, collection_uri,
            collection_maximum, collection_mutate_setting) = Self::build_create_collection_request();

        create_collection(account, candy_machine_address, collection_name,
            collection_description, collection_uri, collection_maximum, collection_mutate_setting);

        let collection_exists = token::check_collection_exists(candy_machine_address, collection_name);
        assert!(collection_exists, FAILED_CANDY_MACHINE_COLLECTION_NOT_EXISTS);
    }

    public fun build_create_collection_request(): (String, String, String, u64, vector<bool>) {
        let collection_name: String = string::utf8(b"Candy Machines");
        let collection_description: String = string::utf8(b"Your favorite candy machine collection");
        let collection_uri: String = string::utf8(b"candymachine.apt");
        let collection_maximum: u64 = 1000;
        let collection_mutate_setting: vector<bool> = vector<bool>[false, false, false];

        (collection_name, collection_description, collection_uri,
            collection_maximum, collection_mutate_setting)
    }
}
