pragma solidity ^0.5.0;

import 'openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol';

contract Token is ERC20, ERC20Mintable, ERC20Burnable, ERC20Detailed {
    mapping(address=>uint256) public nonces; 

    constructor() ERC20Detailed("kvartalo","KVA",18) public {
    }       
    function transferoff(
        address _from,
        address _to,
        uint256 _value,
        bytes32 _r,
        bytes32 _s,
        uint8 _v) public {

        bytes32 hash=keccak256(abi.encodePacked(
            byte(0x19),byte(0),
            this,nonces[_from],
            _from,_to,_value
        ));
        address from = ecrecover(hash,_v,_r,_s);
        require(from==_from,"sender-address-does-not-match");
        nonces[from]++;

        _transfer(_from,_to,_value);
    }
}