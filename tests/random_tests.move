#[test_only]
module candymachine::random_tests {
    use std::error;
    use std::unit_test;
    use std::vector;
    use std::signer;

    use aptos_framework::genesis;
    use aptos_framework::timestamp;

    use candymachine::candy_machine;

    const ERROR_OF_RANDOM_NUMBER_FUN: u64 = 92;

    #[test]
    public fun pseudo_random_test() {
        genesis::setup();
        let account = vector::pop_back(&mut unit_test::create_signers_for_testing(1));
        let address = signer::address_of(&account);
        aptos_framework::account::create_account_for_test(address);
        let max_candy = 100;
        let left_candy = 50;

        let random_number1 = candy_machine::pseudo_random(address, max_candy, left_candy);
        timestamp::fast_forward_seconds(3600);
        let random_number2 = candy_machine::pseudo_random(address, random_number1, max_candy);

        assert!(random_number1 != random_number2, error::internal(ERROR_OF_RANDOM_NUMBER_FUN));
    }

    #[test]
    public fun pseudo_random_test_on_one_number() {
        genesis::setup();
        let account = vector::pop_back(&mut unit_test::create_signers_for_testing(1));
        let address = signer::address_of(&account);
        aptos_framework::account::create_account_for_test(address);
        let max_candy = 1;
        let left_candy = 1;

        let random_number = candy_machine::pseudo_random(address, max_candy, left_candy);
        assert!(random_number == 0, error::internal(ERROR_OF_RANDOM_NUMBER_FUN));
    }

    #[test]
    #[expected_failure(abort_code = 12)]
    public fun pseudo_random_test_on_no_number() {
        genesis::setup();
        let account = vector::pop_back(&mut unit_test::create_signers_for_testing(1));
        let address = signer::address_of(&account);
        aptos_framework::account::create_account_for_test(address);
        let max_candy = 0;
        let left_candy = 0;

        let _random_number = candy_machine::pseudo_random(address, max_candy, left_candy);
    }
}
