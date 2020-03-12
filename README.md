# trust-deal

## dev-notes
1. identity access could be moved to modifiers for state action functions
2. init - check task/shorName for emptiness
3. logic for deal currency must be stated in tech project
4. reINIT, toEnd from INIT state?
5. handle case when reviewer joins, but client gets lost
6. application acceptance model can be changed: we can implement it more off-chain by emiting contractors proposals and gathering them on front. So we will have mapping(contractor=>Application) on front. When client accepts contractor, he saves only contractors address. All other params we get form front.
7. reviewer can be got from ReviewerAcceptedConditions
8. cancelRFP seems to be unfinished

Run tests with:
```
npx truffle test

# with events
npx truffle test --show-events
```

Make sure you have npx package.