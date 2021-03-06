let Deal = artifacts.require("TMIterativeDeal");
let DealToken = artifacts.require("DealToken");
let DealsRegistry = artifacts.require("TMIterativeDealsRegistry");

module.exports = function(deployer, network, accounts) {
    deployer.deploy(DealToken).then(() => {
        return deployer.deploy(DealsRegistry, {from: accounts[8]}).then(() => {
            return deployer.deploy(Deal, accounts[7], 5, DealsRegistry.address)
        })    
    })
}