pragma solidity >=0.5.0 <0.6.0;

import "./auth.sol";
import "./math.sol";
import "./TokenController.sol";

contract LockdropController is TokenController, DSAuth, DSMath {
    uint public perNodeLockedAmount = 0;
    uint public lockedSupply = 0;
    uint public lockedNode = 0;
    mapping (address => bool) public lockdropList;
    
    event UpdatePerNodeLockedAmount(uint oldAmount, uint newAmount);
    event Lock(address indexed node);
    event Release(address indexed node);
    
    function setPerNodeLockedAmount(uint amount) public auth {
        require(amount != perNodeLockedAmount);
        emit UpdatePerNodeLockedAmount(perNodeLockedAmount, amount);
        perNodeLockedAmount = amount;
        lockedSupply = mul(perNodeLockedAmount, lockedNode);
    }
    
    function lock(address node) public auth {
        lockdropList[node] = true;
        lockedSupply = add(lockedSupply, perNodeLockedAmount);
        lockedNode = add(lockedNode, 1);
        emit Lock(node);
    }
    
    function release(address node) public auth {
        delete lockdropList[node];
        lockedSupply = sub(lockedSupply, perNodeLockedAmount);
        lockedNode = sub(lockedNode, 1);
        emit Release(node);
    }
    
    /// @notice For address in lockdropList it's only allowed to transfer the amount greater than the perNodeLockedAmount.
    function onTokenTransfer(address _from, address _to, uint _amount) public returns(uint) {
        if (!lockdropList[_from]) {
            return _amount;
        } else if (_amount <= perNodeLockedAmount) {
            return 0;
        } else {
            return (_amount - perNodeLockedAmount);
        }
    }
    
    /// @notice For address in lockdropList it's only allowed to approve the amount greater than the perNodeLockedAmount.
    function onTokenApprove(address _owner, address _spender, uint _amount) public returns(uint) {
        if (!lockdropList[_owner]) {
            return _amount;
        } else if (_amount <= perNodeLockedAmount) {
            return 0;
        } else {
            return (_amount - perNodeLockedAmount);
        }
    }
}
