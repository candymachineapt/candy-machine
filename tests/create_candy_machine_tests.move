#[test_only]
module candymachine::create_candy_machine_tests {
    use std::signer;
    use std::unit_test;
    use std::vector;
    use std::error;

    use aptos_framework::timestamp::set_time_has_started_for_testing;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::account;
    use aptos_framework::coin;
    use aptos_token::token::TokenDataId;

    use candymachine::candy_machine;
    use aptos_framework::account::create_account_for_test;
    use candymachine::candy_machine_of_token_data_id::initialize;

    const FAILED_CANDY_MACHINE_NOT_EXISTS: u64 = 98;

    #[test(aptos_framework = @0x1, module_owner = @candymachine)]
    public fun create_candy_machine(aptos_framework: &signer, module_owner: &signer) {
        let account = get_account(aptos_framework, module_owner);
        create_candy_machine_test(&account);
    }

    public fun get_account(aptos_framework: &signer, module_owner: &signer): signer {
        set_time_has_started_for_testing(aptos_framework);
        let signers = &mut unit_test::create_signers_for_testing(1);
        let result = vector::pop_back(signers);

        let address = signer::address_of(&result);
        aptos_framework::account::create_account_for_test(address);
        coin::register<AptosCoin>(&result);

        let (burn_cap, mint_cap) = aptos_framework::aptos_coin::initialize_for_test(aptos_framework);
        let creation_fee: u64 = 0; /*creation_fee*/
        coin::deposit(signer::address_of(&result), coin::mint(10000 + creation_fee, &mint_cap));

        create_account_for_test(@candymachine);
        coin::register<AptosCoin>(module_owner);
        coin::deposit(@candymachine, coin::mint(10 * creation_fee, &mint_cap));
        initialize(module_owner);

        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);

        result
    }

    public fun create_candy_machine_test(account: &signer): address {
        let candy_machine_address: address = candy_machine::create_candy_machine<AptosCoin, TokenDataId>(
            account,
            x"01"
        );
        let exists: bool = account::exists_at(candy_machine_address);

        assert!(exists, error::not_found(FAILED_CANDY_MACHINE_NOT_EXISTS));
        candy_machine::check_candy_machine_exists<AptosCoin, TokenDataId>(candy_machine_address);
        candy_machine_address
    }
}