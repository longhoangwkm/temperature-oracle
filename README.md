## Demo
Build a simple  Oracle Contract

## Solution

We will create an oracle service that can get data from sensor. The oracle will save all the requests and answers and will have a predefined set of stakeholders.

These are the accounts running the node.js service that getting data and returns a response to the oracle. The oracle also has a minimum number of equal responses that it must receive in order to confirm that the answer provided is valid.

This way, if competing parties depend on the oracle to power their contracts and one of the parties (nodes) becomes rogue or tries to manipulate the result, it can't because they agreed on a predefined quorum of equal answers.

> How to ensure we are decentralized and without a single point of failure?

We allow multiple offchain oracle nodes to provide data, so once one of them is down, it won't affect data delivery.

> How do we determine who can submit the temperature?

We save provider data each submitting time

> How can we make sure no one is submitting wrong values? 

Because we use the majority mechanism, the error may occur but does not affect the calculation process.

> How do we detect outliers?

We can build subgraph or backend to track submit value each request by provider and visualize that information to check outliers.
We can build a bot, checking outlier by InterQuartile range (IQR) and stastical test to detect and call `setProvider(provider, false)` to remove them out.

**Solution1**

1. Client Oracle request update temperature
2. Oracle nodes listen NewRequest event to check temp
3. Oracle nodes submit temp included RequestId
4. Client Oracle can call `getTemperature()` to get data

**Solution2**

- Oracle owner can allow provider set endpoint url to using `provable_query` from `provable-eth-api/provableAPI.sol`.
- Query all provider Urls and calculate at callback function
```
    function __callback(bytes32 _myid, string memory _result) public {
        // calculate and save to results
    }

    function currentTemp() public payable {
        // loop to query
        for (int providerNo; providerNo < providerNo.length; providerNo ++) {
            provable_query("URL", "xml(providers[providerNo].url");
        }
    }
```
## Architecture

This oracle will comprise two components. The on-chain oracle (a smart contract) and the off-chain oracle service (node.js server).

<img src="https://github.com/longhoangwkm/temperature-oracle/blob/master/docs/image/temp-oracle.png" alt="System Diagram">

## Setup

```
$ git clone git@github.com:longhoangwkm/temperature-oracle.git
$ cd temperature-oracle
$ cd onchain-oracle
$ npm install
$ npx hardhat compile
$ npx hardhat test
```

Notes: Backend scripts TODO