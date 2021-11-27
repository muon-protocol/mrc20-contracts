// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BloodToken is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    uint8 private immutable decimals_;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) public ERC20(_name, _symbol) {
        decimals_ = _decimals;
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(BURNER_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function decimals() public view virtual override returns (uint8) {
        return decimals_;
    }

    function burn(address from, uint256 amount)
        external
        onlyRole(BURNER_ROLE)
        returns (bool)
    {
        _burn(from, amount);
        return false;
    }

    function mint(address to, uint256 amount)
        external
        onlyRole(MINTER_ROLE)
        returns (bool)
    {
        _mint(to, amount);
        return true;
    }
}
