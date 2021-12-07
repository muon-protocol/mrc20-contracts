// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IMuonV02.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface StandardToken {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function decimals() external returns (uint8);

    function mint(address reveiver, uint256 amount) external returns (bool);

    function burn(address sender, uint256 amount) external returns (bool);
}

contract MRC20Presale is Ownable {
    using ECDSA for bytes32;

    IMuonV02 muon;

    mapping(address => uint256) public balances;
    mapping(address => uint256) public lastTimes;

    uint8 constant APP_ID = 6;

    bool public running = true;

    uint256 public maxMuonDelay = 5 minutes;
    address public mintToken;

    event Deposit(
        address token,
        uint256 tokenPrice,
        uint256 amount,
        uint256 time,
        address fromAddress,
        address forAddress,
        uint256[] addressMaxCap
    );

    modifier isRunning() {
        require(running, "!running");
        _;
    }

    constructor(address _muon,address mintToken) {
        muon = IMuonV02(_muon);
        mintToken=mintToken;
    }

    function getChainID() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function deposit(
        address token,
        uint256 tokenPrice,
        uint256 amount,
        uint256 time,
        address forAddress,
        uint256[] memory addressMaxCap,
        bytes calldata _reqId,
        IMuonV02.SchnorrSign[] calldata _sigs
    ) public payable isRunning {
        require(_sigs.length > 0, "!sigs");
        require(addressMaxCap[1] == getChainID(), "Invalid Chain ID");

        bytes32 hash = keccak256(
            abi.encodePacked(
                token,
                tokenPrice,
                amount,
                time,
                forAddress,
                addressMaxCap[0],
                addressMaxCap[1],
                APP_ID
            )
        );
        hash = hash.toEthSignedMessageHash();

        bool verified = muon.verify(_reqId, uint256(hash), _sigs);
        require(verified, "!verified");

        // check max
        uint256 usdAmount = (amount * tokenPrice) /
            (10**(token == address(0) ? 18 : StandardToken(token).decimals()));
        require(balances[forAddress] + usdAmount <= addressMaxCap[0], ">max");

        require(time + maxMuonDelay > block.timestamp, "muon: expired");

        require(time - lastTimes[forAddress] > maxMuonDelay, "duplicate");

        lastTimes[forAddress] = time;

        if (token == address(0)) {
            require(amount == msg.value, "amount err");
        } else {
            StandardToken tokenCon = StandardToken(token);
            tokenCon.transferFrom(address(msg.sender), address(this), amount);
            mintToken.mint(address(msg.sender), amount);
        }

        emit Deposit(
            token,
            tokenPrice,
            amount,
            time,
            msg.sender,
            forAddress,
            addressMaxCap
        );
    }

    function setMuonContract(address addr) public onlyOwner {
        muon = IMuonV02(addr);
    }

    function setIsRunning(bool val) public onlyOwner {
        running = val;
    }

    function setMaxMuonDelay(uint256 delay) public onlyOwner {
        maxMuonDelay = delay;
    }

    function setMintToken(address mintToken) public onlyOwner{
        mintToken=mintToken
    }

    function emergencyWithdrawETH(uint256 amount, address addr)
        public
        onlyOwner
    {
        require(addr != address(0));
        payable(addr).transfer(amount);
    }

    function emergencyWithdrawERC20Tokens(
        address _tokenAddr,
        address _to,
        uint256 _amount
    ) public onlyOwner {
        StandardToken(_tokenAddr).transfer(_to, _amount);
    }
}
