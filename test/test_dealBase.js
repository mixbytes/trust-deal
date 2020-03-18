const { time } = require('openzeppelin-test-helpers');

const Deal = artifacts.require("TMIterativeDeal");
const DealToken = artifacts.require("DealToken");

contract('Deal. Base Test', async accounts => {
    const States = {
        INIT: 1,
        PROPOSED_REVIWER: 2,
        RFP: 3,
        DEPOSIT_WAIT: 4,
    }
    const zeroAddress = 0;

    const client = accounts[0];
    const contractor = accounts[1];
    const reviewer1 = accounts[2];
    const reviewer2 = accounts[3];
    const worker1 = accounts[4];
    const worker2 = accounts[5];
    const contractor2 = accounts[6];
    const platform = accounts[7];

    let dealContract;
    let dealTokenContract;

    let expectThrow = async (promise) => {
        try {
            await promise;
        } catch (error) {
            const invalidOpcode = error.message.search('invalid opcode') >= 0;
            const outOfGas = error.message.search('out of gas') >= 0;
            const revert = error.message.search('revert') >= 0;
            assert(
                invalidOpcode || outOfGas || revert,
                "Expected throw, got '" + error + "' instead",
            );
          return;
        }
        assert.fail('Expected throw not received');
    };

    let takeSnapshot = () => {
        return new Promise((resolve, reject) => {
          web3.currentProvider.send({
            jsonrpc: '2.0',
            method: 'evm_snapshot',
            id: new Date().getTime()
          }, (err, snapshotId) => {
            if (err) { return reject(err) }
            return resolve(snapshotId)
          })
        })
    }

    let revertToSnapShot = (id) => {
        return new Promise((resolve, reject) => {
          web3.currentProvider.send({
            jsonrpc: '2.0',
            method: 'evm_revert',
            params: [id],
            id: new Date().getTime()
          }, (err, result) => {
            if (err) { return reject(err) }
            return resolve(result)
          })
        })
    }

    let snapshotId;

    before('deploying deal and token', async() => {
        // Preparing and deploying token contract
        dealTokenContract = await DealToken.new({from: client});
        
        dealContract = await Deal.new(platform, 5, {from: client});
    });

    it("should fail INIT", async() => {
        let iterationTimeout = 60 * 60 * 24 * 14;
        let taskMock = "some string";
        let shortName = "lal";

        // wrong access
        await expectThrow(
            dealContract.init(shortName, taskMock, iterationTimeout, dealTokenContract.address, {from: contractor})
        )

        // wrong param for iteration duration
        await expectThrow(
            dealContract.init(shortName, taskMock, 0, dealTokenContract.address, {from: client})
        )

        // wrong task name and descr length
        await expectThrow(
            dealContract.init("", taskMock, iterationTimeout, dealTokenContract.address, {from: client})
        )
        await expectThrow(
            dealContract.init(shortName, "", iterationTimeout, dealTokenContract.address, {from: client})
        )
    })

    // TODO add test with ether as deal currency
    it("should move state to INIT", async() => {
        let iterationTimeout = 60 * 60 * 24 * 14; // 14 days
        let taskMock = "some string";
        let shortName = "lal";

        await dealContract.init(shortName, taskMock, iterationTimeout, dealTokenContract.address, {from: client})

        currentState = await dealContract.getState({from: client});
        assert.equal(currentState, States.INIT)
    })

    it('should fail init second time', async() => {
        await expectThrow(
            dealContract.init("12", "212", 12121212, dealTokenContract.address, {from: client})
        )
    })

    it("should fail transition to PROPOSED_REVIEWER", async() => {
        //wrong access
        await expectThrow(
            dealContract.proposeReviewer(reviewer1, 5, 1000, {from: contractor})
        )
        // wrong fee
        await expectThrow(
            dealContract.proposeReviewer(reviewer1, 0, 1000, {from: client})
        )
        await expectThrow(
            dealContract.proposeReviewer(reviewer1, 0, 200000, {from: client})
        )
        // wrong decision duration
        await expectThrow(
            dealContract.proposeReviewer(reviewer1, 5, 0, {from: client})
        )
    })

    it("should change state to PROPOSED_REVIEWER proposing reviewer1", async() => {
        reviewerFee = 5 // 0.05%
        reviwerDecisionDuration = 60 * 60 * 24 * 3 // 3 days
        await dealContract.proposeReviewer(reviewer1, reviewerFee, reviwerDecisionDuration, {from: client});

        contractState = await dealContract.getState({from: client});
        assert.equal(contractState, States.PROPOSED_REVIWER)
    })

    it("should reset reviewer params", async() => {
        reviewerFee = 5 // 0.05%
        reviwerDecisionDuration = 60 * 60 * 24 * 5 // 5 days
        await dealContract.proposeReviewer(reviewer1, reviewerFee, reviwerDecisionDuration, {from: client});

        contractState = await dealContract.getState({from: client});
        assert.equal(contractState, States.PROPOSED_REVIWER)        
    })

    it("should fail decline reviewer coniditions", async() => {
        // wrong access
        await expectThrow(
            dealContract.reviewerJoins(false, {from: contractor})
        )
    })

    it("should decline reviewer conditions", async() => {
        tx = await dealContract.reviewerJoins(false, {from: reviewer1})

        contractState = await dealContract.getState({from: client});
        assert.equal(contractState, States.INIT)
    })

    it("should change state to PROPOSED_REVIEWER proposing reviewer2", async() => {
        reviewerFee = 5 // 0.05%
        reviwerDecisionDuration = 60 * 60 * 24 * 3 // 5 days
        await dealContract.proposeReviewer(reviewer2, reviewerFee, reviwerDecisionDuration, {from: client});

        contractState = await dealContract.getState({from: client});
        assert.equal(contractState, States.PROPOSED_REVIWER)
    })

    it("should fail acception of reviewer conditions", async() => {
        //wrong access
        await expectThrow(
            dealContract.reviewerJoins(true, {from: reviewer1})
        )
    })

    it("should accept reviewer conditions by reviewer2 and move state to RFP", async() => {
        tx = await dealContract.reviewerJoins(true, {from: reviewer2})

        contractState = await dealContract.getState({from: client});
        assert.equal(contractState, States.RFP)

        statedReviewer = tx.logs[0].args.reviewer;
        assert.equal(statedReviewer, reviewer2)
    })

    it("should fail review decline by reviewer2", async() => {
        // wrong state
        await expectThrow(
            dealContract.reviewerJoins(false, {from: reviewer2})
        )
    })

    it('should fail new application', async() => {
        // wrong access
        await expectThrow(
            dealContract.newApplication("123", [worker1, worker2], [1, 1], {from: reviewer2})
        )

        
        // invalid length of params
        await expectThrow(
            dealContract.newApplication("123", [worker1], [1,1], {from: contractor})
        )

        // invalid length of params
        await expectThrow(
            dealContract.newApplication("123", [], [], {from: contractor})
        )

        await expectThrow(
            dealContract.newApplication("", [worker1], [300], {from: contractor})
        )

        // invalid value of param
        await expectThrow(
            dealContract.newApplication("", [worker1, "0x0000000000000000000000000000000000000000"], [1,2], {from: contractor})
        )
        
        await expectThrow(
            dealContract.newApplication("", [worker1, worker2], [0, 3], {from: contractor})
        )
        
    })
    
    it('should add new applications', async() => {
        await dealContract.newApplication("mock", [worker1, worker2], [1000, 1000], {from: contractor})
        await dealContract.newApplication("mock2", [worker1], [800], {from: contractor2})
    })

    it("should fail cancel deal", async() => {
        // wrong access
        await expectThrow(
            dealContract.cancelRFP({from: contractor})
        )
    })

    // TODO Cancellation test in RFP test should be added

    it("should fail application approve", async() => {
        // wrong access
        await expectThrow(
            dealContract.approveApplication(contractor, {from: contractor})
        )

        // wrong contractor address value
        await expectThrow(
            dealContract.approveApplication("0x0000000000000000000000000000000000000000", {from: client})
        )

        // contractor hasn't got applications
        await expectThrow(
            dealContract.approveApplication(reviewer1, {from: client})
        )
    })

    it("should approve application", async() => {
        let tx = await dealContract.approveApplication(contractor, {from: client})
        assert.equal(tx.logs[0].args.contractor, contractor)
    })

    // TODO Cancellation test in W4D should be added

    it("prepare for iteration", async() => {
        // approve tokens for deal contract
        await dealTokenContract.approve(dealContract.address, 100000, {from: client})
    })

    it("should fail iteration funding", async() => {
        // invalid access
        await expectThrow(
            dealContract.newIteration(500000, {from: contractor})
        )
        // too little
        await expectThrow(
            dealContract.newIteration(10000, {from: client})
        )
        // to much
        await expectThrow(
            dealContract.newIteration(10000000000, {from: client})
        )
    })

    it("should fund new iteration", async() => {
        let funding = 100000;
        await dealContract.newIteration(funding, {from: client});

        let balanceOfDeal = await dealTokenContract.balanceOf(dealContract.address);
        assert.equal(balanceOfDeal, funding);
    })

    it("should fail funding new iteration", async() => {
        // wrong state
        await expectThrow(
            dealContract.newIteration(100000, {from: client})
        )
    })

    it("should fail work logging", async() => {
        // invalid access
        await expectThrow(
            dealContract.logWork(10000000, 10, "mock", {from: contractor})
        )
        // empty info param
        await expectThrow(
            dealContract.logWork(10000000, 10, "", {from: worker1})
        )

        // timeout is met
        let currentSnapshot = await takeSnapshot();
        snapshotId = currentSnapshot['result']

        await time.advanceBlock()
        let start = await time.latest()
        let end = start.add(time.duration.days(15));
        await time.increaseTo(end)

        // iteration timeout is met
        await expectThrow(
            dealContract.logWork(10000000, 100, "mock", {from: worker1})
        )

        await revertToSnapShot(snapshotId)

        // logging minutes over budget
        // budgetWithoutFees = 99950, worker1Rate = 1000 => maxMin = 99950 * 60 / 1000 = 5997
        // TODO budgetWithoutFees does not containt platform fee
        await expectThrow(
            dealContract.logWork(10000000, 5997, "mock", {from: worker1})
        )
        
    })

    // TODO dev-note comment 12
    it("should log work", async() => {
        await dealContract.logWork(10000000, 60, "60 mins", {from: worker1});
        await dealContract.logWork(10000000, 60, "60 mins", {from: worker2});
    })

    // TODO test finish iteration with timeout
    it("should fail finish iteration", async() => {
        // invalid access
        await expectThrow(
            dealContract.finishIteration({from: worker1})
        )
    })

    it("should finish iteration", async() => {
        await dealContract.finishIteration({from: contractor})
    })

    it("should fail work logging due to call from wrong state", async() => {
        await expectThrow(
            dealContract.logWork(10000000, 60, "60 mins", {from: worker1})
        )
    })

    it("should fail review-ok", async() => {
        // invalid access
        await expectThrow(
            dealContract.reviewOk({from: contractor})
        )

        // TODO test review with timeout
    })

    it("should review ok", async() => {
        let dealBudget = await dealTokenContract.balanceOf(dealContract.address);
        assert.equal(dealBudget, 100000)

        await dealContract.reviewOk({from: reviewer2})

        let costOfWorker1 = 1000; // 60 mins logged, 1hour = 1000
        let costOfWorker2 = 1000; // 60 mins logged, 1hour = 1000

        let tokenBalanceOfContractor = await dealTokenContract.balanceOf(contractor);
        assert.equal(costOfWorker1 + costOfWorker2, tokenBalanceOfContractor)
        
        let reviewerReward = dealBudget * 5 / 100 / 100 // BPS 5 fee
        let tokenBalanceOfReviewer = await dealTokenContract.balanceOf(reviewer2)
        assert.equal(tokenBalanceOfReviewer, reviewerReward)

        let platformReward = dealBudget * 5 / 100 / 100 // BPS 5 fee
        let tokenBalanceOfPlatform = await dealTokenContract.balanceOf(platform)
        assert.equal(tokenBalanceOfPlatform, platformReward)
    })

    it("should fail review actions", async() => {
        // wrong states
        await expectThrow(
            dealContract.reviewOk({from: reviewer2})
        )
        await expectThrow(
            dealContract.reviewFailed({from: reviewer2})
        )
    })

    it("should fund new iteration", async() => {
        await dealTokenContract.approve(dealContract.address, 20000, {from: client})
        await dealContract.newIteration(20000, {from: client})

        // 97900 + 20000
    })

    it("should log work", async() => {
        await dealContract.logWork(100000000, 120, "info", {from: worker1})
        // cost 2 * 1000 = 2000
    })

    it("should finish iteration because of timeout", async() => {
        // timeout is met
        let currentSnapshot = await takeSnapshot();
        snapshotId = currentSnapshot['result']

        await time.advanceBlock()
        let start = await time.latest()
        let end = start.add(time.duration.days(14));
        await time.increaseTo(end)

        // iteration timeout is met
        await dealContract.finishIteration({from: worker1})
    })

    it("should review fail", async() => {
        let dealBudget = await dealTokenContract.balanceOf(dealContract.address);
        assert.equal(dealBudget, 97900 + 20000)
        await dealContract.reviewFailed({from: reviewer2})

        let tokenBalanceOfContractor = await dealTokenContract.balanceOf(contractor);
        let worker1Costs = 120/60 * 1000; // 2000
        assert.equal(tokenBalanceOfContractor, 2000 + worker1Costs);

        let platformReward = Math.floor(dealBudget * 5 / 100 / 100); // 58
        let tokenBalanceOfPlatform = await dealTokenContract.balanceOf(platform)
        assert.equal(tokenBalanceOfPlatform, 50 + platformReward)

        let reviewerReward = Math.floor(dealBudget * 5 / 100 / 100); // 58
        let tokenBalanceOfReviewer = await dealTokenContract.balanceOf(reviewer2)
        assert.equal(tokenBalanceOfReviewer, 50 + reviewerReward)       
    })
})