pragma solidity ^0.5.0;

contract Offchainsig {

    mapping(address=>uint256) internal nonces;
 
    function nonceOf(address _owner)
    public view returns (uint256) {
        return nonces[_owner];
    }

    function _verify(
        address _from,bytes memory _message,
        bytes32 _r,bytes32 _s,uint8 _v
    ) internal {
        bytes32 hash=keccak256(abi.encodePacked(
            byte(0x19),byte(0),
            this,nonces[_from],
            _message
        ));
        
        address from = ecrecover(hash,_v,_r,_s);
        require(from==_from,"sender-address-does-not-match");
        nonces[_from]++;
    }

}