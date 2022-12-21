#[test_only]
module candymachine::update_sell_price_tests {
    use std::signer;

    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::coin;
    use aptos_token::token::TokenDataId;

    use candymachine::candy_machine;
    use candymachine::create_token_tests;
    use candymachine::candy_machine_of_token_data_id::{start, update_sell_price, mint};
    use candymachine::create_candy_machine_tests::{get_account, create_candy_machine_test};

    const INVALID_SELL_PRICE_OF_CANDY: u64 = 90;
    const WRONG_AMOUNT_OF_COIN: u64 = 91;

    #[test(aptos_framework = @0x1, module_owner = @candymachine)]
    #[expected_failure(abort_code = 196621)]
    fun mint_one_token_after_all_after_start(aptos_framework: &signer, module_owner: &signer) {
        let account = get_account(aptos_framework, module_owner);
        let candy_machine_address = create_candy_machine_test(&account);

        create_token_tests::create_tokens_after_all(&account, candy_machine_address, 5);
        start(&account, candy_machine_address);

        update_sell_price(&account, candy_machine_address, 2);
    }

    #[test(aptos_framework = @0x1, module_owner = @candymachine)]
    fun mint_one_token_on_updated_price(aptos_framework: &signer, module_owner: &signer) {
        let account = get_account(aptos_framework, module_owner);
        let candy_machine_address = create_candy_machine_test(&account);

        create_token_tests::create_tokens_after_all(&account, candy_machine_address, 5);

        let sell_price_of_candy: u64 = candy_machine::get_sell_price_of_candy<AptosCoin, TokenDataId>(candy_machine_address);
        assert!(sell_price_of_candy == 1, INVALID_SELL_PRICE_OF_CANDY);

        update_sell_price(&account, candy_machine_address, 2);

        let sell_price_of_candy: u64 = candy_machine::get_sell_price_of_candy<AptosCoin, TokenDataId>(candy_machine_address);
        assert!(sell_price_of_candy == 2, INVALID_SELL_PRICE_OF_CANDY);

        start(&account, candy_machine_address);
        mint(&account, candy_machine_address);

        let address: address = signer::address_of(&account);
        let coin_balance: u64 = coin::balance<AptosCoin>(address);
        assert!(coin_balance == 9998, WRONG_AMOUNT_OF_COIN);
    }
}