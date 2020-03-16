pragma solidity 0.5.7;

import './base.sol';

contract DealRFPStateLogic is BaseDealStateTransitioner {
    event ContractorChosen(address contractor);

    // TODO look at dev-note 7th comment
    function getReviewer() external view returns (address) {
        require(currentState >= States.RFP, "Call from wrong state");
        return reviewer;
    }

    function getInfo() external view returns (
        States state,
        address dealClient,
        string memory shortName,
        string memory task,
        uint32 iterationTimeSeconds,
        IERC20 paymentToken,
        address dealReviewer,
        uint16 feeBPS,
        uint32 reviewTimeoutSeconds
    ) {
        require(currentState >= States.RFP, "Call from wrong state");
        state = currentState;
        dealClient = client;
        shortName = taskShortName;
        task = taskDescription;
        iterationTimeSeconds = iterationDuration;
        paymentToken = dealToken;
        dealReviewer = reviewer;
        feeBPS = reviewerFeeBPS;
        reviewTimeoutSeconds = reviewerDecisionDuration;
    }

    function newApplication(
        string calldata application,
        address[] calldata workers,
        uint256[] calldata rates
    )
        external
    {
        require(currentState == States.RFP, "Call from wrong state");
        require(workers.length == rates.length,"Workers and rates arrays should be equal");
        require(workers.length > 0 && workers.length < 100, "Array params have wrong lengths");
        require(bytes(application).length > 0, "Empty application description provided");
        require(
            msg.sender != reviewer && msg.sender != client,
            "Client or contractor can't add applications"
        );

        applications[msg.sender] = Application(application);
        mapping(address => uint256) storage e = applications[msg.sender].employeesRates;
        for (uint16 i; i < workers.length; i++) {
            require(
                workers[i] != address(0) && rates[i] != 0,
                "Wrong application params: address or related rate are equal to 0"
            );
            e[workers[i]] = rates[i];
        }
        emit ApplicationAdded(msg.sender, application, workers, rates);
    }

    function cancelRFP() external onlyClient {
        // TODO raw version, probably will change
        require(currentState == States.RFP, "Call from wrong state");

        currentState == States.END;
        emit DealEndedUp(States.RFP);
    }

    function approveApplication(address contractorForDeal) external onlyClient {
        require(currentState == States.RFP, "Call from wrong state");
        require(contractorForDeal != address(0), "Invalid address for contractor");
        require(
            _hasProvidedApplication(contractorForDeal),
            "Provided contractor hasn't got any applications"
        );

        contractor = contractorForDeal;
        currentState = States.WAIT4DEPOSIT;
        emit ContractorChosen(contractor);
    }

    function _hasProvidedApplication(address checkingContractor) internal view returns (bool) {
        Application storage a = applications[checkingContractor];
        if (bytes(a.description).length == 0) {
            return false;
        }
        return true;
    }
}