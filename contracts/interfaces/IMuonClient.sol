// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMuonClient {
    struct SchnorrSign {
        uint256 signature;
        address owner;
        address nonce;
    }

    struct PublicKey {
        uint256 x;
        uint8 parity;
    }

    function muonVerify(
        bytes calldata reqId,
        uint256 hash,
        SchnorrSign memory signature,
        PublicKey memory pubKey
    ) external returns (bool);
}
