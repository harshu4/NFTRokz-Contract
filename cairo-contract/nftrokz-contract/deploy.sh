#! /bin/bash

L1_ERC721_ADDRESS="0x200d7bE3A4ea366CF8aea6Ec1BEda81a03A0f128"
L1_GATEWAY_ADDRESS="0x332CCF31D0D0c35430A9Ba477Ce8bf557135bBC8"

L2_GATEWAY_ADDRESS="0x07685c360044d95517463ef40ba19f85718c3ac4e7b4f6acdfbb124be8a8e582"

export STARKNET_NETWORK=testnet

protostar -p testnet invoke \
    --contract-address ${L2_GATEWAY_ADDRESS} \
    --function initialize \
    --account-address "0x070f8E809C6Cc1Ba7b1dfB721541D1227aBC19BcF0A7b85D6A13EBb3a3ee7Df4" \
    --private-key-path ./pk \
    --network testnet \
    --max-fee auto \
    --inputs "${L1_GATEWAY_ADDRESS}" "0x210a1564940ea06fbe928d2b84ead33e178d7cc6d0e0547e015441fcba5cedc" 

