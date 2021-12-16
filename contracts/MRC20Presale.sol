// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IMuonV02.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

interface IMRC20 is IERC20 {
  function decimals() external returns (uint8);

  function mint(address reveiver, uint256 amount) external returns (bool);

  function burn(address sender, uint256 amount) external returns (bool);
}

contract MRC20Presale is Ownable {
  using ECDSA for bytes32;

  IMuonV02 public muon;

  mapping(address => uint256) public balances;
  mapping(address => uint256) public lastTimes;

  uint8 constant APP_ID = 6;

  bool public running = true;

  uint256 public maxMuonDelay = 5 minutes;
  address public presaleToken;

  event Deposit(
    address token,
    uint256 presaleTokenPrice,
    address fromAddress,
    address forAddress,
    uint256[5] extraParameters
  );

  modifier isRunning() {
    require(running, '!running');
    _;
  }

  constructor(address _muon, address _presaleToken) {
    muon = IMuonV02(_muon);
    presaleToken = _presaleToken;
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
    uint256 presaleTokenPrice,
    address forAddress,
    uint256[5] memory extraParameters,
    // [0]=allocation,[1]=chainId,[2]=tokenPrice, [3]=amount ,[4]=time,
    bytes calldata reqId,
    IMuonV02.SchnorrSign[] calldata sigs
  ) public payable isRunning {
    require(sigs.length > 0, '!sigs');
    require(extraParameters[1] == getChainID(), 'Invalid Chain ID');

    bytes32 hash = keccak256(
      abi.encodePacked(
        token,
        presaleTokenPrice,
        extraParameters[3],
        extraParameters[4],
        forAddress,
        extraParameters[0],
        extraParameters[1],
        extraParameters[2],
        APP_ID
      )
    );

    bool verified = muon.verify(reqId, uint256(hash), sigs);
    require(verified, '!verified');

    // check max
    uint256 usdAmount = token != address(0)
      ? (extraParameters[3] * extraParameters[2]) /
        (10**IMRC20(token).decimals())
      : (extraParameters[3] * extraParameters[2]) / (10**18);

    require(balances[forAddress] + usdAmount <= extraParameters[0], '>max');

    require(
      extraParameters[4] + maxMuonDelay > block.timestamp,
      'muon: expired'
    );

    require(
      extraParameters[4] - lastTimes[forAddress] > maxMuonDelay,
      'duplicate'
    );

    lastTimes[forAddress] = extraParameters[4];

    uint256 mintAmount = (usdAmount * (10**IMRC20(presaleToken).decimals())) /
      presaleTokenPrice;

    require(
      token != address(0) || extraParameters[3] == msg.value,
      'amount err'
    );

    if (token != address(0)) {
      IMRC20(token).transferFrom(
        address(msg.sender),
        address(this),
        extraParameters[3]
      );
    }
    IMRC20(presaleToken).mint(address(msg.sender), mintAmount);

    emit Deposit(
      token,
      presaleTokenPrice,
      msg.sender,
      forAddress,
      extraParameters
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

  function setpresaleToken(address addr) public onlyOwner {
    presaleToken = addr;
  }

  function emergencyWithdrawETH(uint256 amount, address addr) public onlyOwner {
    require(addr != address(0));
    payable(addr).transfer(amount);
  }

  function emergencyWithdrawERC20Tokens(
    address _tokenAddr,
    address _to,
    uint256 _amount
  ) public onlyOwner {
    IMRC20(_tokenAddr).transfer(_to, _amount);
  }
}
