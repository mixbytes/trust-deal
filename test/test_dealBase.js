const Deal = artifacts.require("Deal");
const DealToken = artifacts.require("DealToken");

contract('Deal. Base Test', async accounts => {
    const States = {
        INIT: 0,
        PROPOSED_REVIWER: 1
    }

    const client = accounts[0];
    const developer = accounts[1];
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

        // Preparing and deploying Deal contract
        let currentTime = await getCurrentTimestamp();

        let dealDeadline = currentTime + 10000000000;
        let taskMock = "some string";
        dealContract = await Deal.new(taskMock, dealDeadline, dealTokenContract.address, {from: client});
    });

    it("check deployed deal state is INIT", async() => {
        dealState = await dealContract.currentState.call()

        assert.equal(dealState, States.INIT)
    }) 

})