# Upgradable Smart Contracts - UUPS Proxy pattern

## Introduction

Create an upgradable smart contract by using OpenZeppelin. There are several common patterns for upgradable contract. You can get more from this article.

[The State of Smart Contract Upgrades](https://blog.openzeppelin.com/the-state-of-smart-contract-upgrades/)

This is one of these pattern's impelementation `Universal upgradeable proxies (UUPS proxies)` pattern and tutorial is below:

[UUPS Proxies: Tutorial (Solidity + JavaScript)](https://forum.openzeppelin.com/t/uups-proxies-tutorial-solidity-javascript/7786)

We'll create our first smart contract named `Box` with 2 very basic functions `store()` and `retrieve()` for write and read the state variable. Then create an second smart contract `BoxV2` and add another function `increment()` to add specified value to state variable.

The contract doesn't do much but just shows how to use OpenZeppelin upgradeble plugin to make contract can be upgraded.

## Pre-requisite

- Hardhat + Ethers.js
- Solidity v0.8.11
- OpenZeppelin

## Configuration and Setting

- Creating a new Hardhat project

  ```shell
  # Create project directory
  mkdir uups-proxies && cd $_

  # Choose basic sample project setting
  npx hardhat

  # Install neccessary OpenZeppelin libraries
  npm i -D @openzeppelin/contracts-upgradeable @openzeppelin/hardhat-upgrades

  # dotenv for reading environment variables
  npm i -D dotenv
  ```

- Create an account on Rinkeby testnet and obtain private key

  Use MetaMask wallet client to create an account on Rinkeby testnet and export the private key. Remember to get suffecient ETH from faucet first. You can reqest test ETH from the following link:

  - [Request testnet LINK](https://faucets.chain.link/rinkeby)

- Create a .env file

  ```plaintext
  RINKEBY_RPC_URL=https://rinkeby.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161

  PRIVATE_KEY=[REPLACE WITH YOUR PRIVATE KEY]
  ```

- Config Hardhat configuration file

  ```javascript
  //  hardhat.config.js
  require("@nomiclabs/hardhat-ethers");
  require("@openzeppelin/hardhat-upgrades");

  // Read Rinkeby RPC url and private key from environment variable
  require("dotenv").config();
  const RINKEBY_RPC_URL = process.env.RINKEBY_RPC_URL;
  const PRIVATE_KEY = process.env.PRIVATE_KEY;

  module.exports = {
    solidity: "0.8.11",
    networks: {
      rinkeby: {
        url: RINKEBY_RPC_URL,
        accounts: [PRIVATE_KEY],
        gas: 2100000,
      },
    },
  };
  ```

## Impelement

### Create first basic Box smart contract

Create a very simple smart contract with 2 basic functions `store()` and `retrieve()`. `store()` can update the state variable `value`. `retrieve()` just read the value.

We import three OpenZeppelin library to impelement upgradable contract.Because this is upgradable contract. Do not in initialize the contract state in the constructor. Instead we have an initializer function decorated with the modifier initializer. This is UUPS proxies pattern requirements.

```javascript
// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Box is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    uint256 private value;

    // Because this is upgradable contract
    // Do not in initialize the contract state in the constructor
    // Instead we have an initializer function decorated with the modifier initializer
    function initialize() initializer public {
      __Ownable_init();
      __UUPSUpgradeable_init();
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function _authorizeUpgrade(address) internal override onlyOwner {}

    event ValueChanged(uint256 newValue);

    // Stores a new value in the contract
    function store(uint256 newValue) public {
        value = newValue;
        emit ValueChanged(newValue);
    }

    // Reads the last stored value
    function retrieve() public view returns (uint256) {
        return value;
    }
}
```

### Create Test and try to deploy

Test before we deploy to live testnet. We first use `deployProxy()` function to deploy first version contract.

```javascript
// test/Box.test.ts
const { ethers, upgrades } = require("hardhat");

let contract_proxy_address;

describe("Test Box deploy", function () {
  it("Deploying Box v1", async function () {
    const Box = await ethers.getContractFactory("Box");
    // The { kind: "uups" } option is the key point and requirement for UUPS implementation here.
    const box = await upgrades.deployProxy(Box, { kind: "uups" });
    contract_proxy_address = box.address;
  });
});
```

Run the test file with Hardhat cli

```shell
npx hardhat test
```

![result of test v1](https://i.imgur.com/OW9Y4mk.png)

## Create Box V2 contract

Let's duplicate origin `Box.sol` and rename to `BoxV2.sol`. And just add an new function `increment()`. Get rid off the code `constructor() initializer {}`. Because upgrade contract doesn't need the constructor.

```javascript
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract BoxV2  is Initializable, UUPSUpgradeable, OwnableUpgradeable {

    uint256 private value;

    // Use initialize function instead of constructor to meet special requirements of UUPS proxiex pattern
    function initialize() initializer public {
      __Ownable_init();
      __UUPSUpgradeable_init();
    }

    // Make sure that the contract can be upgraded by contract owner
    function _authorizeUpgrade(address) internal override onlyOwner {}

    // Emitted when the stored value changes
    event ValueChanged(uint256 newValue);

    // Stores a new value in the contract
    function store(uint256 newValue) public {
        value = newValue;
        emit ValueChanged(newValue);
    }

    // Reads the last stored value
    function retrieve() public view returns (uint256) {
        return value;
    }

    // New function for V2
    function increment() public {
        value = value + 1;
        emit ValueChanged(value);
    }
}
```

### Add test for V2 contract

Edit test script and add another test case. Upgrade contract with `upgradeProxy()` and V1 contract's address.

```javascript
// test/Box.test.ts
const { ethers, upgrades } = require("hardhat");

let contract_proxy_address;

describe("Test Box v1 deploy", function () {
  it("Deploying Box v1", async function () {
    const Box = await ethers.getContractFactory("Box");
    // The { kind: "uups" } option is the key point and requirement for UUPS implementation here.
    const box = await upgrades.deployProxy(Box, { kind: "uups" });
    contract_proxy_address = box.address;
  });

  it("Upgrading to v2", async function () {
    const BoxV2 = await ethers.getContractFactory("BoxV2");
    await upgrades.upgradeProxy(contract_proxy_address, BoxV2);
  });
});
```

Run the test file with Hardhat cli

```shell
npx hardhat test
```

![result of test v2](https://i.imgur.com/NI9jDAm.png)

### Create scripts for deploy the V1 contract

Create a deploy script `scripts/deploy.js` for deploy V1 contract. Notice the `{kind: "uups"}` option in the code. It's key point for UUPS proxies pattern.

```javascript
// scripts/deploy.js
const { ethers, upgrades } = require("hardhat");

async function main() {
  const Box = await ethers.getContractFactory("Box");
  // The { kind: "uups" } option is the key point and requirement for UUPS implementation here.
  const box = await upgrades.deployProxy(Box, { kind: "uups" });
  console.log("Box V1 deployed to:", box.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
```

Run the script to deploy contract to Rinkeby testnet.

```shell
npx hardhat run scripts/deploy.js --network rinkeby
```

Obtain the contract address after run the script. We'll use this later.

`0x9b5B064626074c807c29EFcE716d49600317688D`

![deploy v1 result](https://imgur.com/UGFeLBy.png)

Check them on Etherscan after deploy successfully.

[https://rinkeby.etherscan.io/address/0x9b5B064626074c807c29EFcE716d49600317688D](https://rinkeby.etherscan.io/address/0x9b5B064626074c807c29EFcE716d49600317688D)

### Interact with deployed contract

Use Hardhat console to interact with deployed contract and verify contract works as well.

```shell
npx hardhat console --network rinkeby
```

Enter following commands in Hardhat console to interact with contract. We'll get contract instance first, then read the state variable to see the value. Next we use `store()` to write new value, and read value again to see if value changed.

```bash
const Box = await ethers.getContractFactory("Box")
const box = Box.attach("0x9b5B064626074c807c29EFcE716d49600317688D")
(await box.retrieve()).toString();
await box.store(10)
(await box.retrieve()).toString();
```

![result of v1](https://imgur.com/hiSNJG4.png)

Transaction details on Etherscan:

[https://rinkeby.etherscan.io/tx/0xb3a4c186f566b4738f0f0a2b84cbb7d3f03dd348495e9f6a25800de85afe3e80](https://rinkeby.etherscan.io/tx/0xb3a4c186f566b4738f0f0a2b84cbb7d3f03dd348495e9f6a25800de85afe3e80)

Quit the console mode with hit `CTRL+C` twice.

### Create script for upgrade contract V2

Remember to fill in the `BOX_ADDRESS` with the address of the Box contract. Then use `upgradeProxy()` to do a contract upgrading. `{kind: "uups"}` option is not neccessary for upgrade.

```javascript
// scripts/upgrade.js
const { ethers, upgrades } = require("hardhat");

// Fill in the BOX_ADDRESS variable below with the address of the Box contract
const BOX_ADDRESS = "0x9b5B064626074c807c29EFcE716d49600317688D";

async function main() {
  const BoxV2 = await ethers.getContractFactory("BoxV2");
  const box = await upgrades.upgradeProxy(BOX_ADDRESS, BoxV2);
  console.log("Box upgraded");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
```

Run the script to upgrade contract to V2

```shell
npx hardhat run scripts/upgrade.js --network rinkeby
```

### Interact with upgraded contract

We will interact with upgraded contract and contract address is still same as contract v1 so that we can proove contract was upgraded.

```shell
npx hardhat console --network rinkeby
```

Enter following commands in Hardhat console to interact with contract. Upgraded contract address still same as V1.

```bash
const BoxV2 = await ethers.getContractFactory("BoxV2")
const boxV2 = BoxV2.attach("0x9b5B064626074c807c29EFcE716d49600317688D")
(await boxV2.retrieve()).toString()
await boxV2.increment()
(await boxV2.retrieve()).toString()
```

![result for v2 upgrade](https://i.imgur.com/lh5cx3Y.png)

Transaction details on Etherscan:

[https://rinkeby.etherscan.io/tx/0x3b81f913af374904bd525582d708cb8d46d3dd500f65dc3a45ffe43d9a7c42fd](https://rinkeby.etherscan.io/tx/0x3b81f913af374904bd525582d708cb8d46d3dd500f65dc3a45ffe43d9a7c42fd)

## References

- [OpenZeppelin - Proxies](https://docs.openzeppelin.com/contracts/4.x/api/proxy)
- [OpenZeppelin - Upgrades Plugins](https://docs.openzeppelin.com/upgrades-plugins/1.x/)
- [Not All Smart Contracts Are Immutable — Create Upgradable Smart Contracts](https://betterprogramming.pub/not-all-smart-contracts-are-immutable-create-upgradable-smart-contracts-e4e933b7b8a9)
- [UUPS Proxies: Tutorial (Solidity + JavaScript)](https://forum.openzeppelin.com/t/uups-proxies-tutorial-solidity-javascript/7786)
- [The State of Smart Contract Upgrades](https://blog.openzeppelin.com/the-state-of-smart-contract-upgrades/)
