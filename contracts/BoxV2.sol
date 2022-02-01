// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// contract address:     
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
