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

    let getCurrentTimestamp = async() => {
        let blocknumber = await web3.eth.getBlockNumber();
        let block = await web3.eth.getBlock(blocknumber);

        return block.timestamp
    }

    before('deploying deal and token', async() => {
        // Preparing and deploying token contract
        dealTokenContract = await DealToken.new({from: client});
        
        dealContract = await Deal.new({from: client});
    });

    it("should fail INIT", async() => {
        let iterationTimeout = 60 * 60 * 24 * 14;
        let taskMock = "some string";

        // wrong access
        await expectThrow(
            dealContract.init(taskMock, iterationTimeout, dealTokenContract.address, {from: contractor})
        )

        // wrong param for iteration duration
        await expectThrow(
            dealContract.init(taskMock, 0, dealTokenContract.address, {from: client})
        )
    })

    it("should move state to INIT", async() => {
        let iterationTimeout = 60 * 60 * 24 * 14;
        let taskMock = "some string";

        dealContract.init(taskMock, iterationTimeout, dealTokenContract.address, {from: client})

        currentState = await dealContract.getState({from: client});
        assert.equal(currentState, States.INIT)

    })

    it("should fail transition to PROPOSED_REVIWER", async() => {
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

        declinedReviewer = tx.logs[0].args.reviewer;
        assert.equal(declinedReviewer, zeroAddress)
    })

    it("should change state to PROPOSED_REVIEWER proposing reviewer2", async() => {
        reviewerFee = 5 // 0.05%
        reviwerDecisionDuration = 60 * 60 * 24 * 3 // 5 days
        await dealContract.proposeReviewer(reviewer2, reviewerFee, reviwerDecisionDuration, {from: client});

        contractState = await dealContract.getState({from: client});
        assert.equal(contractState, States.PROPOSED_REVIWER)
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
})