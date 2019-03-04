pragma solidity >=0.5.0 <0.6.0;

import "./erc20.sol";
import "./math.sol";
import "./stop.sol";
import "./Controlled.sol";
import "./ControllerManager.sol";

contract DOSToken is ERC20, DSMath, DSStop, Controlled {
    string public constant name = 'DOS Network Token';
    string public constant symbol = 'DOS';
    uint256 public constant decimals = 18;
    uint256 private _supply = 1e9 * 1e18;  // 1 billion total supply
    
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256))  _approvals;

    event Mint(address indexed guy, uint wad);
    event Burn(address indexed guy, uint wad);
    
    constructor() public {
        _balances[msg.sender] = _supply;
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
        // Adjust token transfer amount if necessary.
        if (isContract(controller)) {
            wad = ControllerManager(controller).onTransfer(src, dst, wad);
            require(wad > 0, "transfer-disabled-by-ControllerManager");
        }

        if (src != msg.sender && _approvals[src][msg.sender] != uint(-1)) {
            require(_approvals[src][msg.sender] >= wad, "token-insufficient-approval");
            _approvals[src][msg.sender] = sub(_approvals[src][msg.sender], wad);
        }

        require(_balances[src] >= wad, "token-insufficient-balance");
        _balances[src] = sub(_balances[src], wad);
        _balances[dst] = add(_balances[dst], wad);

        emit Transfer(src, dst, wad);

        return true;
    }

    function approve(address guy) public stoppable returns (bool) {
        return approve(guy, uint(-1));
    }

    function approve(address guy, uint wad) public stoppable returns (bool) {
        // Alerts the token controller of the approve function call
        if (isContract(controller)) {
            wad = ControllerManager(controller).onApprove(msg.sender, guy, wad);
            require(wad > 0, "approve-disabled-by-ControllerManager");
        }
        
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
        emit Mint(guy, wad);
    }
    
    function burn(address guy, uint wad) public auth stoppable {
        if (guy != msg.sender && _approvals[guy][msg.sender] != uint(-1)) {
            require(_approvals[guy][msg.sender] >= wad, "token-insufficient-approval");
            _approvals[guy][msg.sender] = sub(_approvals[guy][msg.sender], wad);
        }

        require(_balances[guy] >= wad, "token-insufficient-balance");
        _balances[guy] = sub(_balances[guy], wad);
        _supply = sub(_supply, wad);
        emit Burn(guy, wad);
    }
    
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
