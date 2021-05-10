// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.12;

import "./HordUpgradable.sol";

/**
 * Validator contract.
 * @author Nikola Madjarevic
 * Date created: 8.5.21.
 * Github: madjarevicn
 */
contract Validator is HordUpgradable {

    address public signatoryAddress;

    // Set initial signatory address and Hord congress
    function initialize(
        address _signatoryAddress,
        address _hordCongress,
        address _maintainersRegistry
    )
    public
    initializer
    {
        signatoryAddress = _signatoryAddress;
        setCongressAndMaintainers(_hordCongress, _maintainersRegistry);
    }

    // Set / change signatory address
    function setSignatoryAddress(
        address _signatoryAddress
    )
    public
    onlyHordCongress
    {
        require(_signatoryAddress != address(0));
        signatoryAddress = _signatoryAddress;
    }

    /**
     * @notice          Function to verify withdraw parameters and if signatory signed message
     * @param           signedMessage is the message to verify
     */
    function verifyWithdraw(
        bytes memory signedMessage,
        uint256 tokenId,
        uint256 amount
    )
    external
    view
    returns (bool)
    {
        address messageSigner = recoverSignature(signedMessage, tokenId, amount);
        return messageSigner == signatoryAddress;
    }

    /**
     * @notice          Function to can check who signed the message
     * @param           signedMessage is the message to verify
     */
    function recoverSignature(
        bytes memory signedMessage,
        uint256 tokenId,
        uint256 amount
    )
    public
    pure
    returns (address)
    {
        // Generate hash
        bytes32 hash = keccak256(
            abi.encodePacked(
                keccak256(abi.encodePacked('bytes binding tokens burn')),
                keccak256(abi.encodePacked(tokenId, amount))
            )
        );

        // Recover signer message from signature
        return recoverHash(hash,signedMessage,0);
    }

    function recoverHash(bytes32 hash, bytes memory sig, uint idx) public pure returns (address) {
        // same as recoverHash in utils/sign.js
        // The signature format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        require (sig.length >= 65+idx, 'bad signature length');
        idx += 32;
        bytes32 r;
        assembly
        {
            r := mload(add(sig, idx))
        }

        idx += 32;
        bytes32 s;
        assembly
        {
            s := mload(add(sig, idx))
        }

        idx += 1;
        uint8 v;
        assembly
        {
            v := mload(add(sig, idx))
        }
        if (v >= 32) { // handle case when signature was made with ethereum web3.eth.sign or getSign which is for signing ethereum transactions
            v -= 32;
            bytes memory prefix = "\x19Ethereum Signed Message:\n32"; // 32 is the number of bytes in the following hash
            hash = keccak256(abi.encodePacked(prefix, hash));
        }
        if (v <= 1) v += 27;
        require(v==27 || v==28,'bad sig v');
        //https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/cryptography/ECDSA.sol#L57
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, 'bad sig s');
        return ecrecover(hash, v, r, s);

    }

}
