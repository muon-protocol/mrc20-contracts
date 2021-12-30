// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract MRC20 is ERC20, ERC20Burnable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    uint8 private immutable decimals_;

    /**
     * @dev Deployers need to grant MINTER_ROLE,
     * BURNER_ROLE to MRC20Bridge to enable crosschain transfers.
     *
     * MRC20Bridge burns the tokens on the source chain and mint on
     * the destination chain
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) ERC20(_name, _symbol) {
        decimals_ = _decimals;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        //TODO: grant burner/minter roles to MRC20 bridge
    }

    function decimals() public view virtual override returns (uint8) {
        return decimals_;
    }

    /**
     * @dev When MRC20Bridge has MINTER_ROLE,
     * the users do not need to Approve for running
     * the crosschain transactions. Otherwise, the holders
     * should Approve before using the MRC20Bridge.
     *
     */
    function burnFrom(address from, uint256 amount) public override{
        if(hasRole(BURNER_ROLE, msg.sender)){
            _burn(from, amount);
        }else{
            super.burnFrom(from, amount);
        }
    }

    /**
     * @dev To enable crosschain transfers, 
     * MRC20Bridge should have MINTER_ROLE
     */
    function mint(address to, uint256 amount)
        external
        onlyRole(MINTER_ROLE)
    {
        _mint(to, amount);
    }
}
