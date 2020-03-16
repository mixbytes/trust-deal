# trust-deal

## dev-notes
1. identity access could be moved to modifiers for state action functions
2. logic for deal currency must be stated in tech project
3. reINIT, toEnd from INIT state?
4. handle case when reviewer joins, but client gets lost
5. application acceptance model can be changed: we can implement it more off-chain by emiting contractors proposals and gathering them on front. So we will have mapping(contractor=>Application) on front. When client accepts contractor, he saves only contractors address. All other params we get form front.
6. reviewer can be got from ReviewerAcceptedConditions
7. cancelRFP seems to be unfinished
8. what if dealToken is address payable or client/contractor are contracts
9. think about functions that definitely must emit events
10. timestamps type cast (from 256 to 64)
11. deal initialized emits client, we can remove getClient

Run tests with:
```
npx truffle test

# with events
npx truffle test --show-events
```

Make sure you have npx package.