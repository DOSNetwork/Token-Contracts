pragma solidity >=0.5.0 <0.6.0;

import "./erc20.sol";
import "./math.sol";
import "./stop.sol";

contract DropBurnToken is ERC20, DSMath, DSStop {
    string public constant name = 'DropBurn Token';
    string public constant symbol = 'DB';
    // Each DropBurn token represents for 10% of staking requirement.
    uint256 public constant decimals = 1;
    // DOS Network is burning 6% of total supply, which is 60,000,000 tokens.
    // Each DOS node stakes at least 50,000 tokens, with 1 DB stands for 10% of
    // staking requirement, we're issuing 12,000 DB tokens.
    uint256 private constant MAX_SUPPLY = 12000;
    uint256 private _supply = MAX_SUPPLY;
    
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256))  _approvals;
    
    constructor() public {
        _balances[msg.sender] = _supply;
        emit Transfer(address(0), msg.sender, _supply);
    }

    function totalSupply() public view returns (uint) {
        return _supply;
    }
    
    function balanceOf(address src) public view returns (uint) {
        return _balances[src];
    }
    
    function allowance(address src, address guy) public view returns (uint) {
        return _approvals[src][guy];
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad) public stoppable returns (bool) {
        if (src != msg.sender && _approvals[src][msg.sender] != uint(-1)) {
            require(_approvals[src][msg.sender] >= wad, "ds-token-insufficient-approval");
            _approvals[src][msg.sender] = sub(_approvals[src][msg.sender], wad);
        }

        require(_balances[src] >= wad, "ds-token-insufficient-balance");
        _balances[src] = sub(_balances[src], wad);
        _balances[dst] = add(_balances[dst], wad);

        emit Transfer(src, dst, wad);

        return true;
    }

    function approve(address guy) public stoppable returns (bool) {
        return approve(guy, uint(-1));
    }

    function approve(address guy, uint wad) public stoppable returns (bool) {
        // To change the approve amount you first have to reduce the addresses`
        // allowance to zero by calling `approve(_guy, 0)` if it is not
        // already 0 to mitigate the race condition described here:
        // https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require((wad == 0) || (_approvals[msg.sender][guy] == 0));
        
        _approvals[msg.sender][guy] = wad;

        emit Approval(msg.sender, guy, wad);

        return true;
    }

    function burn(uint wad) public {
        burn(msg.sender, wad);
    }
    
    function mint(address guy, uint wad) public auth stoppable {
        _balances[guy] = add(_balances[guy], wad);
        _supply = add(_supply, wad);
        require(_supply <= MAX_SUPPLY, "Total supply overflow");
        emit Transfer(address(0), guy, wad);
    }
    
    function burn(address guy, uint wad) public auth stoppable {
        if (guy != msg.sender && _approvals[guy][msg.sender] != uint(-1)) {
            require(_approvals[guy][msg.sender] >= wad, "token-insufficient-approval");
            _approvals[guy][msg.sender] = sub(_approvals[guy][msg.sender], wad);
        }

        require(_balances[guy] >= wad, "token-insufficient-balance");
        _balances[guy] = sub(_balances[guy], wad);
        _supply = sub(_supply, wad);
        emit Transfer(guy, address(0), wad);
    }
    
    /// @notice Ether sent to this contract won't be returned, thank you.
    function () external payable {}

    /// @notice This method can be used by the owner to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    function claimTokens(address _token, address payable _dst) public auth {
        if (_token == address(0)) {
            _dst.transfer(address(this).balance);
            return;
        }

        ERC20 token = ERC20(_token);
        uint balance = token.balanceOf(address(this));
        token.transfer(_dst, balance);
    }
}
