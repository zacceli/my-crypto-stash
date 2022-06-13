//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MerkleTreeWithHistory.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";



abstract contract MyCryptoStash is MerkleTreeWithHistory, ReentrancyGuard{
    uint256 public denomination;

    mapping(bytes32 => bool) public nullifierHashes;
    mapping(bytes32 => bool) public commitments;

    constructor(address _hasher, uint256 _denomination, uint32 _merkleTreeHeight) MerkleTreeWithHistory(_merkleTreeHeight, _hasher){
        require(_denomination > 0, "denomination should be greater than 0.");
        denomination = _denomination;
    }

    function _processDeposit() internal virtual;
    
    function deposit(bytes32 _commitment) external payable nonReentrant {
        require(!commitments[_commitment], "The commitment has already been submitted.");
        uint32 insertedIndex = _insert(_commitment);
        commitments[_commitment] = true;
        _processDeposit();

        // emit event later
       
    }

    function _processWithdraw(address payable _recipient, address payable _relayer, uint256 _fee, uint256 _refund) internal {
        require(msg.value == 0, "Message value is supposed to be zero for ETH instance");

        (bool success, ) = _recipient.call{ value: (denomination - _fee) }("");
        require(success, "payment to _recipient did not go thru");
        if (_fee > 0){
            (success, ) = _relayer.call{ value: _fee }("");
            require(success, "payment to the _relayer did not go thru.");
        }
    }

    function withdraw(
        bytes calldata proof,
        bytes32 _root,
        bytes32 _nullifierHash,
        address payable _recipient,
        address payable _relayer,
        uint256 _fee,
        uint256 _refund,
        uint64 _toBeUnlocked
        ) external payable nonReentrant {
            require(_fee <= denomination, "Fee exceeds transfer value");
            require(!nullifierHashes[_nullifierHash], "The note has been already spent.");
            require(isKnownRoot(_root), "Cannot find your merkle root");

            nullifierHashes[_nullifierHash] = true;
            _processWithdraw(_recipient, _relayer, _fee, _refund);
            // emits Withdraw
        }
}