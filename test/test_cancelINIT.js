const Deal = artifacts.require("TMIterativeDeal");
const DealToken = artifacts.require("DealToken");

contract('Deal. Cancel INIT', async accounts => {
    const States = {
        INIT: 1,
        PROPOSED_REVIWER: 2,
        RFP: 3,
        DEPOSIT_WAIT: 4,
    }

    const client = accounts[0];
    const contractor = accounts[1];
    const platform = accounts[7];

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
        
        dealContract = await Deal.new(platform, 5, {from: client});
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

    // TODO add test with ether as deal currency
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

    it("should fail cancel INIT", async() => {
        await dealContract.cancelINIT({from: client})
    })

    it("should fail cancel INIT - wrong state", async() => {
        // wrong state
        await expectThrow(
            dealContract.cancelINIT({from: client})
        )
    })
})