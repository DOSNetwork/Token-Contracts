pragma solidity >=0.5.0 <0.6.0;

import "./auth.sol";
import "./TokenController.sol";

contract LockdropController is TokenController, DSAuth {
    mapping (address => bool) public lockdropList;
    uint public lockedAmount = 0;
    
    event UpdateLockedAmount(uint oldAmount, uint newAmount);
    event Lock(address indexed node);
    event Release(address indexed node);
    
    function setLockedAmount(uint amount) public auth {
        require(amount != lockedAmount);
        emit UpdateLockedAmount(lockedAmount, amount);
        lockedAmount = amount;
    }
    
    function lock(address node) public auth {
        lockdropList[node] = true;
        emit Lock(node);
    }
    
    function release(address node) public auth {
        delete lockdropList[node];
        emit Release(node);
    }
    
    /// @notice For address in lockdropList it's only allowed to transfer the amount greater than the lockedAmount.
    function onTokenTransfer(address _from, address _to, uint _amount) public returns(uint) {
        if (!lockdropList[_from]) {
            return _amount;
        } else if (_amount <= lockedAmount) {
            return 0;
        } else {
            return (lockedAmount - _amount);
        }
    }
    
    /// @notice For address in lockdropList it's only allowed to approve the amount greater than the lockedAmount.
    function onTokenApprove(address _owner, address _spender, uint _amount) public returns(uint) {
        if (!lockdropList[_owner]) {
            return _amount;
        } else if (_amount <= lockedAmount) {
            return 0;
        } else {
            return (lockedAmount - _amount);
        }
    }
}
