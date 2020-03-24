# trust-deal

## To be done:
1) implement DealsRegistry

## Test
Run local tests with:
```
ganache-cli -p 7545 -i 5777 --allowUnlimitedContractSize  --gasLimit 0xFFFFFFFFFFFF
npx truffle migrate --reset --network development
npx truffle test --network development

# with events
npx truffle test --show-events --network development
```

Make sure you have npx package.