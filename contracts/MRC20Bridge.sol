// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IMuonV02.sol";
import "./IMRC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MRC20Bridge is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    /**
     * @dev `AddToken` and `setSideContract`
     * are using this role.
     *
     * This role could be granted another contract to let a Muon app
     * manage the tokens. The token deployer will be verified by
     * a Muon app and let the deployer add new tokens to the MTC20Bridges.
     */
    bytes32 public constant TOKEN_ADDER_ROLE = keccak256("TOKEN_ADDER");

    using ECDSA for bytes32;

    uint32 public constant APP_ID = 5; // muon's  app id

    IMuonV02 public muon;

    uint256 public network; // current chain id

    // tokenId => tokenContractAddress
    mapping(uint256 => address) public tokens;
    mapping(address => uint256) public ids;

    event AddToken(address addr, uint256 tokenId);

    event Deposit(uint256 txId);

    event Claim(
        address indexed user,
        uint256 txId,
        uint256 fromChain,
        uint256 amount,
        uint256 tokenId
    );
    /* ========== STATE VARIABLES ========== */
    struct TX {
        // uint256 txId;
        uint256 tokenId;
        uint256 amount;
        uint256 toChain;
        address user;
    }

    uint256 public lastTxId = 0; // unique id for deposit tx
    mapping(uint256 => TX) public txs;

    // source chain => (tx id => false/true)
    mapping(uint256 => mapping(uint256 => bool)) public claimedTxs;

    uint256 public minReqSigs; // minimum required tss
    uint256 public fee;
    uint256 public feeScale = 1e6;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _muon,
        uint256 _minReqSigs,
        uint256 _fee
    ) {
        network = getExecutingChainID();
        muon = IMuonV02(_muon);
        minReqSigs = _minReqSigs;
        fee = _fee;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    function deposit(
        uint256 amount,
        uint256 toChain,
        uint256 tokenId
    ) external returns (uint256) {
        return depositFor(msg.sender, amount, toChain, tokenId);
    }

    function depositFor(
        address user,
        uint256 amount,
        uint256 toChain,
        uint256 tokenId
    ) public returns (uint256 txId) {
        require(toChain != network, "Bridge: selfDeposit");
        require(tokens[tokenId] != address(0), "Bridge: unknown tokenId");

        IMRC20 token = IMRC20(tokens[tokenId]);
        token.burnFrom(msg.sender, amount);

        txId = ++lastTxId;
        txs[txId] = TX({
            tokenId: tokenId,
            toChain: toChain,
            amount: amount,
            user: user
        });

        emit Deposit(txId);

        return txId;
    }

    function claim(
        address user,
        uint256 amount,
        uint256 fromChain,
        uint256 toChain,
        uint256 tokenId,
        uint256 txId,
        bytes calldata _reqId,
        IMuonV02.SchnorrSign[] calldata sigs
    ) public {
        require(toChain == network, "Bridge: toChain should equal network");
        require(
            sigs.length >= minReqSigs,
            "Bridge: insufficient number of signatures"
        );

        {
            bytes32 hash = keccak256(
                abi.encodePacked(
                    abi.encodePacked(APP_ID),
                    abi.encodePacked(txId, tokenId, amount),
                    abi.encodePacked(fromChain, toChain, user)
                )
            );

            require(
                muon.verify(_reqId, uint256(hash), sigs),
                "Bridge: not verified"
            );
        }

        require(!claimedTxs[fromChain][txId], "Bridge: already claimed");
        require(tokens[tokenId] != address(0), "Bridge: unknown tokenId");

        amount -= (amount * fee) / feeScale;
        IMRC20 token = IMRC20(tokens[tokenId]);

        token.mint(user, amount);

        claimedTxs[fromChain][txId] = true;
        emit Claim(user, txId, fromChain, amount, tokenId);
    }

    /* ========== VIEWS ========== */

    function pendingTxs(uint256 fromChain, uint256[] calldata _ids)
        public
        view
        returns (bool[] memory unclaimedIds)
    {
        unclaimedIds = new bool[](_ids.length);
        for (uint256 i = 0; i < _ids.length; i++) {
            unclaimedIds[i] = claimedTxs[fromChain][_ids[i]];
        }
    }

    function getTx(uint256 _txId)
        public
        view
        returns (
            uint256 txId,
            uint256 tokenId,
            uint256 amount,
            uint256 fromChain,
            uint256 toChain,
            address user
        )
    // uint256 timestamp
    {
        txId = _txId;
        tokenId = txs[_txId].tokenId;
        amount = txs[_txId].amount;
        fromChain = network;
        toChain = txs[_txId].toChain;
        user = txs[_txId].user;
    }

    function getExecutingChainID() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function addToken(uint256 tokenId, address tokenAddress)
        external
        onlyRole(TOKEN_ADDER_ROLE)
    {
        tokens[tokenId] = tokenAddress;
    }

    function getTokenId(address _addr) public view returns (uint256) {
        return ids[_addr];
    }

    function setNetworkID(uint256 _network) external onlyRole(ADMIN_ROLE) {
        network = _network;
    }

    function setMuonContract(address addr) public onlyRole(ADMIN_ROLE) {
        muon = IMuonV02(addr);
    }

    function setFee(uint256 _fee) external onlyRole(ADMIN_ROLE) {
        fee = _fee;
    }

    function setMinReqSigs(uint256 _minReqSigs) external onlyRole(ADMIN_ROLE) {
        minReqSigs = _minReqSigs;
    }

    function emergencyWithdrawETH(uint256 amount, address addr)
        external
        onlyRole(ADMIN_ROLE)
    {
        require(addr != address(0));
        payable(addr).transfer(amount);
    }

    function emergencyWithdrawERC20Tokens(
        address _tokenAddr,
        address _to,
        uint256 _amount
    ) external onlyRole(ADMIN_ROLE) {
        IERC20(_tokenAddr).transfer(_to, _amount);
    }
}
