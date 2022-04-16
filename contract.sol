// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./lib/Ownable.sol";
import "./lib/Ownable.sol";
import "./lib/Pausable.sol";
import "./lib/ERC1155.sol";
import "./lib/IWETH.sol";
import "./lib/Strings.sol";
import "./lib/SafeMath.sol";

contract StoreFront is ERC1155, Ownable {
    
    function getMessageHash(address _buyer, address _seller, uint _tokenid, uint _price, uint _quantity, uint _amount, uint _timestamp) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_buyer, _seller, _tokenid, _price, _quantity, _amount, _timestamp));
    }
    
    function verify(address _buyer, address _seller, uint _tokenid, uint _price, uint _quantity, uint _amount, uint _timestamp, bytes memory _signature) internal view returns (bool) {
        bytes32 messageHash = getMessageHash(_buyer, _seller, _tokenid, _price, _quantity, _amount, _timestamp);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, _signature) == signerAddress;
    }
    
    function getEthSignedMessageHash(bytes32 _messageHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }
    
    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig) internal pure returns (bytes32 r,bytes32 s,uint8 v) {
        require(sig.length == 65, "invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
    
    function buy(uint _pid, uint _tokenid, uint _price, uint _quantity, uint _amount, uint _timestamp, address _seller, bytes memory _signature) public payable {
        address _buyer = msg.sender;
        uint _value = msg.value;
        require(_buyer != address(0), "CV: buyer to the zero address");
        require(validTokenId(_tokenid), "CV: nonexistent token");
        require(verify(_buyer, _seller, _tokenid, _price, _quantity, _amount, _timestamp, _signature), "CV: invalid _signature");
        require(_price * _quantity == _amount, "CV: invalid amount");
        if (_value==0) {
            IWETH(weth).transferFrom(_buyer, address(this), _amount);
        } else {
            require(_amount == _value, "CV: invalid amount");    
        }
        if (_seller==address(0)) {
            if (_value==0) {
                IWETH(weth).transfer(storeAddress, _amount);
            } else {
                payable(storeAddress).transfer(_amount);
            }
        } else {
            uint _fee = _amount * feerate / 1e4;
            if (_value==0) {
                if (_fee>0) IWETH(weth).transfer(feeAddress, _fee);
                IWETH(weth).transfer(_seller, _amount - _fee);
            } else {
                if (_fee>0) payable(feeAddress).transfer(_fee);
                payable(_seller).transfer(_amount - _fee);
            }
        }
        bytes memory _data;
        if (_seller==address(0)) {
            _mint(_buyer, _tokenid, _quantity, _data);
        } else {
            require(isApprovedForAll(_seller, address(this)), "CV: seller is not approved");
            _transfer(_buyer, _seller, _buyer, _tokenid, _quantity, _data);
        }
        tokenVolumn[_tokenid] += _amount;
        emit Buy(_tokenid * 1e8 + _quantity, _price, _buyer, _seller, _pid);
    }
}