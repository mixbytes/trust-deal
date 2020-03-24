const Deal = artifacts.require("TMIterativeDeal");
const DealToken = artifacts.require("DealToken");
const DealsRegistry = artifacts.require("TMIterativeDealsRegistry");

contract('Deal. Cancel RFP', async accounts => {
    const States = {
        INIT: 1,
        PROPOSED_REVIWER: 2,
        RFP: 3,
        DEPOSIT_WAIT: 4,
        ITERATION: 5,
        REVIEW: 6,
        END: 7
    }

    const zeroAddress = "0x0000000000000000000000000000000000000000";

    const client = accounts[0];
    const contractor = accounts[1];
    const platform = accounts[7];
    const reviewerMain = accounts[2];
    const reviewer2 = accounts[3];
    const worker1 = accounts[4];
    const worker2 = accounts[5];
    const contractor2 = accounts[6];
    const registryOwner = accounts[8];

    const reviewerFeeBPS = 5; // 5.div(10000)
    const iterationDuration = 60 * 60 * 24 * 14; // 14 days
    const reviewerDecisionDuration = 60 * 60 * 24 * 5; // 5 days

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

    before('deploying deal and token', async() => {
        // Preparing and deploying token contract
        dealTokenContract = await DealToken.new({from: client});
        let dealsRegistry = await DealsRegistry.new({from: registryOwner});
        
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
    })

    it('should fail init second time', async() => {
        await expectThrow(
            dealContract.init("12", "212", iterationDuration, dealTokenContract.address, {from: client})
        )
    })

    it("should fail cancel INIT", async() => {
        // wrong access
        await expectThrow(
            dealContract.cancelINIT({from: contractor})
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

    it("should cancel deal RFP", async() => {
        let tx = await dealContract.cancelRFP({from: client})
        let cancelledFromState = tx.logs[0].args.when;
        assert.equal(cancelledFromState, States.RFP)

        currentState = await dealContract.getState();
        assert.equal(currentState, States.END);
    })
})