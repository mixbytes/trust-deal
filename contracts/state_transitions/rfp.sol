pragma solidity 0.5.7;

import './base.sol';

contract DealRFPStateLogic is BaseDealStateTransitioner {
    event ContractorChosen(address contractor);

    function newApplication(
        string calldata application,
        address[] calldata workers,
        uint256[] calldata rates
    )
        external
    {
        require(currentState == States.RFP, ERROR_WRONG_STATE_CALL);
        require(workers.length == rates.length,"Workers and rates arrays should be equal");
        require(workers.length > 0 && workers.length < 100, "Array params have wrong lengths");
        require(bytes(application).length > 0, "Empty application description provided");
        require(
            msg.sender != reviewer && msg.sender != client,
            "Client or contractor can't add applications"
        );

        applications[msg.sender] = Application(application);
        mapping(address => uint256) storage e = applications[msg.sender].employeesRates;
        for (uint8 i; i < workers.length; i++) {
            require(
                workers[i] != address(0) && rates[i] != 0,
                "Wrong application params: address or related rate are equal to 0"
            );
            require(e[workers[i]] == 0, "Application state same worker twice");
            e[workers[i]] = rates[i];
        }
        emit ApplicationAdded(msg.sender, application, workers, rates);
    }

    function cancelRFP() external onlyClient {
        require(currentState == States.RFP, ERROR_WRONG_STATE_CALL);

        currentState = States.END;
        emit DealEndedUp(States.RFP);
    }

    function approveApplication(address payable contractorForDeal) external onlyClient {
        require(currentState == States.RFP, ERROR_WRONG_STATE_CALL);
        require(contractorForDeal != address(0), ERROR_ZERO_ADDRESS);
        require(
            hasProvidedApplication(contractorForDeal),
            "Provided contractor hasn't got any applications"
        );

        contractor = contractorForDeal;
        currentState = States.WAIT4DEPOSIT;
        emit ContractorChosen(contractor);
    }

    function getReviewer() external view returns (address) {
        require(currentState >= States.RFP, ERROR_WRONG_STATE_CALL);
        return reviewer;
    }

    function getInfo() external view returns (
        States state,
        address dealClient,
        string memory shortName,
        string memory task,
        uint32 iterationTimeSeconds,
        IERC20 meanOfPayment,
        address dealReviewer,
        uint16 feeBPS,
        uint32 reviewIntervalSeconds
    ) {
        require(currentState >= States.RFP, ERROR_WRONG_STATE_CALL);
        state = currentState;
        dealClient = client;
        shortName = taskShortName;
        task = taskDescription;
        iterationTimeSeconds = iterationDuration;
        meanOfPayment = dealMeanOfPayment;
        dealReviewer = reviewer;
        feeBPS = reviewerFeeBPS;
        reviewIntervalSeconds = reviewerDecisionDuration;
    }

    function hasProvidedApplication(address checkingContractor) internal view returns (bool) {
        Application storage a = applications[checkingContractor];
        if (bytes(a.description).length == 0) {
            return false;
        }
        return true;
    }
}