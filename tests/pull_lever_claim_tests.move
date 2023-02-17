#[test_only]
module candymachine::pull_lever_claim_tests {
    use candymachine::candy_machine;
    use candymachine::create_token_tests;
    use candymachine::candy_machine_of_token_data_id::{start};
    use candymachine::create_candy_machine_tests::{get_account, create_candy_machine_test, create_candy_machine_2_test};
    use candymachine::candy_machine::PullLeverClaim;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_token::token::TokenDataId;


    #[test(aptos_framework = @0x1, module_owner = @candymachine)]
    fun pull_lever_claim_is_mandatory_to_use(aptos_framework: &signer, module_owner: &signer) {
        let account = get_account(aptos_framework, module_owner);
        let candy_machine_address = create_candy_machine_test(&account);

        create_token_tests::create_tokens_after_all(&account, candy_machine_address, 1);
        start(&account, candy_machine_address);

        let claim: PullLeverClaim = candy_machine::insert_coin<AptosCoin, TokenDataId>(&account, candy_machine_address);
        let _lucky_token_data_id: TokenDataId = candy_machine::pull_lever<AptosCoin, TokenDataId>(candy_machine_address, claim);
    }


    #[test(aptos_framework = @0x1, module_owner = @candymachine)]
    #[expected_failure(abort_code = 65552)]
    fun pull_lever_claim_must_be_machine_related(aptos_framework: &signer, module_owner: &signer) {
        let account = get_account(aptos_framework, module_owner);

        let candy_machine_address = create_candy_machine_test(&account);
        create_token_tests::create_tokens_after_all(&account, candy_machine_address, 1);
        start(&account, candy_machine_address);

        let candy_machine_address_2 = create_candy_machine_2_test(&account);
        create_token_tests::create_tokens_after_all(&account, candy_machine_address_2, 1);
        start(&account, candy_machine_address_2);

        let claim: PullLeverClaim = candy_machine::insert_coin<AptosCoin, TokenDataId>(&account, candy_machine_address_2);
        let _lucky_token_data_id: TokenDataId = candy_machine::pull_lever<AptosCoin, TokenDataId>(candy_machine_address, claim);
    }
}
