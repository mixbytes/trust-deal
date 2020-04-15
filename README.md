# trust-deal

## To be done:
1) Optimizations and security changes in accordance to what was stated in tech docs

## Test
Run local tests with:
```
ganache-cli -p 7545 -i 5777 
npx truffle migrate --reset --network development
npx truffle test --network development

# with events
npx truffle test --show-events --network development
```

Make sure you have npx package.
