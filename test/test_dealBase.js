const { time } = require('openzeppelin-test-helpers');

const Deal = artifacts.require("TMIterativeDeal");
const DealToken = artifacts.require("DealToken");
const DealsRegistry = artifacts.require("TMIterativeDealsRegistry");

contract('Deal. Base Test', async accounts => {
    const States = {
        INIT: 1,
        PROPOSED_REVIWER: 2,
        RFP: 3,
        DEPOSIT_WAIT: 4,
        ITERATON: 5,
        REVIEW: 6,
        END: 7
    }
    const zeroAddress = "0x0000000000000000000000000000000000000000";

    const client = accounts[0];
    const contractor = accounts[1];
    const reviewerMain = accounts[2];
    const reviewer2 = accounts[3];
    const worker1 = accounts[4];
    const worker2 = accounts[5];
    const contractor2 = accounts[6];
    const platform = accounts[7];
    const registryOwner = accounts[8];

    const reviewerFeeBPS = 5; // 5.div(100)

    const iterationDuration = 60 * 60 * 24 * 14; // 14 days
    let iterationNumber;

    const reviewerDecisionDuration = 60 * 60 * 24 * 5; // 5 days

    let dealBudget;
    let currentState;

    let dealContract;
    let dealTokenContract;
    let dealsRegistry;

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
        dealsRegistry = await DealsRegistry.new({from: registryOwner});
        
        dealContract = await Deal.new(platform, 5, dealsRegistry.address, {from: client, gas: 6742783});
    });

    it("should fail INIT", async() => {
        let taskMock = "some string";
        let shortName = "lal";

        // wrong access
        await expectThrow(
            dealContract.init(shortName, taskMock, iterationDuration, dealTokenContract.address, {from: contractor})
        )

        // wrong param for iteration duration
        await expectThrow(
            dealContract.init(shortName, taskMock, 0, dealTokenContract.address, {from: client})
        )

        // wrong task name and descr length
        await expectThrow(
            dealContract.init("", taskMock, iterationDuration, dealTokenContract.address, {from: client})
        )
        await expectThrow(
            dealContract.init(shortName, "", iterationDuration, dealTokenContract.address, {from: client})
        )
    })

    it("should move state to INIT", async() => {
        let taskMock = "some string";
        let shortName = "lal";

        await dealContract.init(shortName, taskMock, iterationDuration, dealTokenContract.address, {from: client})

        currentState = await dealContract.getState({from: client});
        assert.equal(currentState, States.INIT)

        let clientsDeals = await dealsRegistry.getDealsOfClient(client);
        assert.equal(clientsDeals[0], dealContract.address)
    })

    it('should fail init second time', async() => {
        await expectThrow(
            dealContract.init("12", "212", iterationDuration, dealTokenContract.address, {from: client})
        )
    })
    
    it("should fail transition to PROPOSED_REVIEWER", async() => {
        //wrong access
        await expectThrow(
            dealContract.proposeReviewer(reviewerMain, 5, 1000, {from: contractor})
        )
        // wrong fee
        await expectThrow(
            dealContract.proposeReviewer(reviewerMain, 0, 1000, {from: client})
        )
        await expectThrow(
            dealContract.proposeReviewer(reviewerMain, 10000, 200000, {from: client})
        )
        // wrong decision duration
        await expectThrow(
            dealContract.proposeReviewer(reviewerMain, 5, 0, {from: client})
        )
    })

    it("should change state to PROPOSED_REVIEWER proposing reviewer2", async() => {
        let tx = await dealContract.proposeReviewer(reviewer2, 2, reviewerDecisionDuration, {from: client});
        let emittedEventArgs = tx.logs[0].args

        assert.equal(emittedEventArgs.reviewer, reviewer2)
        assert.equal(emittedEventArgs.reviewerFeeBPS, 2)
        assert.equal(emittedEventArgs.decisionDuration, reviewerDecisionDuration)

        contractState = await dealContract.getState({from: client});
        assert.equal(contractState, States.PROPOSED_REVIWER)

        let reviewer2Deals = await dealsRegistry.getDealsOfReviewer(reviewer2)
        assert.equal(reviewer2Deals[0], dealContract.address)
    })

    it("should reset reviewer2 params", async() => {
        await dealContract.proposeReviewer(reviewer2, reviewerFeeBPS, reviewerDecisionDuration, {from: client});

        contractState = await dealContract.getState({from: client});
        assert.equal(contractState, States.PROPOSED_REVIWER)        
    })

    it("should fail decline reviewer2 coniditions", async() => {
        // wrong access
        await expectThrow(
            dealContract.reviewerJoins(false, {from: contractor})
        )
    })

    it("should decline reviewer2 conditions", async() => {
        await dealContract.reviewerJoins(false, {from: reviewer2})

        contractState = await dealContract.getState({from: client});
        assert.equal(contractState, States.INIT)

        let reviewer2Deals = await dealsRegistry.getDealsOfReviewer(reviewer2)
        assert.equal(reviewer2Deals[0], dealContract.address)
    })

    it("should change state to PROPOSED_REVIEWER proposing reviewerMain", async() => {
        await dealContract.proposeReviewer(reviewerMain, reviewerFeeBPS, reviewerDecisionDuration, {from: client});

        contractState = await dealContract.getState({from: client});
        assert.equal(contractState, States.PROPOSED_REVIWER)

        let reviewerMainDeals = await dealsRegistry.getDealsOfReviewer(reviewerMain)
        assert.equal(reviewerMainDeals[0], dealContract.address)
    })

    it("should fail acception of reviewer conditions", async() => {
        //wrong access
        await expectThrow(
            dealContract.reviewerJoins(true, {from: reviewer2})
        )
    })

    it("should accept reviewer conditions", async() => {
        tx = await dealContract.reviewerJoins(true, {from: reviewerMain})

        contractState = await dealContract.getState({from: client});
        assert.equal(contractState, States.RFP)

        statedReviewer = tx.logs[0].args.reviewer;
        assert.equal(statedReviewer, reviewerMain)
    })

    it("should fail review decline by reviewerMain", async() => {
        // wrong state
        await expectThrow(
            dealContract.reviewerJoins(false, {from: reviewerMain})
        )
    })

    it('should fail new application', async() => {
        // wrong access
        await expectThrow(
            dealContract.newApplication("123", [worker1, worker2], [1, 1], {from: reviewerMain})
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
            dealContract.newApplication("123", [worker1, zeroAddress], [1,2], {from: contractor})
        )
        
        await expectThrow(
            dealContract.newApplication("123", [worker1, worker2], [0, 3], {from: contractor})
        )

        // duplicate worker
        await expectThrow(
            dealContract.newApplication("123", [worker1, worker1], [1,2], {from: contractor})
        )
        
    })

    it('should add new applications', async() => {
        // TODO unfinished
        await dealContract.newApplication("mock", [worker1, worker2], [2000, 2000], {from: contractor})
        await dealContract.newApplication("mock", [worker1, worker2], [1000, 1000], {from: contractor})
        await dealContract.newApplication("mock2", [worker1], [800], {from: contractor2})

        let contractorDeals = await dealsRegistry.getDealsOfContractor(contractor)
        assert.equal(contractorDeals.length, 1)
        assert.equal(contractorDeals[0], dealContract.address)

        let worker1Deals = await dealsRegistry.getDealsOfEmployee(worker1)
        let worker2Deals = await dealsRegistry.getDealsOfEmployee(worker2)

        assert.equal(worker1Deals.length, 1)
        assert.equal(worker1Deals[0], dealContract.address)
        assert.equal(worker2Deals[0], dealContract.address)

        let contractor2Deals = await dealsRegistry.getDealsOfContractor(contractor2)
        assert.equal(contractor2Deals[0], dealContract.address)
    })

    it("should fail cancel deal", async() => {
        // wrong access
        await expectThrow(
            dealContract.cancelRFP({from: reviewerMain})
        )
    })

    it("should fail application approve", async() => {
        // wrong access
        await expectThrow(
            dealContract.approveApplication(contractor, {from: contractor})
        )

        // wrong contractor address value
        await expectThrow(
            dealContract.approveApplication(zeroAddress, {from: client})
        )

        // contractor hasn't got applications
        await expectThrow(
            dealContract.approveApplication(accounts[8], {from: client})
        )
    })

    it("should approve application", async() => {
        let tx = await dealContract.approveApplication(contractor, {from: client})
        assert.equal(tx.logs[0].args.contractor, contractor)

        currentState = await dealContract.getState();
        assert.equal(currentState, States.DEPOSIT_WAIT);
    })

    it("view funcs of RFP should work well in W4D", async() => {
        let curReviewer = await dealContract.getReviewer();
        assert.equal(curReviewer, reviewerMain)

        let dealInfo = await dealContract.getInfo();
        assert.equal(dealInfo.state, States.DEPOSIT_WAIT)
        assert.equal(dealInfo.dealClient, client)
        assert.equal(dealInfo.iterationTimeSeconds, iterationDuration)
        assert.equal(dealInfo.meanOfPayment, dealTokenContract.address)
        assert.equal(dealInfo.feeBPS, reviewerFeeBPS)
        assert.equal(dealInfo.reviewIntervalSeconds, reviewerDecisionDuration)
    })

    it('should fail add new applications', async() => {
        // wrong state
        await expectThrow(
            dealContract.newApplication("mock", [worker1, worker2], [2000, 2000], {from: contractor})
        )
    })

    it("prepare for iteration", async() => {
        // approve tokens for deal contract
        await dealTokenContract.approve(dealContract.address, 120000, {from: client})
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

        currentState = await dealContract.getState()
        assert.equal(currentState, States.ITERATON)
        iterationNumber = 1;
    })

    it("should fail funding new iteration", async() => {
        // wrong state
        await expectThrow(
            dealContract.newIteration(20000, {from: client})
        )
    })

    it("should fail deal finishing", async() => {
        // wrong state
        await expectThrow(
            dealContract.finishDeal({from: client})
        )
    })

    it("should fail work logging", async() => {
        let blocknumber = await web3.eth.getBlockNumber();
        let block = await web3.eth.getBlock(blocknumber);
        
        // invalid access
        await expectThrow(
            dealContract.logWork(block.timestamp, 10, "mock", {from: contractor})
        )
        // empty info param
        await expectThrow(
            dealContract.logWork(block.timestamp, 10, "", {from: worker1})
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
            dealContract.logWork(block.timestamp, 100, "mock", {from: worker1})
        )

        await revertToSnapShot(snapshotId)

        // wrong timestamp
        await expectThrow(
            dealContract.logWork(block.timestamp-100, 60, "mock", {from: worker1})
        )
        await expectThrow(
            dealContract.logWork(2**32-2, 60, "mock", {from: worker1})
        )

        // logging minutes over budget
        // budgetWithoutFees = 99900, worker1Rate = 1000 => maxMins = 99900 * 60 / 1000 = 5994
        await expectThrow(
            dealContract.logWork(block.timestamp, 5995, "mock", {from: worker1})
        )
    })

    it("checking iteration stats", async() => {
        let iterStat = await dealContract.getIterationStat()
        let totalStat = await dealContract.getTotalStat()

        // iter 1 without reviewer fee
        assert.equal(iterStat.currentNumber, iterationNumber)
        assert.equal(iterStat.minutesLogged, 0)
        assert.equal(iterStat.remainingBudget, 100000 - 50) // 50 = feeBPS/100 * dealBudget
        assert.equal(iterStat.spentBudget, 50)

        assert.equal(totalStat.totalMinutesLogged, 0)
        assert.equal(totalStat.totalSpentBudget, 50)
    })

    it("should log work", async() => {
        let blocknumber = await web3.eth.getBlockNumber();
        let block = await web3.eth.getBlock(blocknumber);

        await dealContract.logWork(block.timestamp, 60, "60 mins", {from: worker1});
        await dealContract.logWork(block.timestamp, 60, "60 mins", {from: worker2});

        let iterStat = await dealContract.getIterationStat()
        let totalStat = await dealContract.getTotalStat()

        assert.equal(iterStat.currentNumber, iterationNumber)
        assert.equal(iterStat.minutesLogged, 120)
        assert.equal(iterStat.remainingBudget, 100000 - 50 - 1000 - 1000) // 50 = feeBPS/100 * dealBudget
        assert.equal(iterStat.spentBudget, 50 + 1000 + 1000)

        assert.equal(totalStat.totalMinutesLogged, 60 + 60)
        assert.equal(totalStat.totalSpentBudget, 50 + 1000 + 1000)
    })

    it("should fail finish iteration", async() => {
        // invalid access
        await expectThrow(
            dealContract.finishIteration({from: worker1})
        )
    })

    it("should finish iteration", async() => {
        let blocknumber = await web3.eth.getBlockNumber();
        let block = await web3.eth.getBlock(blocknumber);
        let tx = await dealContract.finishIteration({from: contractor})
        let reviewerStartTimestamp = tx.logs[0].args.when;

        currentState = await dealContract.getState();
        assert.equal(currentState, States.REVIEW);
        assert.equal(reviewerStartTimestamp, block.timestamp)
    })

    it("should fail work logging due to call from wrong state", async() => {
        let blocknumber = await web3.eth.getBlockNumber();
        let block = await web3.eth.getBlock(blocknumber);
        await expectThrow(
            dealContract.logWork(block.timestamp, 60, "60 mins", {from: worker1})
        )
    })

    it("should fail review-ok", async() => {
        // invalid access
        await expectThrow(
            dealContract.reviewOk({from: contractor})
        )
    })

    it("should review ok", async() => {
        dealBudget = await dealTokenContract.balanceOf(dealContract.address);
        assert.equal(dealBudget, 100000)

        await dealContract.reviewOk({from: reviewerMain})

        let costOfWorker1 = 1000; // 60 mins logged, 1hour = 1000
        let costOfWorker2 = 1000; // 60 mins logged, 1hour = 1000

        let tokenBalanceOfContractor = await dealTokenContract.balanceOf(contractor);
        assert.equal(costOfWorker1 + costOfWorker2, tokenBalanceOfContractor)
        
        
        let reviewerReward = dealBudget * 5 / 100 / 100 // BPS 5 fee
        let tokenBalanceOfReviewer = await dealTokenContract.balanceOf(reviewerMain)
        assert.equal(tokenBalanceOfReviewer, reviewerReward)
        
        let platformReward = dealBudget * 5 / 100 / 100 // BPS 5 fee
        let tokenBalanceOfPlatform = await dealTokenContract.balanceOf(platform)
        assert.equal(tokenBalanceOfPlatform, platformReward)

        currentState = await dealContract.getState();
        assert.equal(currentState, States.DEPOSIT_WAIT)
    })

    it("should fail review actions", async() => {
        // wrong states
        await expectThrow(
            dealContract.reviewOk({from: reviewerMain})
        )
        await expectThrow(
            dealContract.reviewFailed({from: reviewerMain})
        )
    })

    it("should fund new iteration", async() => {
        await dealContract.newIteration(20000, {from: client})
        let prevBudget = dealBudget;
        dealBudget = await dealTokenContract.balanceOf(dealContract.address)
        assert.equal(dealBudget, prevBudget.toNumber() + 20000 - 2000 - 100)


        iterationNumber += 1;
    })

    it("check deal stats before log", async() => {
        let iterStat = await dealContract.getIterationStat()
        let totalStat = await dealContract.getTotalStat()

        assert.equal(iterStat.currentNumber, iterationNumber)
        assert.equal(iterStat.minutesLogged, 0)
        assert.equal(iterStat.remainingBudget, dealBudget - 58) // 58 = feeBPS/100/100 * dealBudget
        assert.equal(iterStat.spentBudget, 58)
        
        assert.equal(totalStat.totalMinutesLogged, 120)
        assert.equal(totalStat.totalSpentBudget, 50 + 50 + 1000 + 1000 + 58)
    })

    it("should log work", async() => {
        let blocknumber = await web3.eth.getBlockNumber();
        let block = await web3.eth.getBlock(blocknumber);
        await dealContract.logWork(block.timestamp, 120, "info", {from: worker1})
        // cost 120/60 * 1000 = 2000

        let iterStat = await dealContract.getIterationStat()
        let totalStat = await dealContract.getTotalStat()

        assert.equal(iterStat.currentNumber, iterationNumber)
        assert.equal(iterStat.minutesLogged, 120)
        assert.equal(iterStat.remainingBudget, dealBudget - 58 - 2000) // 58 = feeBPS/100/100 * dealBudget
        assert.equal(iterStat.spentBudget, 58 + 2000)
        
        assert.equal(totalStat.totalMinutesLogged, 120 + 120)
        assert.equal(totalStat.totalSpentBudget, 50 + 50 + 1000 + 1000 + 58 + 2000)
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
        currentState = await dealContract.getState()
        assert.equal(currentState, States.REVIEW)
    })

    it("should review fail", async() => {
        assert.equal(dealBudget, 117900)
        let tx = await dealContract.reviewFailed({from: reviewerMain})

        let tokenBalanceOfContractor = await dealTokenContract.balanceOf(contractor);
        let worker1Costs = 120/60 * 1000; // 2000
        assert.equal(tokenBalanceOfContractor, 2000 + worker1Costs);

        let platformReward = Math.floor(dealBudget * 5 / 100 / 100); // 58
        let tokenBalanceOfPlatform = await dealTokenContract.balanceOf(platform)
        assert.equal(tokenBalanceOfPlatform, 50 + platformReward)

        let reviewerReward = Math.floor(dealBudget * 5 / 100 / 100); // 58
        let tokenBalanceOfReviewer = await dealTokenContract.balanceOf(reviewerMain)
        assert.equal(tokenBalanceOfReviewer, 50 + reviewerReward)
        
        let transferedRestAmount = tx.logs[0].args.funds;
        assert.equal(transferedRestAmount, dealBudget - 2000 - 58 - 58)
    })

    it("check deal stat in END state is right", async() => {
        currentState = await dealContract.getState()
        assert.equal(currentState, States.END)

        let iterStat = await dealContract.getIterationStat()
        let totalStat = await dealContract.getTotalStat()

        assert.equal(iterStat.currentNumber, iterationNumber)
        assert.equal(iterStat.minutesLogged, 120)
        assert.equal(iterStat.remainingBudget, 0)
        assert.equal(iterStat.spentBudget, 58 + 2000 + 58)
        
        assert.equal(totalStat.totalMinutesLogged, 120 + 120)
        assert.equal(totalStat.totalSpentBudget, 50 + 50 + 1000 + 1000 + 58 + 2000 + 58)
    })
})