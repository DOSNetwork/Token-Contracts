pragma solidity >=0.5.0 <0.6.0;

/// @dev The token controller contract must implement these functions
contract TokenController {
    /// @notice Notifies the controller about a token transfer allowing the
    ///  controller to react if desired
    /// @param _from The origin of the transfer
    /// @param _to The destination of the transfer
    /// @param _amount The amount of the transfer
    /// @return The adjusted transfer amount filtered by a specific token controller.
    function onTokenTransfer(address _from, address _to, uint _amount) public returns(uint);

    /// @notice Notifies the controller about an approval allowing the
    ///  controller to react if desired
    /// @param _owner The address that calls `approve()`
    /// @param _spender The spender in the `approve()` call
    /// @param _amount The amount in the `approve()` call
    /// @return The adjusted approve amount filtered by a specific token controller.
    function onTokenApprove(address _owner, address _spender, uint _amount) public returns(uint);
}




contract DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) public view returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority  public  authority;
    address      public  owner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_)
        public
        auth
    {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_)
        public
        auth
    {
        authority = authority_;
        emit LogSetAuthority(address(authority));
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig), "ds-auth-unauthorized");
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, address(this), sig);
        }
    }
}



contract ControllerManager is DSAuth {
    address[] public controllers;
    
    function addController(address _ctrl) public auth {
        require(_ctrl != address(0));
        controllers.push(_ctrl);
    }
    
    function removeController(address _ctrl) public auth {
        for (uint idx = 0; idx < controllers.length; idx++) {
            if (controllers[idx] == _ctrl) {
                controllers[idx] = controllers[controllers.length - 1];
                controllers.length -= 1;
                return;
            }
        }
    }
    
    // Return the adjusted transfer amount after being filtered by all token controllers.
    function onTransfer(address _from, address _to, uint _amount) public returns(uint) {
        uint adjustedAmount = _amount;
        for (uint i = 0; i < controllers.length; i++) {
            adjustedAmount = TokenController(controllers[i]).onTokenTransfer(_from, _to, adjustedAmount);
            require(adjustedAmount <= _amount, "TokenController-isnot-allowed-to-lift-transfer-amount");
            if (adjustedAmount == 0) return 0;
        }
        return adjustedAmount;
    }

    // Return the adjusted approve amount after being filtered by all token controllers.
    function onApprove(address _owner, address _spender, uint _amount) public returns(uint) {
        uint adjustedAmount = _amount;
        for (uint i = 0; i < controllers.length; i++) {
            adjustedAmount = TokenController(controllers[i]).onTokenApprove(_owner, _spender, adjustedAmount);
            require(adjustedAmount <= _amount, "TokenController-isnot-allowed-to-lift-approve-amount");
            if (adjustedAmount == 0) return 0;
        }
        return adjustedAmount;
    }
}
