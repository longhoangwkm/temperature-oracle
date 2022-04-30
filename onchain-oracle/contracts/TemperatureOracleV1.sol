pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract TemperatureOracleV1 is Ownable {
    uint256 requestId;
    uint256 minQuorum = 2;
    uint256 latestTemperature;
    uint256 latestUpdatedAt;

    struct Response {
        address provider;
        uint256 value;
    }

    struct Request {
        uint256 consensusTemperature;
        bool hasConsensus;
        uint256 totalVoted;
        mapping(uint256 => Response) responses;
        mapping(address => bool) hasVoted; // TODO
    }

    mapping(address => bool) providers;
    mapping(uint256 => Request) requests;

    event NewRequested(uint256 requestId, address requester);
    event TemperatureUpdated(uint256 requestId, uint256 consensusTemperature);
    event ProviderUpdated(address provider, bool isAllowed);
    event MinQuorumUpdated(uint256 minQuorum);

    modifier onlyProvider() {
        require(
            providers[msg.sender] == true,
            "TemperatureOracleV1: invalid provider"
        );
        _;
    }

    function setMinQuorum(uint256 _minQuorum) external onlyOwner {
        minQuorum = _minQuorum;

        emit MinQuorumUpdated(_minQuorum);
    }

    function setProvider(address provider, bool isAllowed) external onlyOwner {
        providers[provider] = isAllowed;

        emit ProviderUpdated(provider, isAllowed);
    }

    function getTemperature() external view returns (uint256, uint256) {
        return (latestTemperature, latestUpdatedAt);
    }

    function getTemperatureByRequestId(uint256 _requestId)
        external
        view
        returns (uint256)
    {
        return requests[_requestId].consensusTemperature;
    }

    function createRequest() external returns (uint256) {
        emit NewRequested(requestId, msg.sender);
        return requestId++;
    }

    function updateTemperature(uint256 requestId, uint256 temperature)
        public
        onlyProvider
        returns (bool hasConsensus)
    {
        Request storage request = requests[requestId];

        // A provider only can vote one time per requestId
        require(
            request.hasVoted[msg.sender] == false,
            "TemperatureOracleV1: has voted this requestId"
        );

        // Save response
        Response memory response;
        response.provider = msg.sender;
        response.value = temperature;

        request.totalVoted = request.totalVoted + 1;
        request.responses[request.totalVoted] = response;
        request.hasVoted[msg.sender] = true;

        // Check consensus
        uint256 currentQuorum = 0;

        for (uint256 voteNo = 1; voteNo <= request.totalVoted; voteNo++) {
            // TODO
            // This way too too ideal,
            // in practice it is unlikely that the input is the same even to 2 decimal places
            //
            // We assume 1505 (15.05 C degree) ~ 1567 (15.67 C degree)
            if (abs(temperature, request.responses[voteNo].value) <= 100) {
                currentQuorum++;
                if (currentQuorum >= minQuorum) {
                    request.consensusTemperature = temperature;
                    request.hasConsensus = true;
                    latestTemperature = temperature;
                    latestUpdatedAt = block.timestamp;

                    emit TemperatureUpdated(requestId, temperature);

                    return true;
                }
            }
        }

        return false;
    }

    function abs(uint256 a, uint256 b) private pure returns (uint256) {
        return a > b ? a - b : b - a;
    }
}
