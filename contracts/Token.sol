pragma solidity ^0.5.0;

import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';

contract Token is Ownable {

    using SafeMath for uint256;

    // events  ---------------------------------------------------------------

    event Transfer(address from, address to, uint256 value);
    event LimitChanged(address addr, uint256 value);
    event NameChanged(address addr, string value);
    event TaxDestinationChanged(address addr);

    // types  ---------------------------------------------------------------

    struct Account {
        string  name;        
        uint256 balance;
        uint256 limit;
        uint256 nonce;
    }

    // parameters  ---------------------------------------------------------------

    uint256 public taxPercent          = 1;
    uint256 public defaultBalanceLimit = 20*(10**18);
    address public taxDestination; 

    // state  ---------------------------------------------------------------

    uint256 public totalSupply;
    mapping (address => Account) private accs;

    // publics  ---------------------------------------------------------------

    constructor(address _taxDestination) public {
        setTaxDestination(_taxDestination);
    }

    function balanceOf(address _owner)
    public view returns (uint256) {
        return accs[_owner].balance;
    }

    function nonceOf(address _owner)
    public view returns (uint256) {
        return accs[_owner].nonce;
    }

    function limitOf(address _owner)
    public view returns (uint256) {
        return accs[_owner].limit;
    }
    
    function nameOf(address _owner)
    public view returns (string memory) {
        return accs[_owner].name;
    }

    function transfer(
        address _from,address _to,uint256 _value,
        bytes32 _r, bytes32 _s, uint8 _v
    ) external {
        _verify(_from,abi.encodePacked(_from,_to,_value),_r,_s,_v);
        _taxtransfer(_from, _to, _value);
    }

    function setLimit(
        address _addr, uint256 _limit,
        bytes32 _r, bytes32 _s, uint8 _v
    ) external {
        _verify(_addr,abi.encodePacked(_addr,_limit),_r,_s,_v);
        accs[_addr].limit=_limit;
        emit LimitChanged(_addr,_limit);
    }

    function setName(
        address _addr, string calldata _name,
        bytes32 _r, bytes32 _s, uint8 _v
    ) external {
        _verify(_addr,abi.encodePacked(_addr,_name),_r,_s,_v);
        accs[_addr].name=_name;
        emit NameChanged(_addr,_name);
    }

    // admin-only ---------------------------------------------------------------

    function mint(
        address _account, uint256 _value
    ) onlyOwner external {
        require(_account != address(0));

        totalSupply = totalSupply.add(_value);
        accs[_account].balance = accs[_account].balance.add(_value);
        emit Transfer(address(0), _account, _value);
    }

    function burn(
        address _account, uint256 _value
    ) onlyOwner external {
        totalSupply = totalSupply.sub(_value);
        accs[_account].balance = accs[_account].balance.sub(_value);
        emit Transfer(_account, address(0), _value);
    }

    function setTaxDestination(
        address _taxDestination
    ) onlyOwner public {
        taxDestination = _taxDestination;
        emit TaxDestinationChanged(taxDestination);
    }

    // internals ----------------------------------------------------------------

    function _singletransfer(
        address _from, address _to, uint256 _value)
    internal {
        require(_to != address(0));

        accs[_from].balance = accs[_from].balance.sub(_value);
        accs[_to].balance = accs[_to].balance.add(_value);
        emit Transfer(_from, _to, _value);
    }

    function _taxtransfer(
        address _from, address _to, uint256 _value)
    internal {
        uint256 tax = (_value * taxPercent)/100;
        uint256 val = _value - tax;

        _singletransfer(_from, taxDestination, tax);
        _singletransfer(_from,_to, val);

        if (accs[_to].limit==0) {
            require(balanceOf(_to) <= defaultBalanceLimit);
        } else {
            require(balanceOf(_to) <= accs[_to].limit);
        }
    }

    function _verify(
        address _from,bytes memory _message,
        bytes32 _r,bytes32 _s,uint8 _v
    ) internal {
        bytes32 hash=keccak256(abi.encodePacked(
            byte(0x19),byte(0),
            this,accs[_from].nonce,
            _message
        ));
        
        address from = ecrecover(hash,_v,_r,_s);
        require(from==_from,"sender-address-does-not-match");
        accs[_from].nonce++;
    }
}