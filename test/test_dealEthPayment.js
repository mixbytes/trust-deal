const { time } = require('openzeppelin-test-helpers');

const Deal = artifacts.require("TMIterativeDeal");
const BN = web3.utils.BN;

contract('Deal. Eth payment', async accounts => {
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

    const reviewerFeeBPS = 5; // 5.div(100)

    const iterationDuration = 60 * 60 * 24 * 14; // 14 days
    let iterationNumber;

    const reviewerDecisionDuration = 60 * 60 * 24 * 5; // 5 days

    let dealBudget;
    let currentState;

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
        dealContract = await Deal.new(platform, 5, {from: client});
    });

    it("should fail INIT", async() => {
        let taskMock = "some string";
        let shortName = "lal";

        // wrong access
        await expectThrow(
            dealContract.init(shortName, taskMock, iterationDuration, zeroAddress, {from: contractor})
        )

        // wrong param for iteration duration
        await expectThrow(
            dealContract.init(shortName, taskMock, 0, zeroAddress, {from: client})
        )

        // wrong task name and descr length
        await expectThrow(
            dealContract.init("", taskMock, iterationDuration, zeroAddress, {from: client})
        )
        await expectThrow(
            dealContract.init(shortName, "", iterationDuration, zeroAddress, {from: client})
        )
    })

    // TODO add test with ether as deal currency
    it("should move state to INIT", async() => {
        let taskMock = "some string";
        let shortName = "lal";

        await dealContract.init(shortName, taskMock, iterationDuration, zeroAddress, {from: client})

        currentState = await dealContract.getState({from: client});
        assert.equal(currentState, States.INIT)
    })

    it('should fail init second time', async() => {
        await expectThrow(
            dealContract.init("12", "212", iterationDuration, zeroAddress, {from: client})
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
    })

    it("should change state to PROPOSED_REVIEWER proposing reviewerMain", async() => {
        await dealContract.proposeReviewer(reviewerMain, reviewerFeeBPS, reviewerDecisionDuration, {from: client});

        contractState = await dealContract.getState({from: client});
        assert.equal(contractState, States.PROPOSED_REVIWER)
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
        await dealContract.newApplication("mock", [worker1, worker2], [1000, 1000], {from: contractor})
        await dealContract.newApplication("mock2", [worker1], [800], {from: contractor2})
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
        assert.equal(dealInfo.meanOfPayment, 0)
        assert.equal(dealInfo.feeBPS, reviewerFeeBPS)
        assert.equal(dealInfo.reviewIntervalSeconds, reviewerDecisionDuration)
    })

    it('should fail add new applications', async() => {
        // wrong state
        await expectThrow(
            dealContract.newApplication("mock", [worker1, worker2], [2000, 2000], {from: contractor})
        )
    })

    it("should fail iteration funding", async() => {
        // invalid access
        await expectThrow(
            dealContract.newIteration(500000, {from: contractor, value: 500000})
        )
        // too little
        await expectThrow(
            dealContract.newIteration(0, {from: client, value: 10000})
        )
    })

    it("should fund new iteration", async() => {
        let funding = 100000;
        await dealContract.newIteration(funding, {from: client, value: funding});

        let balanceOfDeal = await web3.eth.getBalance(dealContract.address);
        assert.equal(balanceOfDeal, funding);

        currentState = await dealContract.getState()
        assert.equal(currentState, States.ITERATON)
        iterationNumber = 1;
    })

    it("should fail funding new iteration", async() => {
        // wrong state
        await expectThrow(
            dealContract.newIteration(20000, {from: client, value: 20000})
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
        let balanceOfContractorBeforeReview = await web3.eth.getBalance(contractor);
        let balanceOfPlatformBeforeReview = await web3.eth.getBalance(platform)
        dealBudget = await web3.eth.getBalance(dealContract.address);
        assert.equal(dealBudget, 100000)

        await dealContract.reviewOk({from: reviewerMain})

        let costOfWorker1 = 1000; // 60 mins logged, 1hour = 1000
        let costOfWorker2 = 1000; // 60 mins logged, 1hour = 1000

        let balanceOfContractorAfterReview = await web3.eth.getBalance(contractor);
        assert.equal(new BN(balanceOfContractorAfterReview).sub(new BN(balanceOfContractorBeforeReview)).toString(), String(costOfWorker1+costOfWorker2))
        
        let platformReward = dealBudget * 5 / 100 / 100 // BPS 5 fee
        let balanceOfPlatformAfterReview = await web3.eth.getBalance(platform)
        assert.equal(new BN(balanceOfPlatformAfterReview).sub(new BN(balanceOfPlatformBeforeReview)).toString(), String(platformReward))

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
        await dealContract.newIteration(20000, {from: client, value: 20000})
        let prevBudget = new BN(dealBudget);
        dealBudget = await web3.eth.getBalance(dealContract.address)
        assert.equal(new BN(dealBudget).toString(), prevBudget.add(new BN(20000)).sub(new BN(2000+100)).toString())

        iterationNumber += 1;
    })
/
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
        let balanceOfContractorBeforeReview = await web3.eth.getBalance(contractor);
        let balanceOfPlatformBeforeReview = await web3.eth.getBalance(platform)

        let tx = await dealContract.reviewFailed({from: reviewerMain})

        let worker1Costs = 2000 // (120*1000 /60)
        let balanceOfContractorAfterReview = await web3.eth.getBalance(contractor);
        assert.equal(new BN(balanceOfContractorAfterReview).sub(new BN(balanceOfContractorBeforeReview)).toString(), String(worker1Costs))

        let platformReward = Math.floor(dealBudget * 5 / 100 / 100); // 58
        let balanceOfPlatformAfterReview = await web3.eth.getBalance(platform)
        assert.equal(new BN(balanceOfPlatformAfterReview).sub(new BN(balanceOfPlatformBeforeReview)).toString(), String(platformReward))
        
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