# Candy Machine
A fast, secure and efficient NFT orchestration app.

Testnet Account: 0x69c60de3c31db89d9fe61393a57180e40ad2d405e501cfeb5190112e3c352c63

Mainnet Account: Coming soon as candymachine.apt

## Build

After install [Aptos CLI](https://aptos.dev/cli-tools/aptos-cli-tool/install-aptos-cli). 

You must [initialize local configuration](https://aptos.dev/cli-tools/aptos-cli-tool/use-aptos-cli#initialize-local-configuration-and-create-an-account) on project root folder. After that, you can build with below command.

```
aptos move compile --named-addresses candymachine=default
```

## Test

```
aptos move test --named-addresses candymachine=default
```

## Publish

```
aptos move publish --named-addresses candymachine=default
```

After first publish, you must initialize your smart contract. (just for the first time)

You must run the function below with the account address. Replace @candymachine with your account address.

```
aptos move run --function-id '@candymachine::candy_machine_of_token_data_id::initialize'
```