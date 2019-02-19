pragma solidity ^0.5.0;

import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';
import './Offchainsig.sol';

contract Token is Ownable, Offchainsig {

    using SafeMath for uint256;

    // events  ---------------------------------------------------------------

    event Transfer(address from, address to, uint256 value, bool isTax);
    event Mint(uint256 value);
    event Burn(uint256 value);
    event LimitChanged(address addr, uint256 value);
    event NameChanged(address addr, string value);
    event TaxDestinationChanged(address addr);

    // types  ---------------------------------------------------------------

    struct Account {
        uint256   balance;
        uint256   limit;
        string    name;
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

    function setName(
        address _from, string calldata _name,
        bytes32 _r, bytes32 _s, uint8 _v
    ) external {
        _verify(_from,abi.encodePacked(_from,_name),_r,_s,_v);
        accs[_from].name = _name;
    }

    // admin-only ---------------------------------------------------------------

    function setLimit(
        address _addr, uint256 _limit
    ) onlyOwner external {
        accs[_addr].limit=_limit;
        emit LimitChanged(_addr,_limit);
    }

    function mint(
        address _account, uint256 _value
    ) onlyOwner external {
        require(_account != address(0));

        accs[_account].balance = accs[_account].balance.add(_value);
        totalSupply = totalSupply.add(_value);

        emit Transfer(address(0), _account, _value,false);
        emit Mint(_value);
    }

    function burn(
        uint256 _value
    ) onlyOwner external {
        
        accs[msg.sender].balance = accs[msg.sender].balance.sub(_value);
        totalSupply = totalSupply.sub(_value);
        
        emit Transfer(msg.sender, address(0), _value, false);
        emit Burn(_value);
    }

    function setTaxDestination(
        address _taxDestination
    ) onlyOwner public {
        taxDestination = _taxDestination;
        accs[taxDestination].limit=uint256(-1);

        emit LimitChanged(taxDestination,accs[taxDestination].limit);
        emit TaxDestinationChanged(taxDestination);
    }

    // internals ----------------------------------------------------------------

    function _singletransfer(
        address _from, address _to, uint256 _value,
        bool _isTax)
    internal {
        require(_to != address(0));

        accs[_from].balance = accs[_from].balance.sub(_value);
        accs[_to].balance = accs[_to].balance.add(_value);
        emit Transfer(_from, _to, _value,_isTax);
    }

    function _taxtransfer(
        address _from, address _to, uint256 _value)
    internal {

        // transfer the value
        _singletransfer(_from,_to, _value,false);

        // apply the tax
        uint256 tax = (_value * taxPercent)/100;
        if (accs[_from].balance < tax) {
            tax = accs[_from].balance;
        }
        if (tax > 0) {
            _singletransfer(_from, taxDestination, tax,true);
        }

        if (accs[_to].limit==0) {
            require(balanceOf(_to) <= defaultBalanceLimit);
        } else {
            require(balanceOf(_to) <= accs[_to].limit);
        }
    }
}