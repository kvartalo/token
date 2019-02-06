pragma solidity ^0.5.0;

import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';
import './Offchainsig.sol';
import './Token.sol';

// Super simple poll, easy gamable
// Needs to implement https://github.com/aragon/evm-storage-proofs

contract Poll is Ownable,Offchainsig {
    mapping(bytes32=>bool) voted;
    mapping(bytes32=>uint256) votes;

    Token public token;

    constructor(address _token) public {
        token = Token(_token);
    }

    function vote(
        address _from, uint _voteid, uint256 _option,
        bytes32 _r, bytes32 _s, uint8 _v
    ) external {
        require(token.balanceOf(_from)>0);
        _verify(_from,abi.encodePacked(_voteid,_option),_r,_s,_v);

        bytes32 votedh = keccak256(abi.encodePacked(_voteid,_from));
        require(!voted[votedh]);
        votes[keccak256(abi.encodePacked(_voteid,_option))]++;
        voted[votedh]=true;
    }
}
