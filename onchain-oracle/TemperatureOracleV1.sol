// Sources flattened with hardhat v2.9.3 https://hardhat.org

// File @openzeppelin/contracts/utils/Context.sol@v4.6.0

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/Ownable.sol@v4.6.0

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File contracts/TemperatureOracleV1.sol

pragma solidity 0.8.4;

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
