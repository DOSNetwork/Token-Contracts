pragma solidity >=0.5.0 <0.6.0;

import "./auth.sol";
import "./TokenController.sol";

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
