build:
	forge build

test:
	forge test

deploy:
	forge script script/Deploy.s.sol:Deploy --rpc-url $GOERLI_RPC_URL --broadcast --verify -vvvv