// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './MRC20.sol';

contract BloodToken is MRC20 {
    
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) MRC20(_name, _symbol, _decimals) {
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(BURNER_ROLE, msg.sender);
    }

}
